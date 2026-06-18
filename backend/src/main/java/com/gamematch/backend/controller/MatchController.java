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
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/matches")
public class MatchController {

    private final RatingRepository ratingRepository;
    private final GameRepository gameRepository;
    private final UserRepository userRepository;
    private final FriendshipRepository friendshipRepository;

    public MatchController(
            RatingRepository ratingRepository,
            GameRepository gameRepository,
            UserRepository userRepository,
            FriendshipRepository friendshipRepository
    ) {
        this.ratingRepository = ratingRepository;
        this.gameRepository = gameRepository;
        this.userRepository = userRepository;
        this.friendshipRepository = friendshipRepository;
    }

    @GetMapping("/{userId}/{friendId}")
    public List<MatchResponse> getMatches(
            @PathVariable Long userId,
            @PathVariable Long friendId
    ) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        User friend = userRepository.findById(friendId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Friend not found"));

        long acceptedFriendships = friendshipRepository.countBetweenUsersAndStatus(
                user,
                friend,
                FriendshipStatus.ACCEPTED
        );

        if (acceptedFriendships == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Users must be accepted friends to compare games");
        }

        Map<Long, RatingType> userRatings = getPositiveRatingsByGame(userId);
        Map<Long, RatingType> friendRatings = getPositiveRatingsByGame(friendId);

        List<MatchResponse> matches = new ArrayList<>();

        for (Map.Entry<Long, RatingType> userRating : userRatings.entrySet()) {
            RatingType friendRating = friendRatings.get(userRating.getKey());

            if (friendRating == null) {
                continue;
            }

            Game game = gameRepository
                    .findById(userRating.getKey())
                    .orElse(null);

            if (game != null) {
                matches.add(
                        new MatchResponse(
                                game.getId(),
                                game.getTitle(),
                                game.getImageUrl(),
                                userRating.getValue(),
                                friendRating,
                                getPriorityInterest(userRating.getValue(), friendRating)
                        )
                );
            }
        }

        matches.sort(
                Comparator.comparing((MatchResponse match) -> getPriorityScore(match.getPriorityInterest()))
                        .reversed()
                        .thenComparing(MatchResponse::getGameTitle)
        );

        return matches;
    }

    @GetMapping("/users/{userId}/games")
    public List<CompatibleGameResponse> getCompatibleGames(@PathVariable Long userId) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        Map<Long, RatingType> userRatings = getPositiveRatingsByGame(userId);
        List<Friendship> friendships = friendshipRepository.findByUserAndStatus(user, FriendshipStatus.ACCEPTED);
        Map<Long, CompatibleGameAccumulator> compatibleGames = new HashMap<>();

        for (Friendship friendship : friendships) {
            User friend = getOtherUser(friendship, user);
            Map<Long, RatingType> friendRatings = getPositiveRatingsByGame(friend.getId());

            for (Map.Entry<Long, RatingType> userRating : userRatings.entrySet()) {
                RatingType friendRating = friendRatings.get(userRating.getKey());

                if (friendRating == null) {
                    continue;
                }

                CompatibleGameAccumulator accumulator = compatibleGames.computeIfAbsent(
                        userRating.getKey(),
                        gameId -> new CompatibleGameAccumulator(userRating.getValue())
                );

                accumulator.compatibleFriendsCount++;

                if (friendRating == RatingType.FAVORITE) {
                    accumulator.favoriteFriendsCount++;
                }
            }
        }

        List<CompatibleGameResponse> responses = new ArrayList<>();

        for (Map.Entry<Long, CompatibleGameAccumulator> entry : compatibleGames.entrySet()) {
            Optional<Game> game = gameRepository.findById(entry.getKey());

            if (game.isEmpty()) {
                continue;
            }

            CompatibleGameAccumulator accumulator = entry.getValue();
            RatingType priorityInterest = accumulator.favoriteFriendsCount > 0
                    ? RatingType.FAVORITE
                    : RatingType.LIKE;

            responses.add(
                    new CompatibleGameResponse(
                            game.get().getId(),
                            game.get().getTitle(),
                            game.get().getImageUrl(),
                            accumulator.compatibleFriendsCount,
                            accumulator.favoriteFriendsCount,
                            accumulator.userInterest,
                            priorityInterest
                    )
            );
        }

