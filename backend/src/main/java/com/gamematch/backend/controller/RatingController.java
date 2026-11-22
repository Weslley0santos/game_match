package com.gamematch.backend.controller;

import com.gamematch.backend.dto.RatingRequest;
import com.gamematch.backend.model.Rating;
import com.gamematch.backend.repository.RatingRepository;
import com.gamematch.backend.service.CurrentUserService;
import org.postgresql.util.PSQLException;
import org.postgresql.util.PSQLState;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/ratings")
public class RatingController {
    private final RatingRepository repository;
    private final CurrentUserService currentUser;

    public RatingController(RatingRepository repository, CurrentUserService currentUser) {
        this.repository = repository;
        this.currentUser = currentUser;
    }

    @PostMapping
    public Rating create(@RequestBody RatingRequest request) {
        if (request.gameId() == null || request.type() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Game and rating type are required");
        }
        Long userId = currentUser.requireUserId();
        List<Rating> existingRatings = repository.findAllByUserIdAndGameId(userId, request.gameId());
        if (!existingRatings.isEmpty()) {
            existingRatings.forEach(rating -> rating.setType(request.type()));
            repository.saveAll(existingRatings);
            return existingRatings.get(0);
        }
        try {
            return repository.save(new Rating(userId, request.gameId(), request.type()));
        } catch (DataIntegrityViolationException exception) {
            if (exception.getMostSpecificCause() instanceof PSQLException failure
                    && PSQLState.FOREIGN_KEY_VIOLATION.getState().equals(failure.getSQLState())
                    && failure.getServerErrorMessage() != null) {
                String constraint = failure.getServerErrorMessage().getConstraint();
                if ("fk_ratings_user".equals(constraint)) {
                    throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authenticated user not found");
                }
                if ("fk_ratings_game".equals(constraint)) {
                    throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Game not found");
                }
            }
            throw exception;
        }
    }

    @GetMapping("/{id}")
    public Rating getById(@PathVariable Long id) {
        return requireOwned(id);
    }

    @PutMapping("/{id}")
    public Rating update(@PathVariable Long id, @RequestBody RatingRequest request) {
        if (request.type() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rating type is required");
        }
        Rating rating = requireOwned(id);
        rating.setType(request.type());
        return repository.save(rating);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        repository.delete(requireOwned(id));
    }

    @GetMapping("/user/{userId}")
    public List<Rating> getByUser(@PathVariable Long userId) {
        requireCurrentUser(userId);
        return repository.findByUserId(userId);
    }

    private Rating requireOwned(Long id) {
        Rating rating = repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Rating not found"));
        requireCurrentUser(rating.getUserId());
        return rating;
    }

    private void requireCurrentUser(Long userId) {
        if (!currentUser.requireUserId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only access your own ratings");
        }
    }
}
