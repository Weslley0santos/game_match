package com.gamematch.backend.integration;

import com.gamematch.backend.controller.FriendshipController;
import com.gamematch.backend.controller.MatchController;
import com.gamematch.backend.controller.PlayInviteController;
import com.gamematch.backend.controller.RatingController;
import com.gamematch.backend.controller.UserController;
import com.gamematch.backend.dto.LoginRequest;
import com.gamematch.backend.dto.RatingRequest;
import com.gamematch.backend.dto.RegistrationRequest;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.model.FriendshipStatus;
import com.gamematch.backend.model.PlayInviteStatus;
import com.gamematch.backend.model.Rating;
import com.gamematch.backend.model.RatingType;
import com.gamematch.backend.model.User;
import com.gamematch.backend.model.UserRole;
import com.gamematch.backend.repository.FriendshipRepository;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.repository.PlayInviteRepository;
import com.gamematch.backend.repository.RatingRepository;
import com.gamematch.backend.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import jakarta.persistence.EntityManager;
import java.sql.SQLException;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ContextConfiguration(initializers = PostgresTestDatabaseGuard.class)
@Transactional
class PostgresPersistenceIntegrationTest {

    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager entityManager;
    @Autowired private UserRepository userRepository;
    @Autowired private GameRepository gameRepository;
    @Autowired private RatingRepository ratingRepository;
    @Autowired private FriendshipRepository friendshipRepository;
    @Autowired private PlayInviteRepository playInviteRepository;
    @Autowired private RatingController ratingController;
    @Autowired private FriendshipController friendshipController;
    @Autowired private PlayInviteController playInviteController;
    @Autowired private MatchController matchController;
    @Autowired private UserController userController;
    @Autowired private JwtDecoder jwtDecoder;

    private User sender;
    private User receiver;
    private Game game;

    @BeforeEach
    void createTransactionalFixtures() {
        String unique = UUID.randomUUID().toString().replace("-", "");
        sender = userRepository.saveAndFlush(user("Sender", "sender_" + unique.substring(0, 12)));
        receiver = userRepository.saveAndFlush(user("Receiver", "receiver_" + unique.substring(0, 12)));
        game = gameRepository.saveAndFlush(new Game(
                "Integration Game " + unique,
                "Puzzle",
                "Description",
                "https://example.test/cover.png",
                null,
                List.of("PC", "Console")
        ));
    }

    @AfterEach
    void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void connectsOnlyToTestDatabaseAndAppliesFlywayMigrations() {
        assertEquals("game_match_test", jdbc.queryForObject("SELECT current_database()", String.class));
        List<String> appliedVersions = jdbc.queryForList(
                "SELECT version FROM flyway_schema_history WHERE success = true ORDER BY version",
                String.class
        );
        assertTrue(appliedVersions.containsAll(List.of("1", "2", "3", "4")), "V1 through V4 must be applied by Flyway");
        assertTrue(game.getTitle().startsWith("Integration Game "));
    }

    @Test
    void persistsAndReloadsUsersAndEnforcesCanonicalUsernameUniqueness() {
        entityManager.flush();
        entityManager.clear();

        User reloaded = userRepository.findById(sender.getId()).orElseThrow();
        assertEquals(sender.getUsername(), reloaded.getUsername());

        User duplicate = user("Duplicate", sender.getUsername());
        assertThrows(DataAccessException.class, () -> userRepository.saveAndFlush(duplicate));
    }

    @Test
    void registersAndLogsInWithPersistedUsernameAndPasswordHash() {
        String username = "fresh_" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        String password = " password with spaces ";
        var registered = userController.create(new RegistrationRequest(" " + username + " ", password));

        entityManager.flush();
        entityManager.clear();
        User persisted = userRepository.findByUsername(username).orElseThrow();
        assertEquals(registered.getId(), persisted.getId());
        assertEquals(username, persisted.getName());
        assertNotEquals(password, persisted.getPassword());
        assertTrue(persisted.getPassword().startsWith("$2"));

        var authenticated = userController.login(
                new LoginRequest(username.toUpperCase(Locale.ROOT), password));
        assertEquals(persisted.getId(), authenticated.id());
        assertEquals(username, authenticated.username());
        Jwt token = jwtDecoder.decode(authenticated.accessToken());
        assertEquals(persisted.getId().toString(), token.getSubject());
        assertEquals("ROLE_USER", token.getClaimAsString("role"));

        var denied = assertThrows(ResponseStatusException.class,
                () -> userController.login(new LoginRequest(username, password.strip())));
        assertEquals(HttpStatus.UNAUTHORIZED, denied.getStatusCode());
    }

    @Test
    void persistsGamePlatformsAndRatingCreateUpdateAcrossEntityManagerReload() {
        setCurrentUser(sender.getId());
        Rating created = ratingController.create(new RatingRequest(game.getId(), RatingType.LIKE));
        Rating updated = ratingController.create(new RatingRequest(game.getId(), RatingType.FAVORITE));

        entityManager.flush();
        Long gameId = game.getId();
        Long ratingId = updated.getId();
        entityManager.clear();

        Game reloadedGame = gameRepository.findById(gameId).orElseThrow();
        Rating reloadedRating = ratingRepository.findById(ratingId).orElseThrow();
        assertEquals(List.of("PC", "Console"), reloadedGame.getPlatforms());
        assertEquals(RatingType.FAVORITE, reloadedRating.getType());
        assertEquals(created.getId(), updated.getId(), "Creating the same user/game rating updates its stored row");
        assertEquals(1, ratingRepository.findAllByUserIdAndGameId(sender.getId(), gameId).size());
    }

