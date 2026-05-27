package com.gamematch.backend.controller;

import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.UserRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserRepository repository;

    public UserController(UserRepository repository) {
        this.repository = repository;
    }

    @PostMapping
    public User create(@RequestBody User user) {
        return repository.save(user);
    }

    @PostMapping("/login")
    public User login(@RequestBody User request) {

        User user = repository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!user.getPassword().equals(request.getPassword())) {
            throw new RuntimeException("Invalid password");
        }

        return user;
    }

    @GetMapping
    public List<User> getAll() {
        return repository.findAll();
    }
}