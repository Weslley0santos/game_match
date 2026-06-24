package com.gamematch.backend.repository;

import com.gamematch.backend.model.Game;
import com.gamematch.backend.model.PlayInvite;
import com.gamematch.backend.model.PlayInviteStatus;
import com.gamematch.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PlayInviteRepository extends JpaRepository<PlayInvite, Long> {

    List<PlayInvite> findByReceiver(User receiver);

    List<PlayInvite> findBySender(User sender);

    boolean existsBySenderAndReceiverAndGameAndStatus(
            User sender,
            User receiver,
            Game game,
            PlayInviteStatus status
    );
}