    @Test
    void persistsFriendshipInviteAndCompatibilityAcrossReloads() {
        setCurrentUser(sender.getId());
        var pendingFriendship = friendshipController.addFriend(receiver.getId());
        entityManager.flush();
        entityManager.clear();
        assertEquals(FriendshipStatus.PENDING,
                friendshipRepository.findById(pendingFriendship.getId()).orElseThrow().getStatus());

        setCurrentUser(receiver.getId());
        friendshipController.accept(pendingFriendship.getId());
        entityManager.flush();
        entityManager.clear();
        assertEquals(FriendshipStatus.ACCEPTED,
                friendshipRepository.findById(pendingFriendship.getId()).orElseThrow().getStatus());

        setCurrentUser(sender.getId());
        ratingController.create(new RatingRequest(game.getId(), RatingType.LIKE));
        Game dislikedGame = gameRepository.saveAndFlush(new Game(
                "Disliked Game " + UUID.randomUUID(), "Action", "Description", null, null, List.of()
        ));
        ratingController.create(new RatingRequest(dislikedGame.getId(), RatingType.LIKE));
        setCurrentUser(receiver.getId());
        ratingController.create(new RatingRequest(game.getId(), RatingType.FAVORITE));
        ratingController.create(new RatingRequest(dislikedGame.getId(), RatingType.DISLIKE));
        entityManager.flush();
        entityManager.clear();

        setCurrentUser(sender.getId());
        var matches = matchController.getMatches(sender.getId(), receiver.getId());
        assertEquals(1, matches.size());
        assertEquals(game.getId(), matches.getFirst().getGameId());
        assertEquals(RatingType.FAVORITE, matches.getFirst().getPriorityInterest());
        assertFalse(matches.stream().anyMatch(match -> match.getGameId().equals(dislikedGame.getId())),
                "DISLIKE ratings must not appear as compatible matches");

        var pendingInvite = playInviteController.create(receiver.getId(), game.getId());
        entityManager.flush();
        entityManager.clear();
        assertEquals(PlayInviteStatus.PENDING,
                playInviteRepository.findById(pendingInvite.getId()).orElseThrow().getStatus());

        setCurrentUser(receiver.getId());
        playInviteController.accept(pendingInvite.getId());
        entityManager.flush();
        entityManager.clear();
        assertEquals(PlayInviteStatus.ACCEPTED,
                playInviteRepository.findById(pendingInvite.getId()).orElseThrow().getStatus());
    }

    @Test
    void postgresRejectsInvalidFriendshipForeignKey() {
        assertThrows(DataAccessException.class, () -> jdbc.update(
                "INSERT INTO friendship (user_id, friend_id, status) VALUES (?, ?, ?)",
                -1L, receiver.getId(), FriendshipStatus.PENDING.name()
        ));
    }

    @Test
    void postgresRejectsInvalidPlayInviteForeignKey() {
        assertThrows(DataAccessException.class, () -> jdbc.update(
                "INSERT INTO play_invites (sender_id, receiver_id, game_id, status) VALUES (?, ?, ?, ?)",
                -1L, receiver.getId(), game.getId(), PlayInviteStatus.PENDING.name()
        ));
    }

    @Test
    void postgresRejectsInvalidGamePlatformForeignKey() {
        assertThrows(DataAccessException.class, () -> jdbc.update(
                "INSERT INTO game_platforms (game_id, platform) VALUES (?, ?)",
                -1L, "Test platform"
        ));
    }

    @Test
    void postgresRejectsDeletingAUserReferencedByRating() {
        ratingRepository.saveAndFlush(new Rating(sender.getId(), game.getId(), RatingType.LIKE));

        assertForeignKeyViolation(() -> jdbc.update("DELETE FROM users WHERE id = ?", sender.getId()));
    }

    @Test
    void postgresRejectsDeletingAGameReferencedByRating() {
        ratingRepository.saveAndFlush(new Rating(sender.getId(), game.getId(), RatingType.LIKE));
        jdbc.update("DELETE FROM game_platforms WHERE game_id = ?", game.getId());

        assertForeignKeyViolation(() -> jdbc.update("DELETE FROM games WHERE id = ?", game.getId()));
    }

    @Test
    void apiReturns404WhenGameDoesNotExist() throws Exception {
        setCurrentUser(sender.getId());

        MockMvcBuilders.standaloneSetup(ratingController).build()
                .perform(post("/ratings").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"gameId":-1,"type":"LIKE"}
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void apiReturns401WhenJwtSubjectNoLongerExists() throws Exception {
        setCurrentUser(-1L);

        MockMvcBuilders.standaloneSetup(ratingController).build()
                .perform(post("/ratings").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"gameId":%d,"type":"LIKE"}
                                """.formatted(game.getId())))
                .andExpect(status().isUnauthorized());
    }

    private void assertForeignKeyViolation(Runnable write) {
        var failure = assertThrows(DataAccessException.class, write::run);
        var cause = assertInstanceOf(SQLException.class, failure.getMostSpecificCause());
        assertEquals("23503", cause.getSQLState());
    }

    private User user(String name, String username) {
        User user = new User();
        user.setName(name);
        user.setUsername(username);
        user.setPassword("test-only-password");
        user.setRole(UserRole.USER);
        return user;
    }

    private void setCurrentUser(Long userId) {
        Jwt jwt = Jwt.withTokenValue("integration-test-token")
                .header("alg", "none")
                .subject(userId.toString())
                .build();
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(jwt));
    }
}
