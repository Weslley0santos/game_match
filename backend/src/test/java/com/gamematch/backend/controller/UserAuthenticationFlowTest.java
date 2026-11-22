package com.gamematch.backend.controller;

import com.gamematch.backend.config.JwtConfig;
import com.gamematch.backend.config.PasswordEncoderConfig;
import com.gamematch.backend.config.SecurityConfig;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.TokenService;
import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = UserController.class,
        properties = "security.jwt.secret=MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY="
)
@Import({SecurityConfig.class, JwtConfig.class, PasswordEncoderConfig.class, UserAuthenticationFlowTest.TokenTestConfiguration.class})
class UserAuthenticationFlowTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserRepository userRepository;

    private Map<String, User> users;
    private AtomicLong nextUserId;

    @BeforeEach
    void configureInMemoryUserRepository() {
        users = new HashMap<>();
        nextUserId = new AtomicLong(1);

        when(userRepository.findByUsername(anyString())).thenAnswer(invocation ->
                Optional.ofNullable(users.get(normalizeUsername(invocation.getArgument(0)))));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(nextUserId.getAndIncrement());
            users.put(user.getUsername(), user);
            return user;
        });
        when(userRepository.findAll()).thenAnswer(invocation -> List.copyOf(users.values()));
    }

    @Test
    void registersLogsInAndUsesIssuedTokenOnProtectedRoute() throws Exception {
        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":" Player_One ","password":"correct-horse"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("player_one"))
                .andExpect(jsonPath("$.username").value("player_one"))
                .andExpect(jsonPath("$.email").doesNotExist())
                .andExpect(jsonPath("$.password").doesNotExist());

        String loginResponse = mockMvc.perform(post("/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"PLAYER_ONE","password":"correct-horse"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("player_one"))
                .andExpect(jsonPath("$.username").value("player_one"))
                .andExpect(jsonPath("$.email").doesNotExist())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andReturn()
                .getResponse()
                .getContentAsString();

        String accessToken = JsonPath.read(loginResponse, "$.accessToken");

        mockMvc.perform(get("/users")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].name").value("player_one"));
    }

    @Test
    void rejectsAnonymousAccessToUserDirectory() throws Exception {
        mockMvc.perform(get("/users"))
                .andExpect(status().isUnauthorized());

        verify(userRepository, never()).findAll();
    }

    @Test
    void authenticatedUserCanFindAllAccountsUsingOnlyPublicDirectoryFields() throws Exception {
        registerPlayer();
        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"player_two","password":"another-correct-horse"}
                                """))
                .andExpect(status().isOk());

        String loginResponse = mockMvc.perform(post("/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"player_one","password":"correct-horse"}
                                """))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String accessToken = JsonPath.read(loginResponse, "$.accessToken");

        String directoryResponse = mockMvc.perform(get("/users")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        List<Map<String, Object>> directory = JsonPath.read(directoryResponse, "$");

        assertThat(directory).hasSize(2);
        assertThat(directory).extracting(user -> user.get("name"))
                .containsExactlyInAnyOrder("player_one", "player_two");
        assertThat(directory).allSatisfy(user ->
                assertThat(user.keySet()).containsExactlyInAnyOrder("id", "name"));
    }

    @Test
    void rejectsLoginWhenPasswordDoesNotMatchRegisteredAccount() throws Exception {
        registerPlayer();

        mockMvc.perform(post("/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"player_one","password":"wrong-password"}
                                """))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsDuplicateRegistrationRegardlessOfEmailCase() throws Exception {
        registerPlayer();

        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"PLAYER_ONE","password":"another-password"}
                                """))
                .andExpect(status().isConflict());
    }

    @Test
    void rejectsMalformedRegistrationUsernameBeforeCreatingAccount() throws Exception {
        for (String username : new String[]{"ab", "a".repeat(33), "player-name", "jogador ç", "Kelly", ""}) {
            mockMvc.perform(post("/users")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"username\":\"%s\",\"password\":\"correct-horse\"}".formatted(username)))
                    .andExpect(status().isBadRequest());
        }

        verify(userRepository, never()).save(any(User.class));
        org.assertj.core.api.Assertions.assertThat(users).isEmpty();
    }

    @Test
    void rejectsMissingRegistrationFieldsBeforeCreatingAccount() throws Exception {
        String[] requests = {
                "{}",
                "{\"username\":null,\"password\":\"correct-horse\"}",
                "{\"username\":\"player_one\",\"password\":null}"
        };

        for (String request : requests) {
            mockMvc.perform(post("/users")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(request))
                    .andExpect(status().isBadRequest());
        }

        verify(userRepository, never()).save(any(User.class));
        org.assertj.core.api.Assertions.assertThat(users).isEmpty();
    }

    @Test
    void rejectsMalformedLoginUsernameBeforeLookingUpAccount() throws Exception {
        mockMvc.perform(post("/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"player-name","password":"correct-horse"}
                                """))
                .andExpect(status().isUnauthorized());

        verify(userRepository, never()).findByUsername(anyString());
    }

    @Test
    void rejectsMissingLoginCredentialsBeforeLookingUpAccount() throws Exception {
        String[] requests = {
                "{}",
                "{\"username\":null,\"password\":\"correct-horse\"}",
                "{\"username\":\"player_one\",\"password\":null}",
                "{\"username\":\"player_one\",\"password\":\"  \"}"
        };

        for (String request : requests) {
            mockMvc.perform(post("/users/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(request))
                    .andExpect(status().isUnauthorized());
        }

        verify(userRepository, never()).findByUsername(anyString());
    }

    private void registerPlayer() throws Exception {
        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"player_one","password":"correct-horse"}
                                """))
                .andExpect(status().isOk());
    }

    private String normalizeUsername(String username) {
        return username.trim().toLowerCase(Locale.ROOT);
    }

    @TestConfiguration
    static class TokenTestConfiguration {
        @Bean
        TokenService tokenService(JwtEncoder jwtEncoder) {
            return new TokenService(jwtEncoder);
        }
    }
}
