package com.gamematch.backend.integration;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

class PostgresTestDatabaseGuardTest {

    @Test
    void acceptsOnlyTheDedicatedTestDatabaseUrl() {
        assertDoesNotThrow(() ->
                PostgresTestDatabaseGuard.requireTestDatabaseUrl(PostgresTestDatabaseGuard.EXPECTED_URL)
        );
    }

    @Test
    void rejectsTheDevelopmentDatabaseUrl() {
        assertThrows(IllegalStateException.class, () ->
                PostgresTestDatabaseGuard.requireTestDatabaseUrl(
                        "jdbc:postgresql://localhost:5432/game_match"
                )
        );
    }

    @Test
    void rejectsMissingOrUnexpectedDatabaseUrls() {
        assertThrows(IllegalStateException.class, () ->
                PostgresTestDatabaseGuard.requireTestDatabaseUrl(null)
        );
        assertThrows(IllegalStateException.class, () ->
                PostgresTestDatabaseGuard.requireTestDatabaseUrl(
                        "jdbc:postgresql://localhost:5432/game_match_test?currentSchema=public"
                )
        );
    }
}
