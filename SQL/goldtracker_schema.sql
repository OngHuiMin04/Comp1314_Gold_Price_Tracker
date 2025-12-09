DROP DATABASE IF EXISTS goldtracker;
CREATE DATABASE goldtracker;
USE goldtracker;

-- ================================
-- CURRENCIES
-- ================================
CREATE TABLE currencies (
    currencies_id INT AUTO_INCREMENT PRIMARY KEY,
    currency_name VARCHAR(20) NOT NULL UNIQUE,
    currency_exchange DECIMAL(20,10) NULL
);

-- ================================
-- GOLD PRICES
-- ================================
CREATE TABLE gold_prices (
    gold_prices_id INT AUTO_INCREMENT PRIMARY KEY,
    currency_id INT NOT NULL,
    price_timestamp_ny DATETIME NOT NULL,
    script_timestamp_my DATETIME NOT NULL,
    bid_price DECIMAL(20,4),
    ask_price DECIMAL(20,4),
    high_price DECIMAL(20,4),
    low_price DECIMAL(20,4),
    FOREIGN KEY (currency_id) REFERENCES currencies(currencies_id)
);

-- ================================
-- UNIT PRICES
-- ================================
CREATE TABLE unit_prices (
    unit_prices_id INT AUTO_INCREMENT PRIMARY KEY,
    gold_price_id INT NOT NULL,
    unit_ounce DECIMAL(20,4),
    unit_gram DECIMAL(20,4),
    unit_kilo DECIMAL(20,4),
    unit_pennyweight DECIMAL(20,4),
    unit_tola DECIMAL(20,4),
    unit_tael DECIMAL(20,4),
    FOREIGN KEY (gold_price_id) REFERENCES gold_prices(gold_prices_id)
);

-- ================================
-- LOGS
-- ================================
CREATE TABLE logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    currency_id INT NULL,
    gold_price_id INT NULL,
    message VARCHAR(255),
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (currency_id)
        REFERENCES currencies(currencies_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    FOREIGN KEY (gold_price_id)
        REFERENCES gold_prices(gold_prices_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);
