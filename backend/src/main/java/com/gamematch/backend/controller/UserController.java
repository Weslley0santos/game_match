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
import java.util.Locale;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/users")
public class UserController {

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
                    + "@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\\.)+"
                    + "[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$");

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
        if (request == null || request.name() == null || request.name().isBlank()
                || request.email() == null || request.email().isBlank()
                || request.password() == null || request.password().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Name, email and password are required");
        }

        String email = request.email().trim().toLowerCase(Locale.ROOT);
        if (!isValidEmail(email)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A valid email is required");
        }
        repository.findByEmailIgnoreCase(email).ifPresent(existingUser -> {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        });

        User user = new User();
        user.setName(request.name().trim());
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setRole(UserRole.USER);
        try {
            return UserResponse.from(repository.save(user));
        } catch (DataIntegrityViolationException exception) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered", exception);
        }
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        String email = request == null || request.email() == null ? "" : request.email().trim();
        String password = request == null || request.password() == null ? "" : request.password();
        if (!isValidEmail(email) || password.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email ou senha inválidos");
        }

        User user = repository.findByEmailIgnoreCase(email).orElse(null);

        if (user == null || user.getPassword() == null || !passwordEncoder.matches(password, user.getPassword())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email ou senha inválidos");
        }

        return AuthResponse.from(user, tokenService.createToken(user), Instant.now().plus(TokenService.TOKEN_TTL));
    }

    private static boolean isValidEmail(String email) {
        return EMAIL_PATTERN.matcher(email).matches();
    }

    @GetMapping
    public List<UserDirectoryResponse> getAll() {
        return repository.findAll()
                .stream()
                .map(UserDirectoryResponse::from)
                .toList();
    }
}
