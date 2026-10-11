package com.gamematch.backend.controller;

import com.gamematch.backend.dto.RegistrationRequest;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.TokenService;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class UserControllerTest {

    @Test
    void mapsDatabaseEmailConflictToHttpConflict() {
        UserRepository repository = mock(UserRepository.class);
        PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
        TokenService tokenService = mock(TokenService.class);
        UserController controller = new UserController(repository, passwordEncoder, tokenService);

        when(repository.findByEmailIgnoreCase("player@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("password")).thenReturn("encoded-password");
        when(repository.save(any(User.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate email"));

        assertThatThrownBy(() -> controller.create(
                new RegistrationRequest("Player", "player@example.com", "password")
        )).isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));
    }
}
