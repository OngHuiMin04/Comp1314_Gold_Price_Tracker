CREATE DATABASE IF NOT EXISTS goldtracker;
USE goldtracker;

-- =============================
-- CURRENCIES TABLE
-- (Create this first!)
-- =============================
CREATE TABLE IF NOT EXISTS currencies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    ctousd DECIMAL(18,8)
);


-- =============================
-- GOLD PRICES TABLE
-- =============================
CREATE TABLE IF NOT EXISTS gold_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    currency_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    bid_price DECIMAL(10,2),
    ask_price DECIMAL(10,2),
    high_price DECIMAL(10,2),
    low_price DECIMAL(10,2),

    FOREIGN KEY (currency_id) REFERENCES currencies(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =============================
-- UNIT PRICES TABLE
-- =============================
CREATE TABLE IF NOT EXISTS unit_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gold_price_id INT NOT NULL,
    unit_ounce DECIMAL(12,2),
    unit_gram DECIMAL(12,2),
    unit_kilo DECIMAL(14,2),
    unit_pennyweight DECIMAL(12,2),
    unit_tola DECIMAL(12,2),
    unit_tael DECIMAL(12,2),

    FOREIGN KEY (gold_price_id) REFERENCES gold_prices(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
