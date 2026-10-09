package com.gamematch.backend.dto;

import com.gamematch.backend.model.RatingType;

public record RatingRequest(Long gameId, RatingType type) {}
