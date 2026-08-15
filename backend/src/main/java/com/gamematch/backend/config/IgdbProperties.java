package com.gamematch.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "igdb")
public class IgdbProperties {

    private final Api api = new Api();
    private final Auth auth = new Auth();
    private String clientId;
    private String clientSecret;

    public Api getApi() {
        return api;
    }

    public Auth getAuth() {
        return auth;
    }

    public String getClientId() {
        return clientId;
    }

    public void setClientId(String clientId) {
        this.clientId = normalizeCredential(clientId);
    }

    public String getClientSecret() {
        return clientSecret;
    }

    public void setClientSecret(String clientSecret) {
        this.clientSecret = normalizeCredential(clientSecret);
    }

    private String normalizeCredential(String value) {
        if (value == null) {
            return null;
        }

        String normalizedValue = value.trim();
        if (normalizedValue.length() >= 2) {
            char firstCharacter = normalizedValue.charAt(0);
            char lastCharacter = normalizedValue.charAt(normalizedValue.length() - 1);
            boolean hasMatchingQuotes = (firstCharacter == '"' && lastCharacter == '"')
                    || (firstCharacter == '\'' && lastCharacter == '\'');

            if (hasMatchingQuotes) {
                normalizedValue = normalizedValue.substring(1, normalizedValue.length() - 1).trim();
            }
        }

        return normalizedValue;
    }

    public static class Api {
        private String baseUrl;

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }
    }

    public static class Auth {
        private String tokenUrl;

        public String getTokenUrl() {
            return tokenUrl;
        }

        public void setTokenUrl(String tokenUrl) {
            this.tokenUrl = tokenUrl;
        }
    }
}
