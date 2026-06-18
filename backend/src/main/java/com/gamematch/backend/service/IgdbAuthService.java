package com.gamematch.backend.service;

import com.gamematch.backend.config.IgdbProperties;
import com.gamematch.backend.dto.IgdbAuthResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

@Service
public class IgdbAuthService {

    private static final String CLIENT_CREDENTIALS_GRANT_TYPE = "client_credentials";

    private final IgdbProperties igdbProperties;
    private final RestClient restClient;

    public IgdbAuthService(IgdbProperties igdbProperties) {
        this.igdbProperties = igdbProperties;
        this.restClient = RestClient.builder().build();
    }

    public String getAccessToken() {
        IgdbAuthResponse response = authenticate();
        return response.getAccessToken();
    }

    public IgdbAuthResponse authenticate() {
        validateRequiredProperties();

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("client_id", igdbProperties.getClientId());
        body.add("client_secret", igdbProperties.getClientSecret());
        body.add("grant_type", CLIENT_CREDENTIALS_GRANT_TYPE);

        IgdbAuthResponse response = restClient.post()
                .uri(igdbProperties.getAuth().getTokenUrl())
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(body)
                .retrieve()
                .body(IgdbAuthResponse.class);

        if (response == null || isBlank(response.getAccessToken())) {
            throw new IllegalStateException("Twitch authentication response did not include an access token.");
        }

        return response;
    }

    private void validateRequiredProperties() {
        if (isBlank(igdbProperties.getAuth().getTokenUrl())) {
            throw new IllegalStateException("IGDB token URL is not configured.");
        }

        if (isBlank(igdbProperties.getClientId())) {
            throw new IllegalStateException("IGDB client ID is not configured.");
        }

        if (isBlank(igdbProperties.getClientSecret())) {
            throw new IllegalStateException("IGDB client secret is not configured.");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
