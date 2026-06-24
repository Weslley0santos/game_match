package com.gamematch.backend.dto;

import com.gamematch.backend.model.PlayInvite;
import com.gamematch.backend.model.PlayInviteStatus;

public class PlayInviteResponse {

    private Long id;
    private Long senderId;
    private String senderName;
    private Long receiverId;
    private String receiverName;
    private Long gameId;
    private String gameTitle;
    private String gameImageUrl;
    private PlayInviteStatus status;

    public PlayInviteResponse(
            Long id,
            Long senderId,
            String senderName,
            Long receiverId,
            String receiverName,
            Long gameId,
            String gameTitle,
            String gameImageUrl,
            PlayInviteStatus status
    ) {
        this.id = id;
        this.senderId = senderId;
        this.senderName = senderName;
        this.receiverId = receiverId;
        this.receiverName = receiverName;
        this.gameId = gameId;
        this.gameTitle = gameTitle;
        this.gameImageUrl = gameImageUrl;
        this.status = status;
    }

    public static PlayInviteResponse from(PlayInvite invite) {
        return new PlayInviteResponse(
                invite.getId(),
                invite.getSender().getId(),
                invite.getSender().getName(),
                invite.getReceiver().getId(),
                invite.getReceiver().getName(),
                invite.getGame().getId(),
                invite.getGame().getTitle(),
                invite.getGame().getImageUrl(),
                invite.getStatus()
        );
    }

    public Long getId() {
        return id;
    }

    public Long getSenderId() {
        return senderId;
    }

    public String getSenderName() {
        return senderName;
    }

    public Long getReceiverId() {
        return receiverId;
    }

    public String getReceiverName() {
        return receiverName;
    }

    public Long getGameId() {
        return gameId;
    }

    public String getGameTitle() {
        return gameTitle;
    }

    public String getGameImageUrl() {
        return gameImageUrl;
    }

    public PlayInviteStatus getStatus() {
        return status;
    }
}
