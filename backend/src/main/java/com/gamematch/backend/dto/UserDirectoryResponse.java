package com.gamematch.backend.dto;

import com.gamematch.backend.model.User;

public record UserDirectoryResponse(Long id, String name) {
    public static UserDirectoryResponse from(User user) {
        return new UserDirectoryResponse(user.getId(), user.getName());
    }
}
