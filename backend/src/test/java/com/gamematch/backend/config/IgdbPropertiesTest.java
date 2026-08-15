package com.gamematch.backend.config;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class IgdbPropertiesTest {

    @Test
    void removesWhitespaceAndMatchingQuotesFromCredentials() {
        IgdbProperties properties = new IgdbProperties();

        properties.setClientId("  \"client-id\"  ");
        properties.setClientSecret("  'client-secret'  ");

        assertThat(properties.getClientId()).isEqualTo("client-id");
        assertThat(properties.getClientSecret()).isEqualTo("client-secret");
    }
}
