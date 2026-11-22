package com.gamematch.backend.integration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.FlywayException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ContextConfiguration;

import javax.sql.DataSource;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@ContextConfiguration(initializers = PostgresTestDatabaseGuard.class)
class PostgresRatingMigrationTest {

    @Autowired private DataSource dataSource;
    @Autowired private JdbcTemplate jdbc;

    private String schema;

    @BeforeEach
    void selectIsolatedSchema() {
        assertThat(jdbc.queryForObject("SELECT current_database()", String.class)).isEqualTo("game_match_test");
        schema = "ratings_migration_" + UUID.randomUUID().toString().replace("-", "");
    }

    @AfterEach
    void removeOnlyThisTestsSchema() {
        if (schema != null) {
            jdbc.execute("DROP SCHEMA IF EXISTS " + schema + " CASCADE");
        }
    }

    @Test
    void installsValidatedForeignKeysInAnEmptySchema() {
        migrateTo("3");

        assertThat(appliedVersions()).containsExactly("1", "2", "3");
        assertValidatedRatingForeignKeys();
    }

    @Test
    void upgradesV2WithoutLosingValidOrNullableRatings() {
        migrateTo("2");
        createReferences();
        jdbc.update("INSERT INTO " + schema + ".ratings (user_id, game_id, type) VALUES (1, 1, 'LIKE'), (NULL, 1, 'FAVORITE')");
        var before = loadRatings();

        migrateTo("3");

        assertThat(appliedVersions()).containsExactly("1", "2", "3");
        assertValidatedRatingForeignKeys();
        assertThat(loadRatings()).isEqualTo(before);
    }

    @Test
    void rollsBackV3WhenV2ContainsAnOrphanAndCanRetryAfterRepair() {
        migrateTo("2");
        createReferences();
        jdbc.update("INSERT INTO " + schema + ".ratings (user_id, game_id, type) VALUES (1, 1, 'LIKE'), (1, 99, 'DISLIKE')");
        var before = loadRatings();

        assertThatThrownBy(() -> migrateTo("3"))
                .isInstanceOf(FlywayException.class)
                .hasMessageContaining("fk_ratings_game");

        assertThat(appliedVersions()).containsExactly("1", "2");
        assertThat(ratingForeignKeys()).isEmpty();
        assertThat(loadRatings()).isEqualTo(before);

        jdbc.update("INSERT INTO " + schema + ".games (id, title) VALUES (99, 'Recovered test game')");
        migrateTo("3");

        assertThat(appliedVersions()).containsExactly("1", "2", "3");
        assertValidatedRatingForeignKeys();
        assertThat(loadRatings()).isEqualTo(before);
    }

    private void migrateTo(String version) {
        Flyway.configure().dataSource(dataSource)
                .defaultSchema(schema)
                .locations("classpath:db/migration")
                .target(version)
                .load()
                .migrate();
    }

    private List<String> appliedVersions() {
        return jdbc.queryForList("SELECT version FROM " + schema + ".flyway_schema_history "
                + "WHERE version IS NOT NULL AND success ORDER BY installed_rank", String.class);
    }

    private void createReferences() {
        jdbc.update("INSERT INTO " + schema + ".users (id, email) VALUES (1, 'migration@example.test')");
        jdbc.update("INSERT INTO " + schema + ".games (id, title) VALUES (1, 'Test game')");
    }

    private List<RatingRow> loadRatings() {
        return jdbc.query("SELECT id, user_id, game_id, type FROM " + schema + ".ratings ORDER BY id",
                (row, index) -> new RatingRow(row.getLong("id"), row.getObject("user_id", Long.class),
                        row.getLong("game_id"), row.getString("type")));
    }

    private List<String> ratingForeignKeys() {
        return jdbc.queryForList("""
                SELECT conname || ':' || convalidated::text
                FROM pg_constraint
                WHERE conrelid = to_regclass(?) AND contype = 'f'
                """, String.class, schema + ".ratings");
    }

    private void assertValidatedRatingForeignKeys() {
        assertThat(ratingForeignKeys()).containsExactlyInAnyOrder("fk_ratings_game:true", "fk_ratings_user:true");
    }

    private record RatingRow(long id, Long userId, long gameId, String type) {
    }
}
