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

class PlayInviteControllerTest {

    @Test
    void createsPendingInviteForAcceptedFriend() {
        PlayInviteRepository invites = mock(PlayInviteRepository.class);
        UserRepository users = mock(UserRepository.class);
        GameRepository games = mock(GameRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        PlayInviteController controller = new PlayInviteController(invites, users, games, friendships, currentUser);
        User sender = user(1L, "Sender");
        User receiver = user(2L, "Receiver");
        Game game = game(42L, "Apex");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(sender));
        when(users.findById(2L)).thenReturn(Optional.of(receiver));
        when(games.findById(42L)).thenReturn(Optional.of(game));
        when(friendships.countBetweenUsersAndStatus(sender, receiver, FriendshipStatus.ACCEPTED)).thenReturn(1L);
        when(invites.existsBySenderAndReceiverAndGameAndStatus(
                sender, receiver, game, PlayInviteStatus.PENDING
        )).thenReturn(false);
        when(invites.save(any(PlayInvite.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PlayInviteResponse response = controller.create(2L, 42L);

        assertThat(response.getSenderId()).isEqualTo(1L);
        assertThat(response.getReceiverId()).isEqualTo(2L);
        assertThat(response.getGameTitle()).isEqualTo("Apex");
        assertThat(response.getStatus()).isEqualTo(PlayInviteStatus.PENDING);
        verify(invites).save(any(PlayInvite.class));
    }

    @Test
    void refusesInviteToSelfBeforeRepositoryAccess() {
        PlayInviteRepository invites = mock(PlayInviteRepository.class);
        UserRepository users = mock(UserRepository.class);
        GameRepository games = mock(GameRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        PlayInviteController controller = new PlayInviteController(invites, users, games, friendships, currentUser);
        when(currentUser.requireUserId()).thenReturn(1L);

        assertThatThrownBy(() -> controller.create(1L, 42L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        verify(users, never()).findById(any());
        verify(invites, never()).save(any(PlayInvite.class));
    }

    @Test
    void refusesInviteToUserWithoutAcceptedFriendship() {
        PlayInviteRepository invites = mock(PlayInviteRepository.class);
        UserRepository users = mock(UserRepository.class);
        GameRepository games = mock(GameRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        PlayInviteController controller = new PlayInviteController(invites, users, games, friendships, currentUser);
        User sender = user(1L, "Sender");
        User receiver = user(2L, "Receiver");
        Game game = game(42L, "Apex");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(sender));
        when(users.findById(2L)).thenReturn(Optional.of(receiver));
        when(games.findById(42L)).thenReturn(Optional.of(game));
        when(friendships.countBetweenUsersAndStatus(sender, receiver, FriendshipStatus.ACCEPTED)).thenReturn(0L);

        assertThatThrownBy(() -> controller.create(2L, 42L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));

        verify(invites, never()).save(any(PlayInvite.class));
        verify(invites, never()).existsBySenderAndReceiverAndGameAndStatus(
                sender, receiver, game, PlayInviteStatus.PENDING
        );
    }

    @Test
    void refusesDuplicatePendingInviteWithoutSavingAnother() {
        PlayInviteRepository invites = mock(PlayInviteRepository.class);
        UserRepository users = mock(UserRepository.class);
        GameRepository games = mock(GameRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        PlayInviteController controller = new PlayInviteController(invites, users, games, friendships, currentUser);
        User sender = user(1L, "Sender");
        User receiver = user(2L, "Receiver");
        Game game = game(42L, "Apex");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(sender));
        when(users.findById(2L)).thenReturn(Optional.of(receiver));
        when(games.findById(42L)).thenReturn(Optional.of(game));
        when(friendships.countBetweenUsersAndStatus(sender, receiver, FriendshipStatus.ACCEPTED)).thenReturn(1L);
        when(invites.existsBySenderAndReceiverAndGameAndStatus(
                sender, receiver, game, PlayInviteStatus.PENDING
        )).thenReturn(true);

        assertThatThrownBy(() -> controller.create(2L, 42L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));

        verify(invites, never()).save(any(PlayInvite.class));
    }

    @Test
    void acceptsAndRejectsPendingInvitesAndConflictsAfterResolution() {
        PlayInviteRepository invites = mock(PlayInviteRepository.class);
        UserRepository users = mock(UserRepository.class);
        GameRepository games = mock(GameRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        PlayInviteController controller = new PlayInviteController(invites, users, games, friendships, currentUser);
        PlayInvite accepted = invite(1L, 2L, 10L, PlayInviteStatus.PENDING);
        PlayInvite rejected = invite(1L, 2L, 11L, PlayInviteStatus.PENDING);
        when(currentUser.requireUserId()).thenReturn(2L);
        when(invites.findById(10L)).thenReturn(Optional.of(accepted));
        when(invites.findById(11L)).thenReturn(Optional.of(rejected));
        when(invites.save(any(PlayInvite.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(controller.accept(10L).getStatus()).isEqualTo(PlayInviteStatus.ACCEPTED);
        assertThat(controller.reject(11L).getStatus()).isEqualTo(PlayInviteStatus.REJECTED);
        assertThatThrownBy(() -> controller.accept(10L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));

        verify(invites).save(accepted);
        verify(invites).save(rejected);
    }

    @Test
    void listsInvitesBySenderAndReceiver() {
        PlayInviteRepository invites = mock(PlayInviteRepository.class);
        UserRepository users = mock(UserRepository.class);
        GameRepository games = mock(GameRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        PlayInviteController controller = new PlayInviteController(invites, users, games, friendships, currentUser);
        User owner = user(2L, "Owner");
        PlayInvite sentInvite = invite(2L, 3L, 10L, PlayInviteStatus.PENDING);
        PlayInvite receivedInvite = invite(1L, 2L, 11L, PlayInviteStatus.ACCEPTED);
        when(currentUser.requireUserId()).thenReturn(2L);
        when(users.findById(2L)).thenReturn(Optional.of(owner));
        when(invites.findBySender(owner)).thenReturn(List.of(sentInvite));
        when(invites.findByReceiver(owner)).thenReturn(List.of(receivedInvite));

        List<PlayInviteResponse> sent = controller.getSent(2L);
        assertThat(sent).extracting(PlayInviteResponse::getId).containsExactly(sentInvite.getId());
        assertThat(sent).extracting(PlayInviteResponse::getReceiverId).containsExactly(3L);
        assertThat(sent).extracting(PlayInviteResponse::getStatus).containsExactly(PlayInviteStatus.PENDING);

        List<PlayInviteResponse> received = controller.getReceived(2L);
        assertThat(received).extracting(PlayInviteResponse::getId).containsExactly(receivedInvite.getId());
        assertThat(received).extracting(PlayInviteResponse::getSenderId).containsExactly(1L);
        assertThat(received).extracting(PlayInviteResponse::getStatus).containsExactly(PlayInviteStatus.ACCEPTED);
    }

    private static User user(Long id, String name) {
        User user = new User();
        user.setId(id);
        user.setName(name);
        return user;
    }

    private static Game game(Long id, String title) {
        Game game = new Game(title, "Genre", "Description", "image.jpg", id, List.of("PC"));
        game.setId(id);
        return game;
    }

    private static PlayInvite invite(Long senderId, Long receiverId, Long gameId, PlayInviteStatus status) {
        return new PlayInvite(
                user(senderId, "Sender"),
                user(receiverId, "Receiver"),
                game(gameId, "Game " + gameId),
                status
        );
    }
}
