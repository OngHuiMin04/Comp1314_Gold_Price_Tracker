#!/bin/bash
# ============================
# GOLD PRICE TRACKER (RAW HTML)
# ============================

PAGE="https://www.kitco.com/charts/gold"
RAW_FILE="raw.html"
CURRENCIES=("USD" "EUR" "GBP" "AUD" "CNY")
DATA_DIR="./gold_data"
LOG_FILE="$DATA_DIR/gold_tracker.log"

mkdir -p "$DATA_DIR"

# ----------------------------
# Logging function
# ----------------------------
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# ----------------------------
# Display output
# ----------------------------
display_currency_data() {
    local currency=$1
    local timestamp=$2
    local ctousd=$3
    local bid_price=$4
    local ask_price=$5
    local high_price=$6
    local low_price=$7
    local unit_ounce=$8
    local unit_gram=$9
    local unit_kilo=${10}
    local unit_pennyweight=${11}
    local unit_tola=${12}
    local unit_tael=${13}

    echo "=========================================="
    echo " GOLD PRICE - $currency"
    echo "=========================================="
    printf "%-18s : %s\n" "Bid Price"   "$bid_price"
    printf "%-18s : %s\n" "Ask Price"   "$ask_price"
    printf "%-18s : %s\n" "High Price"  "$high_price"
    printf "%-18s : %s\n" "Low Price"   "$low_price"

    echo "--- Price Per Unit ---"
    printf "%-18s : %s\n" "Ounce"       "$unit_ounce"
    printf "%-18s : %s\n" "Gram"        "$unit_gram"
    printf "%-18s : %s\n" "Kilo"        "$unit_kilo"
    printf "%-18s : %s\n" "Pennyweight" "$unit_pennyweight"
    printf "%-18s : %s\n" "Tola"        "$unit_tola"
    printf "%-18s : %s\n" "Tael"        "$unit_tael"

    printf "%-18s : %s\n" "Data Time"   "$timestamp"
    printf "%-18s : %s\n" "Script Run"  "$(TZ="Asia/Kuala_Lumpur" date '+%Y-%m-%d %H:%M:%S')"
    echo "------------------------------------------"
}

# ----------------------------
# Save CSV
# ----------------------------
save_to_file() {
    local currency=$1
    local timestamp=$2
    local ctousd=$3
    local bid_price=$4
    local ask_price=$5
    local high_price=$6
    local low_price=$7
    local unit_ounce=$8
    local unit_gram=$9
    local unit_kilo=${10}
    local unit_pennyweight=${11}
    local unit_tola=${12}
    local unit_tael=${13}

    local file="$DATA_DIR/${currency}_gold_prices.csv"

    if [ ! -f "$file" ]; then
        echo "timestamp,currency,usdtoc_rate,bid_price,ask_price,high_price,low_price,unit_ounce,unit_gram,unit_kilo,unit_pennyweight,unit_tola,unit_tael,script_run_time" > "$file"
    fi

    echo "$timestamp,$currency,$ctousd,$bid_price,$ask_price,$high_price,$low_price,$unit_ounce,$unit_gram,$unit_kilo,$unit_pennyweight,$unit_tola,$unit_tael,$(TZ=Asia/Kuala_Lumpur date '+%Y-%m-%d %H:%M:%S')" >> "$file"
}

# ----------------------------
# Start Script
# ----------------------------
log_message "Starting gold tracker..."

# CHECK 1: Internet
if ! curl -s --head https://www.google.com/ > /dev/null; then
    log_message "ERROR: No internet connection."
    exit 1
fi

# CHECK 2: Kitco reachable
if ! curl -s -H "User-Agent: Mozilla/5.0" "$PAGE" -o "$RAW_FILE"; then
    log_message "ERROR: Unable to reach Kitco."
    exit 1
fi

# ----------------------------
# Extract BID & ASK
# ----------------------------
bid_usd=$(grep -oP '<h3[^>]*>\K[0-9,]+\.[0-9]+' "$RAW_FILE" | head -1 | tr -d ',')
ask_usd=$(grep -oP 'text-\[19px\] font-normal">\K[0-9,]+\.[0-9]+' "$RAW_FILE" | head -1 | tr -d ',')

if [ -z "$bid_usd" ] || [ -z "$ask_usd" ]; then
    log_message "ERROR: Failed to parse gold data — HTML structure changed."
    exit 1
fi

bid_usd=$(printf "%.2f" "$bid_usd")
ask_usd=$(printf "%.2f" "$ask_usd")

# Extract HIGH & LOW
low_usd=$(grep -oP 'CommodityPrice_priceToday__wBwVD"><div>\K[0-9,]+\.[0-9]+' "$RAW_FILE" | head -1 | tr -d ',')
high_usd=$(grep -oP 'CommodityPrice_priceToday__wBwVD"><div>[0-9,]+\.[0-9]+</div><div>\K[0-9,]+\.[0-9]+' "$RAW_FILE" | head -1 | tr -d ',')

low_usd=$(printf "%.2f" "$low_usd")
high_usd=$(printf "%.2f" "$high_usd")

