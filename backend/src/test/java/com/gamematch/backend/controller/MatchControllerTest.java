package com.gamematch.backend.controller;

import com.gamematch.backend.dto.CompatibleGameResponse;
import com.gamematch.backend.dto.FriendInterestResponse;
import com.gamematch.backend.dto.MatchResponse;
import com.gamematch.backend.model.Friendship;
import com.gamematch.backend.model.FriendshipStatus;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.model.Rating;
import com.gamematch.backend.model.RatingType;
import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.FriendshipRepository;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.repository.RatingRepository;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.CurrentUserService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MatchControllerTest {

    @Test
    void requiresAcceptedFriendshipBeforeComparingRatings() {
        RatingRepository ratings = mock(RatingRepository.class);
        GameRepository games = mock(GameRepository.class);
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        MatchController controller = new MatchController(ratings, games, users, friendships, currentUser);
        User owner = user(1L, "Owner");
        User friend = user(2L, "Friend");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(owner));
        when(users.findById(2L)).thenReturn(Optional.of(friend));
        when(friendships.countBetweenUsersAndStatus(owner, friend, FriendshipStatus.ACCEPTED)).thenReturn(0L);

        assertThatThrownBy(() -> controller.getMatches(1L, 2L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));

        verify(ratings, never()).findByUserIdAndTypeIn(eq(1L), anyList());
    }

    @Test
    void returnsOnlySharedPositiveRatingsWithFavoritePriorityAndTitleOrdering() {
        RatingRepository ratings = mock(RatingRepository.class);
        GameRepository games = mock(GameRepository.class);
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        MatchController controller = new MatchController(ratings, games, users, friendships, currentUser);
        User owner = user(1L, "Owner");
        User friend = user(2L, "Friend");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(owner));
        when(users.findById(2L)).thenReturn(Optional.of(friend));
        when(friendships.countBetweenUsersAndStatus(owner, friend, FriendshipStatus.ACCEPTED)).thenReturn(1L);
        when(ratings.findByUserIdAndTypeIn(eq(1L), anyList())).thenReturn(List.of(
                new Rating(1L, 10L, RatingType.LIKE),
                new Rating(1L, 20L, RatingType.FAVORITE),
                new Rating(1L, 30L, RatingType.LIKE),
                new Rating(1L, 50L, RatingType.LIKE),
                new Rating(1L, 60L, RatingType.LIKE)
        ));
        when(ratings.findByUserIdAndTypeIn(eq(2L), anyList())).thenReturn(List.of(
                new Rating(2L, 10L, RatingType.FAVORITE),
                new Rating(2L, 20L, RatingType.LIKE),
                new Rating(2L, 40L, RatingType.FAVORITE),
                new Rating(2L, 50L, RatingType.LIKE),
                new Rating(2L, 60L, RatingType.LIKE)
        ));
        when(games.findById(10L)).thenReturn(Optional.of(game(10L, "Zelda")));
        when(games.findById(20L)).thenReturn(Optional.of(game(20L, "Apex")));
        when(games.findById(50L)).thenReturn(Optional.of(game(50L, "Outer Wilds")));
        when(games.findById(60L)).thenReturn(Optional.of(game(60L, "Celeste")));

        List<MatchResponse> matches = controller.getMatches(1L, 2L);

        assertThat(matches).extracting(MatchResponse::getGameTitle)
                .containsExactly("Apex", "Zelda", "Celeste", "Outer Wilds");
        assertThat(matches).extracting(MatchResponse::getPriorityInterest)
                .containsExactly(RatingType.FAVORITE, RatingType.FAVORITE, RatingType.LIKE, RatingType.LIKE);
        assertThat(matches).extracting(MatchResponse::getGameId).containsExactly(20L, 10L, 60L, 50L);
        verify(ratings).findByUserIdAndTypeIn(1L, List.of(RatingType.LIKE, RatingType.FAVORITE));
        verify(ratings).findByUserIdAndTypeIn(2L, List.of(RatingType.LIKE, RatingType.FAVORITE));
    }

    @Test
    void countsCompatibleFriendsAndFavoriteInterestsAcrossAcceptedFriends() {
        RatingRepository ratings = mock(RatingRepository.class);
        GameRepository games = mock(GameRepository.class);
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        MatchController controller = new MatchController(ratings, games, users, friendships, currentUser);
        User owner = user(1L, "Owner");
        User bob = user(2L, "Bob");
        User carol = user(3L, "Carol");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(owner));
        when(friendships.findByUserAndStatus(owner, FriendshipStatus.ACCEPTED)).thenReturn(List.of(
                new Friendship(owner, bob, FriendshipStatus.ACCEPTED),
                new Friendship(carol, owner, FriendshipStatus.ACCEPTED)
        ));
        when(ratings.findByUserIdAndTypeIn(eq(1L), anyList())).thenReturn(List.of(
                new Rating(1L, 10L, RatingType.FAVORITE),
                new Rating(1L, 20L, RatingType.LIKE)
        ));
        when(ratings.findByUserIdAndTypeIn(eq(2L), anyList())).thenReturn(List.of(
                new Rating(2L, 10L, RatingType.FAVORITE),
                new Rating(2L, 20L, RatingType.LIKE)
        ));
        when(ratings.findByUserIdAndTypeIn(eq(3L), anyList())).thenReturn(List.of(
                new Rating(3L, 10L, RatingType.LIKE),
                new Rating(3L, 20L, RatingType.FAVORITE)
        ));
        when(games.findById(10L)).thenReturn(Optional.of(game(10L, "Apex")));
        when(games.findById(20L)).thenReturn(Optional.of(game(20L, "Zelda")));

        List<CompatibleGameResponse> compatibleGames = controller.getCompatibleGames(1L);

        assertThat(compatibleGames).hasSize(2);
        assertThat(compatibleGames.get(0).getGameTitle()).isEqualTo("Apex");
        assertThat(compatibleGames.get(0).getCompatibleFriendsCount()).isEqualTo(2);
        assertThat(compatibleGames.get(0).getFavoriteFriendsCount()).isEqualTo(1);
        assertThat(compatibleGames.get(1).getGameTitle()).isEqualTo("Zelda");
        assertThat(compatibleGames.get(1).getCompatibleFriendsCount()).isEqualTo(2);
        assertThat(compatibleGames.get(1).getFavoriteFriendsCount()).isEqualTo(1);
        verify(ratings).findByUserIdAndTypeIn(1L, List.of(RatingType.LIKE, RatingType.FAVORITE));
        verify(ratings).findByUserIdAndTypeIn(2L, List.of(RatingType.LIKE, RatingType.FAVORITE));
        verify(ratings).findByUserIdAndTypeIn(3L, List.of(RatingType.LIKE, RatingType.FAVORITE));
    }

    @Test
    void listsInterestedAcceptedFriendsWithFavoritesFirst() {
        RatingRepository ratings = mock(RatingRepository.class);
        GameRepository games = mock(GameRepository.class);
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        MatchController controller = new MatchController(ratings, games, users, friendships, currentUser);
        User owner = user(1L, "Owner");
        User bob = user(2L, "Bob");
        User carol = user(3L, "Carol");
        when(currentUser.requireUserId()).thenReturn(1L);
        when(users.findById(1L)).thenReturn(Optional.of(owner));
        when(games.findById(10L)).thenReturn(Optional.of(game(10L, "Apex")));
        when(ratings.findByUserIdAndGameIdAndTypeIn(eq(1L), eq(10L), anyList())).thenReturn(
                List.of(new Rating(1L, 10L, RatingType.LIKE))
        );
        when(friendships.findByUserAndStatus(owner, FriendshipStatus.ACCEPTED)).thenReturn(List.of(
                new Friendship(owner, bob, FriendshipStatus.ACCEPTED),
                new Friendship(owner, carol, FriendshipStatus.ACCEPTED)
        ));
        when(ratings.findByUserIdAndGameIdAndTypeIn(eq(2L), eq(10L), anyList())).thenReturn(
                List.of(new Rating(2L, 10L, RatingType.LIKE))
        );
        when(ratings.findByUserIdAndGameIdAndTypeIn(eq(3L), eq(10L), anyList())).thenReturn(
                List.of(new Rating(3L, 10L, RatingType.FAVORITE))
        );

        List<FriendInterestResponse> interestedFriends = controller.getInterestedFriends(1L, 10L);

        assertThat(interestedFriends).extracting(FriendInterestResponse::getFriendName)
                .containsExactly("Carol", "Bob");
        assertThat(interestedFriends).extracting(FriendInterestResponse::getInterestType)
                .containsExactly(RatingType.FAVORITE, RatingType.LIKE);
        verify(ratings).findByUserIdAndGameIdAndTypeIn(
                1L, 10L, List.of(RatingType.LIKE, RatingType.FAVORITE));
        verify(ratings).findByUserIdAndGameIdAndTypeIn(
                2L, 10L, List.of(RatingType.LIKE, RatingType.FAVORITE));
        verify(ratings).findByUserIdAndGameIdAndTypeIn(
                3L, 10L, List.of(RatingType.LIKE, RatingType.FAVORITE));
    }

    @Test
    void rejectsCompatibilityRequestForAnotherUserBeforeLoadingData() {
        RatingRepository ratings = mock(RatingRepository.class);
        GameRepository games = mock(GameRepository.class);
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        MatchController controller = new MatchController(ratings, games, users, friendships, currentUser);
        when(currentUser.requireUserId()).thenReturn(1L);

        assertThatThrownBy(() -> controller.getMatches(2L, 3L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));

        verify(users, never()).findById(2L);
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
}
