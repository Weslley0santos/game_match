package com.gamematch.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "ratings")
public class Rating {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private Long gameId;

    @Enumerated(EnumType.STRING)
    private RatingType type;

    public Rating() {}

    public Rating(Long userId, Long gameId, RatingType type) {
        this.userId = userId;
        this.gameId = gameId;
        this.type = type;
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public Long getGameId() {
        return gameId;
    }

    public RatingType getType() {
        return type;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public void setGameId(Long gameId) {
        this.gameId = gameId;
    }

    public void setType(RatingType type) {
        this.type = type;
    }
}