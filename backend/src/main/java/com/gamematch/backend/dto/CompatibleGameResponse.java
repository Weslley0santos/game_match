package com.gamematch.backend.dto;

import com.gamematch.backend.model.RatingType;

public class CompatibleGameResponse {

    private Long gameId;
    private String gameTitle;
    private String imageUrl;
    private int compatibleFriendsCount;
    private int favoriteFriendsCount;
    private RatingType userInterest;
    private RatingType priorityInterest;

    public CompatibleGameResponse(
            Long gameId,
            String gameTitle,
            String imageUrl,
            int compatibleFriendsCount,
            int favoriteFriendsCount,
            RatingType userInterest,
            RatingType priorityInterest
    ) {
        this.gameId = gameId;
        this.gameTitle = gameTitle;
        this.imageUrl = imageUrl;
        this.compatibleFriendsCount = compatibleFriendsCount;
        this.favoriteFriendsCount = favoriteFriendsCount;
        this.userInterest = userInterest;
        this.priorityInterest = priorityInterest;
    }

    public Long getGameId() {
        return gameId;
    }

    public String getGameTitle() {
        return gameTitle;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public int getCompatibleFriendsCount() {
        return compatibleFriendsCount;
    }

    public int getFavoriteFriendsCount() {
        return favoriteFriendsCount;
    }

    public RatingType getUserInterest() {
        return userInterest;
    }

    public RatingType getPriorityInterest() {
        return priorityInterest;
    }
}
