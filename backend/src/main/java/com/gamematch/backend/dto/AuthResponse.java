package com.gamematch.backend.dto;

import com.gamematch.backend.model.User;

import java.time.Instant;

public record AuthResponse(
        Long id,
        String name,
        String username,
        String accessToken,
        String tokenType,
        Instant expiresAt
) {
    public static AuthResponse from(User user, String accessToken, Instant expiresAt) {
        return new AuthResponse(user.getId(), user.getName(), user.getUsername(), accessToken, "Bearer", expiresAt);
    }
}
