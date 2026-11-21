-- Additive session revocation counter; run after migration 001.
ALTER TABLE users ADD COLUMN auth_version INT UNSIGNED NOT NULL DEFAULT 1;
