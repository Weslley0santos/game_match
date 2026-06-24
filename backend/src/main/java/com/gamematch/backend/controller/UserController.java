package com.gamematch.backend.controller;

import com.gamematch.backend.dto.UserResponse;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserRepository repository;

    public UserController(UserRepository repository) {
        this.repository = repository;
    }

    @PostMapping
    public UserResponse create(@RequestBody User user) {
        repository.findByEmail(user.getEmail()).ifPresent(existingUser -> {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        });

        return UserResponse.from(repository.save(user));
    }

    @PostMapping("/login")
    public UserResponse login(@RequestBody User request) {

        User user = repository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!user.getPassword().equals(request.getPassword())) {
            throw new RuntimeException("Invalid password");
        }

        return UserResponse.from(user);
    }

    @GetMapping
    public List<UserResponse> getAll() {
        return repository.findAll()
                .stream()
                .map(UserResponse::from)
                .toList();
    }
}
