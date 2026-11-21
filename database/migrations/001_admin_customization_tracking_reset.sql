-- FurniFlex additive feature migration. Run once against furniflex_db; it preserves all existing rows.
ALTER TABLE products
  ADD COLUMN default_width_cm DECIMAL(8,2) NOT NULL DEFAULT 100,
  ADD COLUMN default_height_cm DECIMAL(8,2) NOT NULL DEFAULT 100,
  ADD COLUMN default_depth_cm DECIMAL(8,2) NOT NULL DEFAULT 100,
  ADD COLUMN width_rate_per_cm DECIMAL(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN height_rate_per_cm DECIMAL(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN depth_rate_per_cm DECIMAL(10,2) NOT NULL DEFAULT 0;

CREATE TABLE password_reset_tokens (
  reset_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX(user_id, expires_at),
  CONSTRAINT fk_reset_user FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;
