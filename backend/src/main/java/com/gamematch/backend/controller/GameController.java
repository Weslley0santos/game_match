package com.gamematch.backend.controller;

import com.gamematch.backend.dto.IgdbGameResponse;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.service.IgdbGameService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/games")
public class GameController {

    private static final String NOT_INFORMED = "N\u00e3o informado";

    private final GameRepository gameRepository;
    private final IgdbGameService igdbGameService;

    public GameController(GameRepository gameRepository, IgdbGameService igdbGameService) {
        this.gameRepository = gameRepository;
        this.igdbGameService = igdbGameService;
    }

    // GET /games -> lista todos os jogos
    @GetMapping
    public List<Game> getAllGames() {
        return gameRepository.findAll();
    }

    // GET /games/igdb/search?query=termo -> busca jogos na IGDB sem salvar no banco
    @GetMapping("/igdb/search")
    public List<IgdbGameResponse> searchIgdbGames(@RequestParam(required = false) String query) {
        if (query == null || query.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Query must not be blank.");
        }

        return igdbGameService.searchGames(query);
    }

    // POST /games/igdb/import?query=termo -> busca jogos na IGDB e salva os novos no banco
    @PostMapping("/igdb/import")
    public List<Game> importIgdbGames(@RequestParam(required = false) String query) {
        if (query == null || query.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Query must not be blank.");
        }

        Set<Long> igdbIdsToImport = new HashSet<>();
        List<Game> gamesToImport = igdbGameService.searchGames(query).stream()
                .filter(igdbGame -> igdbGame.getId() != null)
                .filter(igdbGame -> igdbIdsToImport.add(igdbGame.getId()))
                .filter(igdbGame -> !gameRepository.existsByIgdbId(igdbGame.getId()))
                .map(this::toGame)
                .toList();

        return gameRepository.saveAll(gamesToImport);
    }

    // POST /games -> cria um jogo
    @PostMapping
    public Game createGame(@RequestBody Game game) {
        return gameRepository.save(game);
    }

    private Game toGame(IgdbGameResponse igdbGame) {
        return new Game(
                defaultText(igdbGame.getName(), NOT_INFORMED),
                getFirstGenreName(igdbGame),
                defaultText(igdbGame.getSummary(), ""),
                normalizeCoverUrl(igdbGame),
                igdbGame.getId(),
                getPlatformNames(igdbGame)
        );
    }

    private String getFirstGenreName(IgdbGameResponse igdbGame) {
        if (igdbGame.getGenres() == null) {
            return NOT_INFORMED;
        }

        return igdbGame.getGenres().stream()
                .filter(genre -> genre != null)
                .map(IgdbGameResponse.IgdbGenreResponse::getName)
                .filter(name -> name != null && !name.isBlank())
                .findFirst()
                .orElse(NOT_INFORMED);
    }

    private List<String> getPlatformNames(IgdbGameResponse igdbGame) {
        if (igdbGame.getPlatforms() == null) {
            return List.of(NOT_INFORMED);
        }

        List<String> platformNames = igdbGame.getPlatforms().stream()
                .filter(platform -> platform != null)
                .map(IgdbGameResponse.IgdbPlatformResponse::getName)
                .filter(name -> name != null && !name.isBlank())
                .toList();

        return platformNames.isEmpty() ? List.of(NOT_INFORMED) : platformNames;
    }

    private String defaultText(String value, String defaultValue) {
        return value == null || value.isBlank() ? defaultValue : value;
    }

    private String normalizeCoverUrl(IgdbGameResponse igdbGame) {
        if (igdbGame.getCover() == null || igdbGame.getCover().getUrl() == null) {
            return "";
        }

        String coverUrl = igdbGame.getCover().getUrl();
        if (coverUrl.isBlank()) {
            return "";
        }

        return coverUrl.startsWith("//") ? "https:" + coverUrl : coverUrl;
    }
}
