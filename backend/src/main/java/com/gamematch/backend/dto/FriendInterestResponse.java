package com.gamematch.backend.dto;

import com.gamematch.backend.model.RatingType;

public class FriendInterestResponse {

    private Long friendId;
    private String friendName;
    private RatingType interestType;

    public FriendInterestResponse(Long friendId, String friendName, RatingType interestType) {
        this.friendId = friendId;
        this.friendName = friendName;
        this.interestType = interestType;
    }

    public Long getFriendId() {
        return friendId;
    }

    public String getFriendName() {
        return friendName;
    }

    public RatingType getInterestType() {
        return interestType;
    }
}
