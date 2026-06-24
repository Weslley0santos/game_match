package com.gamematch.backend.controller;

import com.gamematch.backend.dto.IgdbGameResponse;
import com.gamematch.backend.model.Game;
import com.gamematch.backend.repository.GameRepository;
import com.gamematch.backend.service.IgdbGameService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashSet;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@RestController
@RequestMapping("/games")
public class GameController {

    private static final Logger logger = LoggerFactory.getLogger(GameController.class);
    private static final String NOT_INFORMED = "N\u00e3o informado";
    private static final List<String> EXTRA_CONTENT_TERMS = List.of(
            "dlc",
            "expansion",
            "add-on",
            "addon",
            "pack",
            "skin",
            "bundle",
            "season pass",
            "soundtrack",
            "upgrade",
            "expansion",
            "update",
            "bonus",
            "demo",
            "trailer",
            "wallpaper",
            "theme",
            "avatar",
            "costume",
            "outfit",
            "map",
            "mash-up",
            "mashup"
    );

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

        List<IgdbGameResponse> igdbGames = igdbGameService.searchMainGames(query);
        logger.info("IGDB import query '{}' returned {} games before filters.", query, igdbGames.size());

        List<IgdbGameResponse> gamesWithId = igdbGames.stream()
                .filter(igdbGame -> igdbGame.getId() != null)
                .toList();
        logger.info("IGDB import query '{}' has {} games after removing missing IGDB ids.", query, gamesWithId.size());

        List<IgdbGameResponse> gamesAfterNameFilter = gamesWithId.stream()
                .filter(this::isMainGameByName)
                .toList();
        logger.info(
                "IGDB import query '{}' has {} games after anti-extra-content filters. Removed by name filter: {}.",
                query,
                gamesAfterNameFilter.size(),
                gamesWithId.size() - gamesAfterNameFilter.size()
        );

        Set<Long> igdbIdsToImport = new HashSet<>();
        List<IgdbGameResponse> uniqueIgdbGames = gamesAfterNameFilter.stream()
                .filter(igdbGame -> igdbIdsToImport.add(igdbGame.getId()))
                .toList();
        logger.info(
                "IGDB import query '{}' has {} unique IGDB games. Removed duplicated IGDB ids from response: {}.",
                query,
                uniqueIgdbGames.size(),
                gamesAfterNameFilter.size() - uniqueIgdbGames.size()
        );

        List<Game> gamesToImport = uniqueIgdbGames.stream()
                .filter(igdbGame -> !gameRepository.existsByIgdbId(igdbGame.getId()))
                .map(this::toGame)
                .toList();
        logger.info(
                "IGDB import query '{}' has {} games ready to save. Ignored because already exists in database: {}.",
                query,
                gamesToImport.size(),
                uniqueIgdbGames.size() - gamesToImport.size()
        );

        List<Game> savedGames = gameRepository.saveAll(gamesToImport);
        logger.info("IGDB import query '{}' saved {} games.", query, savedGames.size());

        return savedGames;
    }

    // POST /games/igdb/import-one?query=termo -> busca jogos na IGDB e salva apenas um resultado
    @PostMapping("/igdb/import-one")
    public Game importOneIgdbGame(@RequestParam(required = false) String query) {
        if (query == null || query.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Query must not be blank.");
        }

        List<IgdbGameResponse> igdbGames = igdbGameService.searchMainGames(query);
        logger.info("IGDB import-one query '{}' returned {} games before filters.", query, igdbGames.size());

        List<IgdbGameResponse> validGames = igdbGames.stream()
                .filter(igdbGame -> igdbGame.getId() != null)
                .filter(this::isMainGameByName)
                .toList();
        logger.info("IGDB import-one query '{}' has {} games after anti-extra-content filters.", query, validGames.size());

        IgdbGameResponse selectedGame = validGames.stream()
                .min(Comparator.comparingInt(igdbGame -> getNameMatchScore(query, igdbGame.getName())))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No valid IGDB game found for query."));

        logger.info(
                "IGDB import-one query '{}' selected game '{}' with IGDB id {}.",
                query,
                selectedGame.getName(),
                selectedGame.getId()
        );

        Optional<Game> existingGame = gameRepository.findByIgdbId(selectedGame.getId());
        if (existingGame.isPresent()) {
            logger.info("IGDB import-one query '{}' returned existing game with id {}.", query, existingGame.get().getId());
            return existingGame.get();
        }

        Game savedGame = gameRepository.save(toGame(selectedGame));
        logger.info("IGDB import-one query '{}' saved game with id {}.", query, savedGame.getId());

        return savedGame;
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

    private boolean isMainGameByName(IgdbGameResponse igdbGame) {
        String name = igdbGame.getName();
        if (name == null || name.isBlank()) {
            return false;
        }

        String normalizedName = name.toLowerCase();
        return EXTRA_CONTENT_TERMS.stream()
                .noneMatch(normalizedName::contains);
    }

    private int getNameMatchScore(String query, String gameName) {
        String normalizedQuery = normalizeNameForMatch(query);
        String normalizedGameName = normalizeNameForMatch(gameName);

        if (normalizedGameName.equals(normalizedQuery)) {
            return 0;
        }

        if (normalizedGameName.startsWith(normalizedQuery)) {
            return 1;
        }

        if (normalizedGameName.contains(normalizedQuery)) {
            return 2;
        }

        if (normalizedQuery.contains(normalizedGameName)) {
            return 3;
        }

        return 4;
    }

    private String normalizeNameForMatch(String value) {
        if (value == null) {
            return "";
        }

        return value.toLowerCase()
                .replaceAll("[^a-z0-9]+", " ")
                .trim();
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
