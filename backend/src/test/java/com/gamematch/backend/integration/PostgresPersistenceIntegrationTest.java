package com.gamematch.backend.integration;

import com.gamematch.backend.controller.FriendshipController;
import com.gamematch.backend.controller.MatchController;
import com.gamematch.backend.controller.PlayInviteController;
import com.gamematch.backend.controller.RatingController;
import com.gamematch.backend.dto.RatingRequest;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

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

    private User sender;
    private User receiver;
    private Game game;

    @BeforeEach
    void createTransactionalFixtures() {
        String unique = UUID.randomUUID().toString().replace("-", "");
        sender = userRepository.saveAndFlush(user("Sender", "sender-" + unique + "@example.test"));
        receiver = userRepository.saveAndFlush(user("Receiver", "receiver-" + unique + "@example.test"));
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
        assertTrue(appliedVersions.containsAll(List.of("1", "2")), "V1 and V2 must be applied by Flyway");
        assertTrue(game.getTitle().startsWith("Integration Game "));
    }

    @Test
    void persistsAndReloadsUsersAndEnforcesCaseInsensitiveEmailUniqueness() {
        entityManager.flush();
        entityManager.clear();

        User reloaded = userRepository.findById(sender.getId()).orElseThrow();
        assertEquals(sender.getEmail(), reloaded.getEmail());

        User duplicate = user("Duplicate", sender.getEmail().toUpperCase());
        assertThrows(DataAccessException.class, () -> userRepository.saveAndFlush(duplicate));
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

    private User user(String name, String email) {
        User user = new User();
        user.setName(name);
        user.setEmail(email);
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
