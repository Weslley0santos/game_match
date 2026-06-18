package com.gamematch.backend.dto;

import com.gamematch.backend.model.RatingType;

public class MatchResponse {

    private Long gameId;
    private String gameTitle;
    private String imageUrl;
    private RatingType userInterest;
    private RatingType friendInterest;
    private RatingType priorityInterest;

    public MatchResponse(
            Long gameId,
            String gameTitle,
            String imageUrl,
            RatingType userInterest,
            RatingType friendInterest,
            RatingType priorityInterest
    ) {
        this.gameId = gameId;
        this.gameTitle = gameTitle;
        this.imageUrl = imageUrl;
        this.userInterest = userInterest;
        this.friendInterest = friendInterest;
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

    public RatingType getUserInterest() {
        return userInterest;
    }

    public RatingType getFriendInterest() {
        return friendInterest;
    }

    public RatingType getPriorityInterest() {
        return priorityInterest;
    }

    public void setGameId(Long gameId) {
        this.gameId = gameId;
    }

    public void setGameTitle(String gameTitle) {
        this.gameTitle = gameTitle;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public void setUserInterest(RatingType userInterest) {
        this.userInterest = userInterest;
    }

    public void setFriendInterest(RatingType friendInterest) {
        this.friendInterest = friendInterest;
    }

    public void setPriorityInterest(RatingType priorityInterest) {
        this.priorityInterest = priorityInterest;
    }
}
