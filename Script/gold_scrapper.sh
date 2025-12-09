#!/bin/bash
# =======================================================
# FINAL SCRAPPER (Matches your schema exactly)
# =======================================================

set -euo pipefail

DB="goldtracker"
DB_USER="root"

currency="$1"
timestamp_ny="$2"     # Kitco data time (NY)
timestamp_my="$3"     # Script time (Malaysia)
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

echo "DEBUG inserting $currency | NY=$timestamp_ny | MY=$timestamp_my"
echo "DEBUG inserting $currency with ctousd=$ctousd"

# =======================================================
# 1. CURRENCIES INSERT
# =======================================================
"${mysql_cmd[@]}" -e "
INSERT INTO currencies (currency_name, currency_exchange)
VALUES ('$currency', $ctousd)
ON DUPLICATE KEY UPDATE currency_exchange = VALUES(currency_exchange);
"

currency_id=$("${mysql_cmd[@]}" -N -e "
SELECT currencies_id FROM currencies WHERE currency_name='$currency';
")

if [[ -z "$currency_id" ]]; then
    echo "ERROR: currency_id missing"
    exit 1
fi

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

if [[ -z "$gold_price_id" || "$gold_price_id" -eq 0 ]]; then
    echo \"ERROR: gold_price_id invalid!\"
    exit 1
fi

# =======================================================
# 3. INSERT INTO unit_prices
# =======================================================
unit_sql="
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

echo "DEBUG unit_prices SQL:"
echo "$unit_sql"

if ! "${mysql_cmd[@]}" -e "$unit_sql"; then
    echo "ERROR: unit_prices insert failed"
    exit 1
fi

# =======================================================
# 4. INSERT LOG
# =======================================================
"${mysql_cmd[@]}" -e "
INSERT INTO logs (currency_id, gold_price_id, message)
VALUES ($currency_id, $gold_price_id, 'Inserted by tracker');
"

echo "✔ SUCCESS: $currency inserted (gold_price_id=$gold_price_id)"