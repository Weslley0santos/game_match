package com.gamematch.backend.controller;

import com.gamematch.backend.dto.IgdbGameResponse;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.service.IgdbGameService;
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
        verify(gameRepository).save(any(Game.class));
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

    @Test
    void bulkImportSkipsInvalidDuplicateAndAlreadyStoredCatalogEntries() {
        GameRepository gameRepository = mock(GameRepository.class);
        IgdbGameService igdbGameService = mock(IgdbGameService.class);
        GameController controller = new GameController(gameRepository, igdbGameService);

        IgdbGameResponse missingId = igdbGame(null, "Unknown", 0, null, null);
        IgdbGameResponse addOn = igdbGame(2L, "Game DLC", 0, null, null);
        IgdbGameResponse child = igdbGame(3L, "Game Child", 0, 1L, null);
        IgdbGameResponse version = igdbGame(4L, "Game Version", 0, null, 1L);
        IgdbGameResponse firstCopy = igdbGame(10L, "Zelda", 0, null, null);
        IgdbGameResponse duplicateId = igdbGame(10L, "Another Game", 0, null, null);
        IgdbGameResponse stored = igdbGame(20L, "Mario", 0, null, null);
        IgdbGameResponse newGame = igdbGame(30L, "Hades", 0, null, null);
        when(igdbGameService.searchMainGames("catalog")).thenReturn(List.of(
                missingId, addOn, child, version, firstCopy, duplicateId, stored, newGame
        ));
        when(gameRepository.existsByIgdbId(20L)).thenReturn(true);
        when(gameRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        List<Game> imported = controller.importIgdbGames("catalog");

        assertThat(imported).extracting(Game::getIgdbId).containsExactly(10L, 30L);
        verify(gameRepository).existsByIgdbId(10L);
        verify(gameRepository).existsByIgdbId(20L);
        verify(gameRepository).existsByIgdbId(30L);
        verify(gameRepository, never()).existsByIgdbId(2L);
        verify(gameRepository, never()).existsByIgdbId(3L);
        verify(gameRepository, never()).existsByIgdbId(4L);
    }

    @Test
    void rejectsBlankSearchBeforeCallingIgdb() {
        GameRepository gameRepository = mock(GameRepository.class);
        IgdbGameService igdbGameService = mock(IgdbGameService.class);
        GameController controller = new GameController(gameRepository, igdbGameService);

        assertThatThrownBy(() -> controller.importIgdbGames("  "))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        verify(igdbGameService, never()).searchMainGames(any());
        verify(gameRepository, never()).saveAll(any());
    }

    @Test
    void exposesTheStoredGameCatalog() {
        GameRepository gameRepository = mock(GameRepository.class);
        GameController controller = new GameController(gameRepository, mock(IgdbGameService.class));
        List<Game> catalog = List.of(new Game("Apex", "Shooter", "", "image.jpg", 10L, List.of("PC")));
        when(gameRepository.findAll()).thenReturn(catalog);

        assertThat(controller.getAllGames()).containsExactlyElementsOf(catalog);
    }

    @Test
    void importOneReturnsExistingCatalogEntryWithoutSavingDuplicate() {
        GameRepository gameRepository = mock(GameRepository.class);
        IgdbGameService igdbGameService = mock(IgdbGameService.class);
        GameController controller = new GameController(gameRepository, igdbGameService);
        Game existing = new Game("Hollow Knight", "Metroidvania", "", "image.jpg", 14593L, List.of("PC"));
        when(igdbGameService.searchMainGames("Hollow Knight"))
                .thenReturn(List.of(igdbGame(14593L, "Hollow Knight", 0, null, null)));
        when(gameRepository.findByIgdbId(14593L)).thenReturn(Optional.of(existing));

        assertThat(controller.importOneIgdbGame("Hollow Knight")).isSameAs(existing);

        verify(gameRepository, never()).save(any(Game.class));
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
