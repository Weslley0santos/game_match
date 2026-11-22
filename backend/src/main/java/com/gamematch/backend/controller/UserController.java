package com.gamematch.backend.controller;

import com.gamematch.backend.dto.UserResponse;
import com.gamematch.backend.dto.AuthResponse;
import com.gamematch.backend.dto.LoginRequest;
import com.gamematch.backend.dto.RegistrationRequest;
import com.gamematch.backend.dto.UserDirectoryResponse;
import com.gamematch.backend.model.User;
import com.gamematch.backend.model.UserRole;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.TokenService;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.time.Instant;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/users")
public class UserController {

    private static final Pattern USERNAME_PATTERN = Pattern.compile("^[a-z0-9_]{3,32}$");
    private static final Pattern USERNAME_INPUT_PATTERN = Pattern.compile("^[A-Za-z0-9_]{3,32}$");
    private static final String USERNAME_CONSTRAINT = "uk_users_username";
    private static final String INVALID_CREDENTIALS = "Usuário ou senha inválidos";

    private final UserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;

    public UserController(UserRepository repository, PasswordEncoder passwordEncoder, TokenService tokenService) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    @PostMapping
    public UserResponse create(@RequestBody RegistrationRequest request) {
        if (request == null || request.username() == null || request.password() == null
                || request.password().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Username and password are required");
        }

        String trimmedUsername = request.username().strip();
        if (!isValidUsernameInput(trimmedUsername) || exceedsBcryptLimit(request.password())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid username or password");
        }
        String username = normalizeUsername(trimmedUsername);
        repository.findByUsername(username).ifPresent(existingUser -> {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already registered");
        });

        User user = new User();
        user.setName(username);
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setRole(UserRole.USER);
        try {
            return UserResponse.from(repository.save(user));
        } catch (DataIntegrityViolationException exception) {
            if (isUsernameConflict(exception)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already registered", exception);
            }
            throw exception;
        }
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        String rawUsername = request == null || request.username() == null ? "" : request.username().strip();
        String username = normalizeUsername(rawUsername);
        String password = request == null || request.password() == null ? "" : request.password();
        if (!isValidUsernameInput(rawUsername) || !isValidUsername(username)
                || password.isBlank() || exceedsBcryptLimit(password)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, INVALID_CREDENTIALS);
        }

        User user = repository.findByUsername(username).orElse(null);

        if (user == null || user.getPassword() == null || !passwordEncoder.matches(password, user.getPassword())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, INVALID_CREDENTIALS);
        }

        return AuthResponse.from(user, tokenService.createToken(user), Instant.now().plus(TokenService.TOKEN_TTL));
    }

    private static String normalizeUsername(String username) {
        return username.toLowerCase(Locale.ROOT);
    }

    private static boolean isValidUsername(String username) {
        return USERNAME_PATTERN.matcher(username).matches();
    }

    private static boolean isValidUsernameInput(String username) {
        return USERNAME_INPUT_PATTERN.matcher(username).matches();
    }

    private static boolean exceedsBcryptLimit(String password) {
        return password.getBytes(StandardCharsets.UTF_8).length > 72;
    }

    private static boolean isUsernameConflict(DataIntegrityViolationException exception) {
        Throwable cause = exception;
        while (cause != null) {
            if (cause instanceof org.hibernate.exception.ConstraintViolationException violation
                    && USERNAME_CONSTRAINT.equals(violation.getConstraintName())) {
                return true;
            }
            if (cause instanceof org.postgresql.util.PSQLException postgresException
                    && postgresException.getServerErrorMessage() != null
                    && USERNAME_CONSTRAINT.equals(postgresException.getServerErrorMessage().getConstraint())) {
                return true;
            }
            cause = cause.getCause();
        }
        return false;
    }

    @GetMapping
    public List<UserDirectoryResponse> getAll() {
        return repository.findAll()
                .stream()
                .map(UserDirectoryResponse::from)
                .toList();
    }
}
