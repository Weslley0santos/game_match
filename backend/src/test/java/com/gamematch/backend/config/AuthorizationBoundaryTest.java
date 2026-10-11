package com.gamematch.backend.config;

import com.gamematch.backend.controller.FriendshipController;
import com.gamematch.backend.controller.GameController;
import com.gamematch.backend.controller.PlayInviteController;
import com.gamematch.backend.controller.RatingController;
import com.gamematch.backend.model.Friendship;
import com.gamematch.backend.model.FriendshipStatus;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.model.PlayInvite;
import com.gamematch.backend.model.PlayInviteStatus;
import com.gamematch.backend.model.Rating;
import com.gamematch.backend.model.RatingType;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.FriendshipRepository;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.repository.PlayInviteRepository;
import com.gamematch.backend.repository.RatingRepository;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.CurrentUserService;
import com.gamematch.backend.service.IgdbGameService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = {
        FriendshipController.class,
        GameController.class,
        PlayInviteController.class,
        RatingController.class
})
@Import({SecurityConfig.class, CurrentUserService.class})
class AuthorizationBoundaryTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private FriendshipRepository friendshipRepository;

    @MockitoBean
    private GameRepository gameRepository;

    @MockitoBean
    private PlayInviteRepository playInviteRepository;

    @MockitoBean
    private RatingRepository ratingRepository;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private IgdbGameService igdbGameService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @BeforeEach
    void configureJwtDecoder() {
        when(jwtDecoder.decode("user-token")).thenReturn(jwt("user-token", "1", "ROLE_USER"));
        when(jwtDecoder.decode("admin-token")).thenReturn(jwt("admin-token", "1", "ROLE_ADMIN"));
    }

    @Test
    void deniesProtectedRouteWithoutToken() throws Exception {
        mockMvc.perform(get("/ratings/10"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void blocksReadingAnotherUsersRating() throws Exception {
        when(ratingRepository.findById(10L)).thenReturn(Optional.of(new Rating(2L, 20L, RatingType.LIKE)));

        mockMvc.perform(get("/ratings/10").header(HttpHeaders.AUTHORIZATION, "Bearer user-token"))
                .andExpect(status().isForbidden());
    }

    @Test
    void blocksUpdatingAnotherUsersRating() throws Exception {
        when(ratingRepository.findById(10L)).thenReturn(Optional.of(new Rating(2L, 20L, RatingType.LIKE)));

        mockMvc.perform(put("/ratings/10")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"gameId\":20,\"type\":\"DISLIKE\"}"))
                .andExpect(status().isForbidden());

        verify(ratingRepository, never()).save(any(Rating.class));
    }

    @Test
    void blocksReadingAnotherUsersFriendships() throws Exception {
        mockMvc.perform(get("/friendships/2").header(HttpHeaders.AUTHORIZATION, "Bearer user-token"))
                .andExpect(status().isForbidden());
    }

    @Test
    void blocksAcceptingFriendshipRequestForAnotherUser() throws Exception {
        Friendship friendship = new Friendship(user(3L), user(2L), FriendshipStatus.PENDING);
        when(friendshipRepository.findById(10L)).thenReturn(Optional.of(friendship));

        mockMvc.perform(put("/friendships/10/accept")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer user-token"))
                .andExpect(status().isForbidden());

        verify(friendshipRepository, never()).save(any(Friendship.class));
    }

    @Test
    void blocksReadingAnotherUsersPlayInvites() throws Exception {
        mockMvc.perform(get("/play-invites/2/received").header(HttpHeaders.AUTHORIZATION, "Bearer user-token"))
                .andExpect(status().isForbidden());
    }

    @Test
    void blocksAcceptingPlayInviteForAnotherUser() throws Exception {
        PlayInvite invite = new PlayInvite(
                user(3L), user(2L), new Game("Game", "Genre", "", "", 1L, List.of()), PlayInviteStatus.PENDING
        );
        when(playInviteRepository.findById(10L)).thenReturn(Optional.of(invite));

        mockMvc.perform(put("/play-invites/10/accept")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer user-token"))
                .andExpect(status().isForbidden());

        verify(playInviteRepository, never()).save(any(PlayInvite.class));
    }

    @Test
    void limitsGameCreationAndImportToAdministrators() throws Exception {
        mockMvc.perform(post("/games")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer user-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Game\"}"))
                .andExpect(status().isForbidden());
        verify(gameRepository, never()).save(any(Game.class));

        when(gameRepository.save(any(Game.class))).thenAnswer(invocation -> invocation.getArgument(0));
        mockMvc.perform(post("/games")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer admin-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Game\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/games/igdb/import")
                        .param("query", "zelda")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer user-token"))
                .andExpect(status().isForbidden());

        when(igdbGameService.searchMainGames("zelda")).thenReturn(List.of());
        when(gameRepository.saveAll(any())).thenReturn(List.of());
        mockMvc.perform(post("/games/igdb/import")
                        .param("query", "zelda")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer admin-token"))
                .andExpect(status().isOk());
    }

    private Jwt jwt(String token, String subject, String role) {
        Instant now = Instant.now();
        return Jwt.withTokenValue(token)
                .header("alg", "none")
                .subject(subject)
                .issuedAt(now)
                .expiresAt(now.plusSeconds(300))
                .claim("role", role)
                .build();
    }

    private User user(Long id) {
        User user = new User();
        user.setId(id);
        return user;
    }
}
