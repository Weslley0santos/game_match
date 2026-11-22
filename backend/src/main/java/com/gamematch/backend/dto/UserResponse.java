package com.gamematch.backend.dto;

import com.gamematch.backend.model.User;

public class UserResponse {

    private Long id;
    private String name;
    private String username;

    public UserResponse(Long id, String name, String username) {
        this.id = id;
        this.name = name;
        this.username = username;
    }

    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getName(),
                user.getUsername()
        );
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getUsername() {
        return username;
    }
}
