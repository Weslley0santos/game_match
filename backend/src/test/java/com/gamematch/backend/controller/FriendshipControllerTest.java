package com.gamematch.backend.controller;

import com.gamematch.backend.dto.FriendshipResponse;
import com.gamematch.backend.model.Friendship;
import com.gamematch.backend.model.FriendshipStatus;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.FriendshipRepository;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.CurrentUserService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class FriendshipControllerTest {

    @Test
    void createsPendingRequestFromCurrentUserToSelectedFriend() {
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        UserRepository users = mock(UserRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        FriendshipController controller = new FriendshipController(friendships, users, currentUser);
        User sender = user(1L, "Sender");
        User receiver = user(2L, "Receiver");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(sender));
        when(users.findById(2L)).thenReturn(Optional.of(receiver));
        when(friendships.findBetweenUsers(sender, receiver)).thenReturn(Optional.empty());
        when(friendships.save(any(Friendship.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FriendshipResponse response = controller.addFriend(2L);

        assertThat(response.getUserId()).isEqualTo(1L);
        assertThat(response.getFriendId()).isEqualTo(2L);
        assertThat(response.getStatus()).isEqualTo(FriendshipStatus.PENDING);
        verify(friendships).save(any(Friendship.class));
    }

    @Test
    void rejectsSelfFriendRequestWithoutLookingUpUsers() {
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        UserRepository users = mock(UserRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        FriendshipController controller = new FriendshipController(friendships, users, currentUser);
        when(currentUser.requireUserId()).thenReturn(1L);

        assertThatThrownBy(() -> controller.addFriend(1L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        verify(users, never()).findById(any());
        verify(friendships, never()).save(any(Friendship.class));
    }

    @Test
    void rejectsExistingPendingOrAcceptedFriendshipButAllowsRetryAfterRejection() {
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        UserRepository users = mock(UserRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        FriendshipController controller = new FriendshipController(friendships, users, currentUser);
        User sender = user(1L, "Sender");
        User receiver = user(2L, "Receiver");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(sender));
        when(users.findById(2L)).thenReturn(Optional.of(receiver));
        when(friendships.findBetweenUsers(sender, receiver)).thenReturn(
                Optional.of(new Friendship(sender, receiver, FriendshipStatus.PENDING)),
                Optional.of(new Friendship(sender, receiver, FriendshipStatus.ACCEPTED)),
                Optional.of(new Friendship(sender, receiver, FriendshipStatus.REJECTED))
        );

        assertThatThrownBy(() -> controller.addFriend(2L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));
        assertThatThrownBy(() -> controller.addFriend(2L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));

        when(friendships.save(any(Friendship.class))).thenAnswer(invocation -> invocation.getArgument(0));
        FriendshipResponse retry = controller.addFriend(2L);
        assertThat(retry.getStatus()).isEqualTo(FriendshipStatus.PENDING);
        verify(friendships).save(any(Friendship.class));
    }

    @Test
    void acceptsPendingRequestAndRejectsItAfterResolution() {
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        UserRepository users = mock(UserRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        FriendshipController controller = new FriendshipController(friendships, users, currentUser);
        Friendship pending = new Friendship(user(1L, "Sender"), user(2L, "Receiver"), FriendshipStatus.PENDING);
        when(currentUser.requireUserId()).thenReturn(2L);
        when(friendships.findById(10L)).thenReturn(Optional.of(pending));
        when(friendships.save(any(Friendship.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FriendshipResponse response = controller.accept(10L);
        assertThat(response.getStatus()).isEqualTo(FriendshipStatus.ACCEPTED);

        assertThatThrownBy(() -> controller.reject(10L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));
        verify(friendships).save(pending);
    }

    @Test
    void recipientCanRejectPendingRequestAndListsFriendsAndRequests() {
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        UserRepository users = mock(UserRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        FriendshipController controller = new FriendshipController(friendships, users, currentUser);
        User owner = user(2L, "Owner");
        Friendship pending = new Friendship(user(1L, "Sender"), owner, FriendshipStatus.PENDING);
        Friendship pendingRequest = new Friendship(user(4L, "Other Sender"), owner, FriendshipStatus.PENDING);
        Friendship accepted = new Friendship(owner, user(3L, "Friend"), FriendshipStatus.ACCEPTED);
        when(currentUser.requireUserId()).thenReturn(2L);
        when(friendships.findById(20L)).thenReturn(Optional.of(pending));
        when(friendships.save(any(Friendship.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(users.findById(2L)).thenReturn(Optional.of(owner));
        when(friendships.findByFriendAndStatus(owner, FriendshipStatus.PENDING)).thenReturn(List.of(pendingRequest));
        when(friendships.findByUserAndStatus(owner, FriendshipStatus.ACCEPTED)).thenReturn(List.of(accepted));

        assertThat(controller.reject(20L).getStatus()).isEqualTo(FriendshipStatus.REJECTED);
        assertThat(controller.getPendingRequests(2L))
                .extracting(FriendshipResponse::getUserId)
                .containsExactly(4L);
        assertThat(controller.getFriends(2L))
                .extracting(FriendshipResponse::getFriendId)
                .containsExactly(3L);
    }

    private static User user(Long id, String name) {
        User user = new User();
        user.setId(id);
        user.setName(name);
        return user;
    }
}
