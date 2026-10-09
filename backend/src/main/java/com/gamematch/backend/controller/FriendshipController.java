package com.gamematch.backend.controller;

import com.gamematch.backend.dto.FriendshipResponse;
import com.gamematch.backend.model.Friendship;
import com.gamematch.backend.model.FriendshipStatus;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.FriendshipRepository;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.CurrentUserService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/friendships")
public class FriendshipController {

    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;
    private final CurrentUserService currentUser;

    public FriendshipController(
            FriendshipRepository friendshipRepository,
            UserRepository userRepository,
            CurrentUserService currentUser
    ) {
        this.friendshipRepository = friendshipRepository;
        this.userRepository = userRepository;
        this.currentUser = currentUser;
    }

    @PostMapping
    public FriendshipResponse addFriend(@RequestParam Long friendId) {
        Long userId = currentUser.requireUserId();

        if (userId.equals(friendId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User cannot send a friendship request to himself");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        User friend = userRepository.findById(friendId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Friend not found"));

        friendshipRepository.findBetweenUsers(user, friend).ifPresent(existingFriendship -> {
            if (existingFriendship.getStatus() != FriendshipStatus.REJECTED) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Friendship request already exists");
            }
        });

        Friendship friendship = new Friendship(user, friend, FriendshipStatus.PENDING);

        return FriendshipResponse.from(friendshipRepository.save(friendship));
    }

    @GetMapping("/{userId}")
    public List<FriendshipResponse> getFriends(@PathVariable Long userId) {
        requireCurrentUser(userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        return friendshipRepository
                .findByUserAndStatus(user, FriendshipStatus.ACCEPTED)
                .stream()
                .map(FriendshipResponse::from)
                .toList();
    }

    @GetMapping("/{userId}/pending")
    public List<FriendshipResponse> getPendingRequests(@PathVariable Long userId) {
        requireCurrentUser(userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        return friendshipRepository
                .findByFriendAndStatus(user, FriendshipStatus.PENDING)
                .stream()
                .map(FriendshipResponse::from)
                .toList();
    }

    @PutMapping("/{id}/accept")
    public FriendshipResponse accept(@PathVariable Long id) {

        Friendship friendship = friendshipRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Friendship request not found"));

        requireRecipient(friendship);
        requirePending(friendship);

        friendship.setStatus(FriendshipStatus.ACCEPTED);

        return FriendshipResponse.from(friendshipRepository.save(friendship));
    }

    @PutMapping("/{id}/reject")
    public FriendshipResponse reject(@PathVariable Long id) {

        Friendship friendship = friendshipRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Friendship request not found"));

        requireRecipient(friendship);
        requirePending(friendship);

        friendship.setStatus(FriendshipStatus.REJECTED);

        return FriendshipResponse.from(friendshipRepository.save(friendship));
    }

    private void requireCurrentUser(Long userId) {
        if (!currentUser.requireUserId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only access your own friendships");
        }
    }

    private void requireRecipient(Friendship friendship) {
        requireCurrentUser(friendship.getFriend().getId());
    }

    private void requirePending(Friendship friendship) {
        if (friendship.getStatus() != FriendshipStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Friendship request is no longer pending");
        }
    }
}
