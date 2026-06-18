package com.gamematch.backend.dto;

import com.gamematch.backend.model.Friendship;
import com.gamematch.backend.model.FriendshipStatus;

public class FriendshipResponse {

    private Long id;
    private Long userId;
    private String userName;
    private Long friendId;
    private String friendName;
    private FriendshipStatus status;

    public FriendshipResponse(Long id, Long userId, String userName, Long friendId, String friendName, FriendshipStatus status) {
        this.id = id;
        this.userId = userId;
        this.userName = userName;
        this.friendId = friendId;
        this.friendName = friendName;
        this.status = status;
    }

    public static FriendshipResponse from(Friendship friendship) {
        return new FriendshipResponse(
                friendship.getId(),
                friendship.getUser().getId(),
                friendship.getUser().getName(),
                friendship.getFriend().getId(),
                friendship.getFriend().getName(),
                friendship.getStatus()
        );
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public String getUserName() {
        return userName;
    }

    public Long getFriendId() {
        return friendId;
    }

    public String getFriendName() {
        return friendName;
    }

    public FriendshipStatus getStatus() {
        return status;
    }
}
