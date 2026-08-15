package com.gamematch.backend.controller;

import com.gamematch.backend.dto.IgdbGameResponse;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.service.IgdbGameService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class GameControllerTest {

    @Test
    void importOnePrefersMainGameWhenPortWithSameNameComesFirst() {
        GameRepository gameRepository = mock(GameRepository.class);
        IgdbGameService igdbGameService = mock(IgdbGameService.class);
        GameController controller = new GameController(gameRepository, igdbGameService);

        IgdbGameResponse unofficialPort = igdbGame(365702L, "Hollow Knight", 11, null, null);
        IgdbGameResponse mainGame = igdbGame(14593L, "Hollow Knight", 0, null, null);

        when(igdbGameService.searchMainGames("Hollow Knight"))
                .thenReturn(List.of(unofficialPort, mainGame));
        when(gameRepository.findByIgdbId(14593L)).thenReturn(Optional.empty());
        when(gameRepository.save(any(Game.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Game importedGame = controller.importOneIgdbGame("Hollow Knight");

        assertThat(importedGame.getIgdbId()).isEqualTo(14593L);
        verify(gameRepository).findByIgdbId(14593L);
    }

    @Test
    void bulkImportExcludesNonMainGamesEvenIfTheyHaveAValidName() {
        GameRepository gameRepository = mock(GameRepository.class);
        IgdbGameService igdbGameService = mock(IgdbGameService.class);
        GameController controller = new GameController(gameRepository, igdbGameService);

        IgdbGameResponse unofficialPort = igdbGame(365702L, "Hollow Knight", 11, null, null);
        IgdbGameResponse mainGame = igdbGame(14593L, "Hollow Knight", 0, null, null);

        when(igdbGameService.searchMainGames("Hollow Knight"))
                .thenReturn(List.of(unofficialPort, mainGame));
        when(gameRepository.existsByIgdbId(14593L)).thenReturn(false);
        when(gameRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        List<Game> importedGames = controller.importIgdbGames("Hollow Knight");

        assertThat(importedGames)
                .extracting(Game::getIgdbId)
                .containsExactly(14593L);
    }

    private IgdbGameResponse igdbGame(
            Long id,
            String name,
            Integer gameType,
            Long parentGame,
            Long versionParent
    ) {
        IgdbGameResponse game = new IgdbGameResponse();
        game.setId(id);
        game.setName(name);
        game.setGameType(gameType);
        game.setParentGame(parentGame);
        game.setVersionParent(versionParent);
        return game;
    }
}
