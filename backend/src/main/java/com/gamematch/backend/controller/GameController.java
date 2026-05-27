package com.gamematch.backend.controller;

import com.gamematch.backend.model.Game;
import com.gamematch.backend.repository.GameRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/games")
public class GameController {

    private final GameRepository gameRepository;

    public GameController(GameRepository gameRepository) {
        this.gameRepository = gameRepository;
    }

    // GET /games -> lista todos os jogos
    @GetMapping
    public List<Game> getAllGames() {
        return gameRepository.findAll();
    }

    // POST /games -> cria um jogo
    @PostMapping
    public Game createGame(@RequestBody Game game) {
        return gameRepository.save(game);
    }
}