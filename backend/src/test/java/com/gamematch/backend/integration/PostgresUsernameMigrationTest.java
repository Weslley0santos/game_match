package com.gamematch.backend.integration;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ContextConfiguration;

import javax.sql.DataSource;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

@SpringBootTest
@ContextConfiguration(initializers = PostgresTestDatabaseGuard.class)
class PostgresUsernameMigrationTest {

    @Autowired private DataSource dataSource;
    @Autowired private JdbcTemplate jdbc;

    private String schema;

    @BeforeEach
    void createDisposableV3Schema() {
        assertThat(jdbc.queryForObject("SELECT current_database()", String.class))
                .isEqualTo("game_match_test");
        schema = "username_migration_" + UUID.randomUUID().toString().replace("-", "");
        migrateTo("3");
        insertLegacyRows();
    }

    @AfterEach
    void dropOnlyDisposableSchema() {
        if (schema != null) {
            jdbc.execute("DROP SCHEMA IF EXISTS " + schema + " CASCADE");
        }
    }

    @Test
    void upgradesPopulatedV3AndPreservesLegacyIdentityCredentialsAndRelationships() {
        migrateTo("4");

        assertThat(appliedVersions()).containsExactly("1", "2", "3", "4");
        assertThat(jdbc.query("SELECT id, username, name, email, password, role FROM " + schema
                        + ".users ORDER BY id", (row, index) -> List.<Object>of(
                        row.getLong("id"), row.getString("username"), row.getString("name"),
                        row.getString("email"), row.getString("password"), row.getString("role"))))
                .containsExactly(
                        List.of(-42L, "legacy_n42", "Legacy negative", "negative@example.test", "hash-negative", "ADMIN"),
                        List.of(41L, "legacy_41", "Legacy positive", "positive@example.test", "hash-positive", "USER"));
        assertThat(jdbc.query("SELECT user_id, friend_id FROM " + schema + ".friendship",
                (row, index) -> List.of(row.getLong(1), row.getLong(2))))
                .containsExactly(List.of(41L, -42L));
        assertThat(jdbc.query("SELECT sender_id, receiver_id, game_id FROM " + schema + ".play_invites",
                (row, index) -> List.of(row.getLong(1), row.getLong(2), row.getLong(3))))
                .containsExactly(List.of(41L, -42L, 9L));
        assertThat(jdbc.query("SELECT user_id, game_id, type FROM " + schema + ".ratings",
                (row, index) -> List.<Object>of(row.getLong(1), row.getLong(2), row.getString(3))))
                .containsExactly(List.of(41L, 9L, "FAVORITE"));
    }

    @Test
    void v4EnforcesUsernameFormatNullabilityAndUniquenessInPostgres() {
        migrateTo("4");

        assertThrows(DataAccessException.class, () -> jdbc.update(
                "UPDATE " + schema + ".users SET username = ? WHERE id = ?", "BAD-NAME", 41L));
        assertThrows(DataAccessException.class, () -> jdbc.update(
                "UPDATE " + schema + ".users SET username = ? WHERE id = ?", "UPPERCASE", 41L));
        assertThrows(DataAccessException.class, () -> jdbc.update(
                "UPDATE " + schema + ".users SET username = ? WHERE id = ?", "a".repeat(33), 41L));
        assertThrows(DataAccessException.class, () -> jdbc.update(
                "UPDATE " + schema + ".users SET username = NULL WHERE id = ?", 41L));
        assertThrows(DataAccessException.class, () -> jdbc.update(
                "UPDATE " + schema + ".users SET username = ? WHERE id = ?", "legacy_n42", 41L));
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

    private void insertLegacyRows() {
        jdbc.update("INSERT INTO " + schema + ".users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)",
                41L, "Legacy positive", "positive@example.test", "hash-positive", "USER");
        jdbc.update("INSERT INTO " + schema + ".users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)",
                -42L, "Legacy negative", "negative@example.test", "hash-negative", "ADMIN");
        jdbc.update("INSERT INTO " + schema + ".games (id, title) VALUES (?, ?)", 9L, "Legacy game");
        jdbc.update("INSERT INTO " + schema + ".friendship (user_id, friend_id, status) VALUES (?, ?, ?)",
                41L, -42L, "ACCEPTED");
        jdbc.update("INSERT INTO " + schema + ".play_invites (sender_id, receiver_id, game_id, status) VALUES (?, ?, ?, ?)",
                41L, -42L, 9L, "PENDING");
        jdbc.update("INSERT INTO " + schema + ".ratings (user_id, game_id, type) VALUES (?, ?, ?)",
                41L, 9L, "FAVORITE");
    }
}
