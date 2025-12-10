#!/bin/bash
# ALWAYS switch to Script folder (IMPORTANT for cron)
cd /mnt/c/Users/Amanda\ Ong/Documents/Github/Comp1314_Gold_Price_Tracker/Script

# =======================================================
# GOLD TRACKER (MySQL INSERT)
# =======================================================

set -eo pipefail

DB="goldtracker"
DB_USER="root"

# =======================================================
# SAFE ARGUMENT HANDLING
# =======================================================
currency="${1:-USD}"
timestamp_ny="${2:-2000-01-01 00:00:00}"
timestamp_my="${3:-2000-01-01 00:00:00}"
ctousd="${4:-1}"

bid_price="${5:-0}"
ask_price="${6:-0}"
high_price="${7:-0}"
low_price="${8:-0}"

unit_ounce="${9:-0}"
unit_gram="${10:-0}"
unit_kilo="${11:-0}"
unit_pennyweight="${12:-0}"
unit_tola="${13:-0}"
unit_tael="${14:-0}"

mysql_cmd=(mysql -u "$DB_USER" -D "$DB")

# =======================================================
# BLOCK BAD INSERTS
# =======================================================
if [ "$bid_price" = "0" ] || [ "$ask_price" = "0" ]; then
    echo "SKIPPED INSERT — Invalid (0) price for $currency" >> ./log/scrapper.log
    exit 0
fi

if [ "$timestamp_ny" = "2000-01-01 00:00:00" ]; then
    echo "SKIPPED INSERT — Missing timestamp for $currency" >> ./log/scrapper.log
    exit 0
fi

# =======================================================
# 1. INSERT OR UPDATE CURRENCY
# =======================================================
"${mysql_cmd[@]}" -e "
INSERT INTO currencies (currency_name, currency_exchange)
VALUES ('$currency', $ctousd)
ON DUPLICATE KEY UPDATE currency_exchange = VALUES(currency_exchange);
"

currency_id=$("${mysql_cmd[@]}" -N -e "
SELECT currencies_id FROM currencies WHERE currency_name='$currency';
")

# =======================================================
# 2. INSERT INTO gold_prices
# =======================================================
gold_price_id=$("${mysql_cmd[@]}" -N -e "
INSERT INTO gold_prices (
    currency_id,
    price_timestamp_ny,
    script_timestamp_my,
    bid_price, ask_price, high_price, low_price
) VALUES (
    $currency_id,
    '$timestamp_ny',
    '$timestamp_my',
    $bid_price, $ask_price, $high_price, $low_price
);

SELECT LAST_INSERT_ID();
")

# =======================================================
# 3. INSERT INTO unit_prices
# =======================================================
"${mysql_cmd[@]}" -e "
INSERT INTO unit_prices (
    gold_price_id,
    unit_ounce, unit_gram, unit_kilo,
    unit_pennyweight, unit_tola, unit_tael
) VALUES (
    $gold_price_id,
    $unit_ounce, $unit_gram, $unit_kilo,
    $unit_pennyweight, $unit_tola, $unit_tael
);
"

# =======================================================
# 4. INSERT INTO LOGS
# =======================================================
"${mysql_cmd[@]}" -e "
INSERT INTO logs (currency_id, gold_price_id, message)
VALUES ($currency_id, $gold_price_id, 'Inserted by tracker');
"

# =======================================================
# FINAL SCRAPER MESSAGE
# =======================================================
echo "Scrapper completed successfully → $currency | NY=$timestamp_ny | MY=$timestamp_my" >> ./log/scrapper.log
