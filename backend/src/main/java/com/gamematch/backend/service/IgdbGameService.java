package com.gamematch.backend.service;

import com.gamematch.backend.config.IgdbProperties;
import com.gamematch.backend.dto.IgdbGameResponse;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;

@Service
public class IgdbGameService {

    private static final int SEARCH_LIMIT = 20;

    private final IgdbProperties igdbProperties;
    private final IgdbAuthService igdbAuthService;
    private final RestClient restClient;

    public IgdbGameService(IgdbProperties igdbProperties, IgdbAuthService igdbAuthService) {
        this.igdbProperties = igdbProperties;
        this.igdbAuthService = igdbAuthService;
        this.restClient = RestClient.builder().build();
    }

    public List<IgdbGameResponse> searchGames(String query) {
        validateSearch(query);

        String accessToken = igdbAuthService.getAccessToken();
        List<IgdbGameResponse> games = restClient.post()
                .uri(buildGamesUrl())
                .header("Client-ID", igdbProperties.getClientId())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                .accept(MediaType.APPLICATION_JSON)
                .contentType(MediaType.TEXT_PLAIN)
                .body(buildSearchBody(query))
                .retrieve()
                .body(new ParameterizedTypeReference<>() {});

        return games == null ? List.of() : games;
    }

    private String buildGamesUrl() {
        String baseUrl = igdbProperties.getApi().getBaseUrl();
        return baseUrl.endsWith("/") ? baseUrl + "games" : baseUrl + "/games";
    }

    private String buildSearchBody(String query) {
        String escapedQuery = query.trim()
                .replace("\\", "\\\\")
                .replace("\"", "\\\"");

        return """
                search "%s";
                fields id,name,summary,cover.url,genres.name,platforms.name;
                limit %d;
                """.formatted(escapedQuery, SEARCH_LIMIT);
    }

    private void validateSearch(String query) {
        if (isBlank(igdbProperties.getApi().getBaseUrl())) {
            throw new IllegalStateException("IGDB base URL is not configured.");
        }

        if (isBlank(igdbProperties.getClientId())) {
            throw new IllegalStateException("IGDB client ID is not configured.");
        }

        if (isBlank(query)) {
            throw new IllegalArgumentException("Search query must not be blank.");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
