package com.gamematch.backend.controller;

import com.gamematch.backend.dto.PlayInviteResponse;
import com.gamematch.backend.model.FriendshipStatus;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.model.PlayInvite;
import com.gamematch.backend.model.PlayInviteStatus;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.FriendshipRepository;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.repository.PlayInviteRepository;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.CurrentUserService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/play-invites")
public class PlayInviteController {

    private final PlayInviteRepository playInviteRepository;
    private final UserRepository userRepository;
    private final GameRepository gameRepository;
    private final FriendshipRepository friendshipRepository;
    private final CurrentUserService currentUser;

    public PlayInviteController(
            PlayInviteRepository playInviteRepository,
            UserRepository userRepository,
            GameRepository gameRepository,
            FriendshipRepository friendshipRepository,
            CurrentUserService currentUser
    ) {
        this.playInviteRepository = playInviteRepository;
        this.userRepository = userRepository;
        this.gameRepository = gameRepository;
        this.friendshipRepository = friendshipRepository;
        this.currentUser = currentUser;
    }

    @PostMapping
    public PlayInviteResponse create(
            @RequestParam Long receiverId,
            @RequestParam Long gameId
    ) {
        Long senderId = currentUser.requireUserId();
        if (senderId.equals(receiverId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User cannot send a play invite to himself");
        }

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sender not found"));

        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Receiver not found"));

        Game game = gameRepository.findById(gameId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Game not found"));

        long acceptedFriendships = friendshipRepository.countBetweenUsersAndStatus(
                sender,
                receiver,
                FriendshipStatus.ACCEPTED
        );

        if (acceptedFriendships == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Users must be accepted friends to send play invites");
        }

        boolean pendingInviteExists = playInviteRepository.existsBySenderAndReceiverAndGameAndStatus(
                sender,
                receiver,
                game,
                PlayInviteStatus.PENDING
        );

        if (pendingInviteExists) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Pending play invite already exists");
        }

        PlayInvite invite = new PlayInvite(sender, receiver, game, PlayInviteStatus.PENDING);

        return PlayInviteResponse.from(playInviteRepository.save(invite));
    }

    @GetMapping("/{userId}/received")
    public List<PlayInviteResponse> getReceived(@PathVariable Long userId) {
        requireCurrentUser(userId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        return playInviteRepository.findByReceiver(user)
                .stream()
                .map(PlayInviteResponse::from)
                .toList();
    }

    @GetMapping("/{userId}/sent")
    public List<PlayInviteResponse> getSent(@PathVariable Long userId) {
        requireCurrentUser(userId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        return playInviteRepository.findBySender(user)
                .stream()
                .map(PlayInviteResponse::from)
                .toList();
    }

    @PutMapping("/{inviteId}/accept")
    public PlayInviteResponse accept(@PathVariable Long inviteId) {
        PlayInvite invite = findInvite(inviteId);
        requireCurrentUser(invite.getReceiver().getId());
        requirePending(invite);
        invite.setStatus(PlayInviteStatus.ACCEPTED);

        return PlayInviteResponse.from(playInviteRepository.save(invite));
    }

    @PutMapping("/{inviteId}/reject")
    public PlayInviteResponse reject(@PathVariable Long inviteId) {
        PlayInvite invite = findInvite(inviteId);
        requireCurrentUser(invite.getReceiver().getId());
        requirePending(invite);
        invite.setStatus(PlayInviteStatus.REJECTED);

        return PlayInviteResponse.from(playInviteRepository.save(invite));
    }

    private PlayInvite findInvite(Long inviteId) {
        return playInviteRepository.findById(inviteId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Play invite not found"));
    }

    private void requireCurrentUser(Long userId) {
        if (!currentUser.requireUserId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only access your own invitations");
        }
    }

    private void requirePending(PlayInvite invite) {
        if (invite.getStatus() != PlayInviteStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Play invite is no longer pending");
        }
    }
}
