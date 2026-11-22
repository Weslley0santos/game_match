ALTER TABLE ratings
    ADD CONSTRAINT fk_ratings_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE NO ACTION,
    ADD CONSTRAINT fk_ratings_game FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE NO ACTION;
