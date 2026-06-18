package com.gamematch.backend.repository;

import com.gamematch.backend.model.Rating;
import com.gamematch.backend.model.RatingType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RatingRepository extends JpaRepository<Rating, Long> {

    List<Rating> findByUserId(Long userId);

    List<Rating> findAllByUserIdAndGameId(Long userId, Long gameId);

    List<Rating> findByUserIdAndTypeIn(
            Long userId,
            List<RatingType> types
    );

    List<Rating> findByUserIdAndGameIdAndTypeIn(
            Long userId,
            Long gameId,
            List<RatingType> types
    );
}
