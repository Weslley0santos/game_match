package com.gamematch.backend.integration;

import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;

/** Fails before Spring creates the datasource or Flyway can change a database. */
public final class PostgresTestDatabaseGuard
        implements ApplicationContextInitializer<ConfigurableApplicationContext> {

    public static final String EXPECTED_URL = "jdbc:postgresql://localhost:5432/game_match_test";

    @Override
    public void initialize(ConfigurableApplicationContext applicationContext) {
        requireTestDatabaseUrl(applicationContext.getEnvironment().getProperty("spring.datasource.url"));
    }

    static void requireTestDatabaseUrl(String url) {
        if (!EXPECTED_URL.equals(url)) {
            throw new IllegalStateException(
                    "PostgreSQL integration tests require " + EXPECTED_URL
                            + "; refusing to initialize Spring or Flyway with the configured URL."
            );
        }
    }
}
