package com.gamematch.backend.dto;

import java.util.List;

public class IgdbGameResponse {

    private Long id;
    private String name;
    private String summary;
    private IgdbCoverResponse cover;
    private List<IgdbGenreResponse> genres;
    private List<IgdbPlatformResponse> platforms;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public IgdbCoverResponse getCover() {
        return cover;
    }

    public void setCover(IgdbCoverResponse cover) {
        this.cover = cover;
    }

    public List<IgdbGenreResponse> getGenres() {
        return genres;
    }

    public void setGenres(List<IgdbGenreResponse> genres) {
        this.genres = genres;
    }

    public List<IgdbPlatformResponse> getPlatforms() {
        return platforms;
    }

    public void setPlatforms(List<IgdbPlatformResponse> platforms) {
        this.platforms = platforms;
    }

    public static class IgdbCoverResponse {
        private String url;

        public String getUrl() {
            return url;
        }

        public void setUrl(String url) {
            this.url = url;
        }
    }

    public static class IgdbGenreResponse {
        private String name;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }

    public static class IgdbPlatformResponse {
        private String name;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }
}
