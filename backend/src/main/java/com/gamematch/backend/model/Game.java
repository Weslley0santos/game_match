package com.gamematch.backend.model;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "games")
public class Game {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private String genre;

    @Column(length = 1000)
    private String description;

    private String imageUrl;

    @ElementCollection
    @CollectionTable(name = "game_platforms", joinColumns = @JoinColumn(name = "game_id"))
    @Column(name = "platform")
    private List<String> platforms;

    public Game() {}

    public Game(String title, String genre, String description, String imageUrl, List<String> platforms) {
        this.title = title;
        this.genre = genre;
        this.description = description;
        this.imageUrl = imageUrl;
        this.platforms = platforms;
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getGenre() {
        return genre;
    }

    public String getDescription() {
        return description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public List<String> getPlatforms() {
        return platforms;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public void setPlatforms(List<String> platforms) {
        this.platforms = platforms;
    }
}