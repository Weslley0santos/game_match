package com.gamematch.backend.config;

import com.gamematch.backend.controller.GameController;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.service.IgdbGameService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(GameController.class)
@Import(SecurityConfig.class)
class GameSearchSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private GameRepository gameRepository;

    @MockitoBean
    private IgdbGameService igdbGameService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @BeforeEach
    void configureJwtDecoder() {
        when(jwtDecoder.decode("user-token")).thenReturn(jwt("user-token", "ROLE_USER"));
        when(jwtDecoder.decode("admin-token")).thenReturn(jwt("admin-token", "ROLE_ADMIN"));
    }

    @Test
    void rejectsAnonymousSearch() throws Exception {
        mockMvc.perform(get("/games/igdb/search").param("query", "zelda"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsRegularUserSearch() throws Exception {
        mockMvc.perform(get("/games/igdb/search")
                        .param("query", "zelda")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer user-token"))
                .andExpect(status().isForbidden());
    }

    @Test
    void allowsAdministratorSearch() throws Exception {
        mockMvc.perform(get("/games/igdb/search")
                        .param("query", "zelda")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer admin-token"))
                .andExpect(status().isOk());
    }

    private Jwt jwt(String token, String role) {
        Instant now = Instant.now();
        return Jwt.withTokenValue(token)
                .header("alg", "none")
                .subject("test-user")
                .issuedAt(now)
                .expiresAt(now.plusSeconds(300))
                .claim("role", role)
                .build();
    }
}