        responses.sort(
                Comparator.comparing((CompatibleGameResponse game) -> getPriorityScore(game.getPriorityInterest()))
                        .reversed()
                        .thenComparing(CompatibleGameResponse::getCompatibleFriendsCount, Comparator.reverseOrder())
                        .thenComparing(CompatibleGameResponse::getGameTitle)
        );

        return responses;
    }

    @GetMapping("/users/{userId}/games/{gameId}/friends")
    public List<FriendInterestResponse> getInterestedFriends(
            @PathVariable Long userId,
            @PathVariable Long gameId
    ) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        gameRepository.findById(gameId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Game not found"));

        RatingType userInterest = getBestPositiveRating(userId, gameId);

        if (userInterest == null) {
            return List.of();
        }

        List<FriendInterestResponse> responses = new ArrayList<>();
        List<Friendship> friendships = friendshipRepository.findByUserAndStatus(user, FriendshipStatus.ACCEPTED);

        for (Friendship friendship : friendships) {
            User friend = getOtherUser(friendship, user);
            RatingType friendInterest = getBestPositiveRating(friend.getId(), gameId);

            if (friendInterest != null) {
                responses.add(
                        new FriendInterestResponse(
                                friend.getId(),
                                friend.getName(),
                                friendInterest
                        )
                );
            }
        }

        responses.sort(
                Comparator.comparing((FriendInterestResponse friend) -> getPriorityScore(friend.getInterestType()))
                        .reversed()
                        .thenComparing(FriendInterestResponse::getFriendName)
        );

        return responses;
    }

    private Map<Long, RatingType> getPositiveRatingsByGame(Long userId) {
        List<Rating> ratings = ratingRepository.findByUserIdAndTypeIn(
                userId,
                List.of(RatingType.LIKE, RatingType.FAVORITE)
        );

        Map<Long, RatingType> ratingsByGame = new HashMap<>();

        for (Rating rating : ratings) {
            RatingType current = ratingsByGame.get(rating.getGameId());

            if (current == null || getPriorityScore(rating.getType()) > getPriorityScore(current)) {
                ratingsByGame.put(rating.getGameId(), rating.getType());
            }
        }

        return ratingsByGame;
    }

    private RatingType getBestPositiveRating(Long userId, Long gameId) {
        List<Rating> ratings = ratingRepository.findByUserIdAndGameIdAndTypeIn(
                userId,
                gameId,
                List.of(RatingType.LIKE, RatingType.FAVORITE)
        );

        RatingType bestRating = null;

        for (Rating rating : ratings) {
            if (bestRating == null || getPriorityScore(rating.getType()) > getPriorityScore(bestRating)) {
                bestRating = rating.getType();
            }
        }

        return bestRating;
    }

    private User getOtherUser(Friendship friendship, User user) {
        return friendship.getUser().getId().equals(user.getId())
                ? friendship.getFriend()
                : friendship.getUser();
    }

    private RatingType getPriorityInterest(RatingType userInterest, RatingType friendInterest) {
        if (userInterest == RatingType.FAVORITE || friendInterest == RatingType.FAVORITE) {
            return RatingType.FAVORITE;
        }

        return RatingType.LIKE;
    }

    private int getPriorityScore(RatingType ratingType) {
        if (ratingType == RatingType.FAVORITE) {
            return 2;
        }

        if (ratingType == RatingType.LIKE) {
            return 1;
        }

        return 0;
    }

    private static class CompatibleGameAccumulator {
        private int compatibleFriendsCount;
        private int favoriteFriendsCount;
        private final RatingType userInterest;

        private CompatibleGameAccumulator(RatingType userInterest) {
            this.userInterest = userInterest;
        }
    }
}
