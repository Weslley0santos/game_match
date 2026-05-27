package com.gamematch.backend.config;

import com.gamematch.backend.model.Game;
import com.gamematch.backend.repository.GameRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class DataSeeder {

    @Bean
    CommandLineRunner initDatabase(GameRepository gameRepository) {
        return args -> {

            if (gameRepository.count() > 0) {
                return;
            }

            gameRepository.save(new Game(
                    "Minecraft",
                    "Sandbox",
                    "Explore mundos infinitos, construa e sobreviva em um mundo aberto criativo.",
                    "https://picsum.photos/400?1",
                    List.of("PC", "Console", "Mobile")
            ));

            gameRepository.save(new Game(
                    "Valorant",
                    "FPS",
                    "Jogo tático de tiro com agentes únicos e habilidades estratégicas.",
                    "https://picsum.photos/400?2",
                    List.of("PC")
            ));

            gameRepository.save(new Game(
                    "Stardew Valley",
                    "Simulation",
                    "Construa sua fazenda, faça amizades e viva uma vida relaxante no campo.",
                    "https://picsum.photos/400?3",
                    List.of("PC", "Console", "Mobile")
            ));

            gameRepository.save(new Game(
                    "The Witcher 3",
                    "RPG",
                    "Uma aventura épica em mundo aberto cheio de escolhas e monstros.",
                    "https://picsum.photos/400?4",
                    List.of("PC", "Console")
            ));

            gameRepository.save(new Game(
                    "League of Legends",
                    "MOBA",
                    "Batalhas estratégicas em equipe com campeões únicos.",
                    "https://picsum.photos/400?5",
                    List.of("PC")
            ));
        };
    }
}