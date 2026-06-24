package com.gamematch.backend.service;

import com.gamematch.backend.config.IgdbProperties;
import com.gamematch.backend.dto.IgdbGameResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;

@Service
public class IgdbGameService {

    private static final Logger logger = LoggerFactory.getLogger(IgdbGameService.class);
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

        return searchGames(query, false);
    }

    public List<IgdbGameResponse> searchMainGames(String query) {
        validateSearch(query);

        return searchGames(query, true);
    }

    private List<IgdbGameResponse> searchGames(String query, boolean onlyMainGames) {
        String accessToken = igdbAuthService.getAccessToken();
        String searchBody = buildSearchBody(query, onlyMainGames);

        logger.info(
                "IGDB search credentials configured: clientId={}, clientSecret={}",
                !isBlank(igdbProperties.getClientId()),
                !isBlank(igdbProperties.getClientSecret())
        );
        logger.info("IGDB search request body: {}", searchBody.replace(System.lineSeparator(), " "));

        List<IgdbGameResponse> games = restClient.post()
                .uri(buildGamesUrl())
                .header("Client-ID", igdbProperties.getClientId())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                .accept(MediaType.APPLICATION_JSON)
                .contentType(MediaType.TEXT_PLAIN)
                .body(searchBody)
                .retrieve()
                .body(new ParameterizedTypeReference<>() {});

        List<IgdbGameResponse> safeGames = games == null ? List.of() : games;
        logger.info("IGDB search returned {} games.", safeGames.size());

        return safeGames;
    }

    private String buildGamesUrl() {
        String baseUrl = igdbProperties.getApi().getBaseUrl();
        return baseUrl.endsWith("/") ? baseUrl + "games" : baseUrl + "/games";
    }

    private String buildSearchBody(String query, boolean onlyMainGames) {
        String escapedQuery = query.trim()
                .replace("\\", "\\\\")
                .replace("\"", "\\\"");

        if (onlyMainGames) {
            return """
                    search "%s";
                    fields id,name,summary,cover.url,genres.name,platforms.name,category,parent_game,version_parent;
                    limit %d;
                    """.formatted(escapedQuery, SEARCH_LIMIT);
        }

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
