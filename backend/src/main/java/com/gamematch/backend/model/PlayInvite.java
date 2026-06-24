package com.gamematch.backend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "play_invites")
public class PlayInvite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private User sender;

    @ManyToOne
    private User receiver;

    @ManyToOne
    private Game game;

    @Enumerated(EnumType.STRING)
    private PlayInviteStatus status;

    public PlayInvite() {
    }

    public PlayInvite(User sender, User receiver, Game game, PlayInviteStatus status) {
        this.sender = sender;
        this.receiver = receiver;
        this.game = game;
        this.status = status;
    }

    public Long getId() {
        return id;
    }

    public User getSender() {
        return sender;
    }

    public User getReceiver() {
        return receiver;
    }

    public Game getGame() {
        return game;
    }

    public PlayInviteStatus getStatus() {
        return status;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setSender(User sender) {
        this.sender = sender;
    }

    public void setReceiver(User receiver) {
        this.receiver = receiver;
    }

    public void setGame(Game game) {
        this.game = game;
    }

    public void setStatus(PlayInviteStatus status) {
        this.status = status;
    }
}
