package com.gamematch.backend.controller;

import com.gamematch.backend.model.Rating;
import com.gamematch.backend.repository.RatingRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/ratings")
public class RatingController {

    private final RatingRepository repository;

    public RatingController(RatingRepository repository) {
        this.repository = repository;
    }

    @PostMapping
    public Rating create(@RequestBody Rating rating) {
        return repository.save(rating);
    }

    @GetMapping("/{id}")
    public Rating getById(@PathVariable Long id) {
        return repository.findById(id).orElseThrow();
    }
    @PutMapping("/{id}")
    public Rating update(@PathVariable Long id, @RequestBody Rating newRating) {
        Rating rating = repository.findById(id).orElseThrow();

        rating.setType(newRating.getType());

        return repository.save(rating);
    }
    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        repository.deleteById(id);
    }

    @GetMapping("/user/{userId}")
    public List<Rating> getByUser(@PathVariable Long userId) {
        return repository.findByUserId(userId);
    }
}