-- Day6 only: reset the two teaching accounts in a separate schema.
-- Finish transactions in BOTH existing sessions before running this file again.
CREATE DATABASE IF NOT EXISTS infra_transaction_lab;
USE infra_transaction_lab;

CREATE TABLE IF NOT EXISTS accounts (
    id INT PRIMARY KEY,
    balance INT NOT NULL,
    CONSTRAINT nonnegative_balance CHECK (balance >= 0)
) ENGINE = InnoDB;

START TRANSACTION;
INSERT INTO accounts (id, balance) VALUES (1, 1000), (2, 1000)
ON DUPLICATE KEY UPDATE balance = 1000;
COMMIT;

SELECT id, balance FROM accounts ORDER BY id;
