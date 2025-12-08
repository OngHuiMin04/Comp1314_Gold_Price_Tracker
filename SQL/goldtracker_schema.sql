-- ===========================================
-- DATABASE
-- ===========================================
CREATE DATABASE IF NOT EXISTS goldtracker;
USE goldtracker;

-- ===========================================
-- TABLE 1: currencies
-- ===========================================
CREATE TABLE IF NOT EXISTS currencies (
    currencies_id INT AUTO_INCREMENT PRIMARY KEY,
    currency_name VARCHAR(20) NOT NULL UNIQUE,
    currency_exchange DECIMAL(18,8)  -- ctousd
);

-- ===========================================
-- TABLE 2: gold_prices
-- ===========================================
CREATE TABLE IF NOT EXISTS gold_prices (
    gold_prices_id INT AUTO_INCREMENT PRIMARY KEY,
    currency_id INT NOT NULL,

    bid_price DECIMAL(10,2),
    ask_price DECIMAL(10,2),
    high_price DECIMAL(10,2),
    low_price DECIMAL(10,2),

    FOREIGN KEY (currency_id) REFERENCES currencies(currencies_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ===========================================
-- TABLE 3: unit_prices
-- ===========================================
CREATE TABLE IF NOT EXISTS unit_prices (
    unit_price_id INT AUTO_INCREMENT PRIMARY KEY,
    gold_price_id INT NOT NULL,

    unit_ounce DECIMAL(12,2),
    unit_gram DECIMAL(12,2),
    unit_kilo DECIMAL(14,2),
    unit_pennyweight DECIMAL(12,2),
    unit_tola DECIMAL(12,2),
    unit_tael DECIMAL(12,2),

    FOREIGN KEY (gold_price_id) REFERENCES gold_prices(gold_prices_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ===========================================
-- TABLE 4: logs
-- ===========================================
CREATE TABLE IF NOT EXISTS logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,

    currency_id INT NOT NULL,
    gold_price_id INT NOT NULL,

    message VARCHAR(255),
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (currency_id) REFERENCES currencies(currencies_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    FOREIGN KEY (gold_price_id) REFERENCES gold_prices(gold_prices_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
