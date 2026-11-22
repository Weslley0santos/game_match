package com.gamematch.backend.controller;

import com.gamematch.backend.dto.RegistrationRequest;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.TokenService;
import org.hibernate.exception.ConstraintViolationException;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.sql.SQLException;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UserControllerTest {

    @Test
    void registersNormalizedUsernameAndUsesItAsDisplayName() {
        UserRepository repository = mock(UserRepository.class);
        PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
        UserController controller = new UserController(repository, passwordEncoder, mock(TokenService.class));
        when(repository.findByUsername("player_27")).thenReturn(Optional.empty());
        when(passwordEncoder.encode(" password ")).thenReturn("encoded-password");
        when(repository.save(any(User.class))).thenAnswer(invocation -> {
            User saved = invocation.getArgument(0);
            saved.setId(12L);
            return saved;
        });

        var response = controller.create(new RegistrationRequest(" Player_27 ", " password "));

        assertThat(response.getId()).isEqualTo(12L);
        assertThat(response.getName()).isEqualTo("player_27");
        assertThat(response.getUsername()).isEqualTo("player_27");
        verify(passwordEncoder).encode(" password ");
    }

    @Test
    void rejectsInvalidUsernameAndPasswordLengthWithoutSaving() {
        UserRepository repository = mock(UserRepository.class);
        UserController controller = new UserController(repository, mock(PasswordEncoder.class), mock(TokenService.class));
        for (String username : new String[]{"ab", "a".repeat(33), "a-b", "éabc", "Kelly", "  "}) {
            assertThatThrownBy(() -> controller.create(new RegistrationRequest(username, "password")))
                    .isInstanceOfSatisfying(ResponseStatusException.class, e ->
                            assertThat(e.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        }
        assertThatThrownBy(() -> controller.create(new RegistrationRequest("player", "é".repeat(37))))
                .isInstanceOfSatisfying(ResponseStatusException.class, e ->
                        assertThat(e.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        verify(repository, never()).save(any(User.class));
    }

    @Test
    void mapsUsernameConstraintRaceToConflict() {
        UserRepository repository = mock(UserRepository.class);
        UserController controller = new UserController(repository, mock(PasswordEncoder.class), mock(TokenService.class));
        when(repository.findByUsername("player")).thenReturn(Optional.empty());
        when(repository.save(any(User.class))).thenThrow(new DataIntegrityViolationException(
                "duplicate username", new ConstraintViolationException("duplicate username", new SQLException(), "uk_users_username")));

        assertThatThrownBy(() -> controller.create(new RegistrationRequest("player", "password")))
                .isInstanceOfSatisfying(ResponseStatusException.class, e ->
                        assertThat(e.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));
    }
}