# ----------------------------
# Extract Unit Prices
# ----------------------------
extract_unit_price() {
    grep -oP "<p class=\"CommodityPrice_priceName__Ehicd capitalize\">$1</p><p class=\"CommodityPrice_convertPrice__5Addh ml-auto justify-self-end\">\K[0-9,]+\.[0-9]+" "$RAW_FILE" \
        | head -1 | tr -d ','
}

unit_ounce_usd=$(extract_unit_price "ounce")
unit_gram_usd=$(extract_unit_price "gram")
unit_kilo_usd=$(extract_unit_price "Kilo")
unit_pennyweight_usd=$(extract_unit_price "pennyweight")
unit_tola_usd=$(extract_unit_price "tola")
unit_tael_usd=$(extract_unit_price "tael")

unit_ounce_usd=$(printf "%.2f" "$unit_ounce_usd")
unit_gram_usd=$(printf "%.2f" "$unit_gram_usd")
unit_kilo_usd=$(printf "%.2f" "$unit_kilo_usd")
unit_pennyweight_usd=$(printf "%.2f" "$unit_pennyweight_usd")
unit_tola_usd=$(printf "%.2f" "$unit_tola_usd")
unit_tael_usd=$(printf "%.2f" "$unit_tael_usd")

# ----------------------------
# Extract conversion rates
# ----------------------------
extract_usdtoc() {
    grep -oP "\"$1\"[^}]*\"usdtoc\":\K[0-9]+\.[0-9]+" "$RAW_FILE" | head -1
}

extract_ctousd() {
    grep -oP "\"$1\"[^}]*\"ctousd\":\K[0-9]+\.[0-9]+" "$RAW_FILE" | head -1
}

rate_USD=1
rate_EUR=$(extract_usdtoc "EUR")
rate_GBP=$(extract_usdtoc "GBP")
rate_AUD=$(extract_usdtoc "AUD")
rate_CNY=$(extract_usdtoc "CNY")

ctousd_USD=1
ctousd_EUR=$(extract_ctousd "EUR")
ctousd_GBP=$(extract_ctousd "GBP")
ctousd_AUD=$(extract_ctousd "AUD")
ctousd_CNY=$(extract_ctousd "CNY")

# ============================
# FIXED TIMESTAMP (NO COMMAS)
# ============================
timestamp=$(TZ="America/New_York" date '+%Y-%m-%d %H:%M:%S %Z')

# ----------------------------
# Process all currencies
# ----------------------------
for currency in "${CURRENCIES[@]}"; do

    case $currency in
        "USD") rate=1;         ctousd=1 ;;
        "EUR") rate=$rate_EUR; ctousd=$ctousd_EUR ;;
        "GBP") rate=$rate_GBP; ctousd=$ctousd_GBP ;;
        "AUD") rate=$rate_AUD; ctousd=$ctousd_AUD ;;
        "CNY") rate=$rate_CNY; ctousd=$ctousd_CNY ;;
    esac

    bid_price=$(printf "%.2f" "$(echo "$bid_usd / $rate" | bc -l)")
    ask_price=$(printf "%.2f" "$(echo "$ask_usd / $rate" | bc -l)")
    high_price=$(printf "%.2f" "$(echo "$high_usd / $rate" | bc -l)")
    low_price=$(printf "%.2f" "$(echo "$low_usd / $rate" | bc -l)")

    unit_ounce=$(printf "%.2f" "$(echo "$unit_ounce_usd / $rate" | bc -l)")
    unit_gram=$(printf "%.2f" "$(echo "$unit_gram_usd / $rate" | bc -l)")
    unit_kilo=$(printf "%.2f" "$(echo "$unit_kilo_usd / $rate" | bc -l)")
    unit_pennyweight=$(printf "%.2f" "$(echo "$unit_pennyweight_usd / $rate" | bc -l)")
    unit_tola=$(printf "%.2f" "$(echo "$unit_tola_usd / $rate" | bc -l)")
    unit_tael=$(printf "%.2f" "$(echo "$unit_tael_usd / $rate" | bc -l)")

    display_currency_data "$currency" "$timestamp" "$ctousd" "$bid_price" "$ask_price" "$high_price" "$low_price" \
        "$unit_ounce" "$unit_gram" "$unit_kilo" "$unit_pennyweight" "$unit_tola" "$unit_tael"

    save_to_file "$currency" "$timestamp" "$ctousd" "$bid_price" "$ask_price" "$high_price" "$low_price" \
        "$unit_ounce" "$unit_gram" "$unit_kilo" "$unit_pennyweight" "$unit_tola" "$unit_tael"

    sleep 1
done

echo ""
echo "SUMMARY REPORT"
echo "=============="

for currency in "${CURRENCIES[@]}"; do
    file="$DATA_DIR/${currency}_gold_prices.csv"
    if [ -f "$file" ]; then
        count=$(($(wc -l < "$file") - 1))
        echo "$currency: $count records"
    else
        echo "$currency: No data"
    fi
done

log_message "Gold price tracker completed successfully"
