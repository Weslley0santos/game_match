ALTER TABLE users ADD COLUMN username VARCHAR(32);

UPDATE users
SET username = CASE
    WHEN id < 0 THEN 'legacy_n' || replace(id::text, '-', '')
    ELSE 'legacy_' || id::text
END;

ALTER TABLE users
    ALTER COLUMN username SET NOT NULL,
    ADD CONSTRAINT ck_users_username_format
        CHECK (username ~ '^[a-z0-9_]{3,32}$'),
    ADD CONSTRAINT uk_users_username UNIQUE (username);
