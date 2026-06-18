package com.gamematch.backend.repository;

import com.gamematch.backend.model.Friendship;
import com.gamematch.backend.model.FriendshipStatus;
import com.gamematch.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FriendshipRepository extends JpaRepository<Friendship, Long> {

    @Query("select f from Friendship f where f.status = :status and (f.user = :user or f.friend = :user)")
    List<Friendship> findByUserAndStatus(@Param("user") User user, @Param("status") FriendshipStatus status);

    List<Friendship> findByFriendAndStatus(User friend, FriendshipStatus status);

    @Query("select f from Friendship f where (f.user = :user and f.friend = :friend) or (f.user = :friend and f.friend = :user)")
    Optional<Friendship> findBetweenUsers(@Param("user") User user, @Param("friend") User friend);

    @Query("select count(f) from Friendship f where f.status = :status and ((f.user = :user and f.friend = :friend) or (f.user = :friend and f.friend = :user))")
    long countBetweenUsersAndStatus(
            @Param("user") User user,
            @Param("friend") User friend,
            @Param("status") FriendshipStatus status
    );
}
