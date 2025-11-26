#!/bin/bash
# ============================
# GOLD PRICE TRACKER (RAW HTML)
# ============================

PAGE="https://www.kitco.com/charts/gold"
RAW_FILE="/mnt/c/Users/Amanda Ong/Documents/GitHub/Comp1314_Gold_Price_Tracker/HTML/raw.html"
CURRENCIES=("USD" "EUR" "GBP" "AUD" "CNY")
DATA_DIR="./gold_data"
LOG_FILE="$DATA_DIR/gold_tracker.log"

mkdir -p "$DATA_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# ----------------------------
# Display result
# ----------------------------
display_currency_data() {
    local currency=$1
    local timestamp=$2
    local bid_price=$3
    local ask_price=$4
    local high_price=$5
    local low_price=$6

    echo "=========================================="
    echo " GOLD PRICE - $currency"
    echo "=========================================="
    printf "%-18s : %s\n" "Bid Price"     "$bid_price"
    printf "%-18s : %s\n" "Ask Price"     "$ask_price"
    printf "%-18s : %s\n" "High Price"    "$high_price"
    printf "%-18s : %s\n" "Low Price"     "$low_price"
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
    local bid_price=$3
    local ask_price=$4
    local high_price=$5
    local low_price=$6

    local file="$DATA_DIR/${currency}_gold_prices.csv"

    if [ ! -f "$file" ]; then
        echo "timestamp,bid_price,ask_price,high_price,low_price,script_run_time" > "$file"
    fi

    echo "$timestamp,$bid_price,$ask_price,$high_price,$low_price,$(TZ="Asia/Kuala_Lumpur" date '+%Y-%m-%d %H:%M:%S')" >> "$file"
}

# ----------------------------
# Start Tracking
# ----------------------------
log_message "Starting gold tracker..."
curl -s "$PAGE" > raw.html
rawdata=$(cat raw.html)

# ----------------------------
# Extract BID & ASK
# ----------------------------
bid_usd=$(grep -oP '<h3[^>]*>\K[0-9,]+\.[0-9]+' raw.html | head -1 | tr -d ',')
ask_usd=$(grep -oP 'text-\[19px\] font-normal">\K[0-9,]+\.[0-9]+' raw.html | head -1 | tr -d ',')

bid_usd=$(printf "%.2f" "$bid_usd")
ask_usd=$(printf "%.2f" "$ask_usd")

# ----------------------------
# Extract HIGH & LOW
# ----------------------------
low_usd=$(grep -oP 'CommodityPrice_priceToday__wBwVD"><div>\K[0-9,]+\.[0-9]+' raw.html | head -1 | tr -d ',')
high_usd=$(grep -oP 'CommodityPrice_priceToday__wBwVD"><div>[0-9,]+\.[0-9]+</div><div>\K[0-9,]+\.[0-9]+' raw.html | head -1 | tr -d ',')

low_usd=$(printf "%.2f" "$low_usd")
high_usd=$(printf "%.2f" "$high_usd")

# ----------------------------
# Extract UNIT PRICES (USD)
# ----------------------------
extract_unit_price() {
    grep -oP "<p class=\"CommodityPrice_priceName__Ehicd capitalize\">$1</p><p class=\"CommodityPrice_convertPrice__5Addh ml-auto justify-self-end\">\K[0-9,]+\.[0-9]+" raw.html \
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
# Extract Currency Rates (usdtoc)
# ----------------------------
extract_rate() {
    grep -oP "\"$1\"[^}]*\"usdtoc\":\K[0-9]+\.[0-9]+" raw.html | head -1
}

rate_USD=1
rate_EUR=$(extract_rate "EUR")
rate_GBP=$(extract_rate "GBP")
rate_AUD=$(extract_rate "AUD")
rate_CNY=$(extract_rate "CNY")

timestamp=$(TZ="America/New_York" date '+%b %d, %Y at %I:%M %p %Z')

# ----------------------------
# Process each currency
# ----------------------------
for currency in "${CURRENCIES[@]}"; do

    case $currency in
        "USD") rate=1 ;;
        "EUR") rate=$rate_EUR ;;
        "GBP") rate=$rate_GBP ;;
        "AUD") rate=$rate_AUD ;;
        "CNY") rate=$rate_CNY ;;
    esac

    # Correct conversion (USD → Currency)
    bid_price=$(printf "%.2f" "$(echo "$bid_usd / $rate" | bc -l)")
    ask_price=$(printf "%.2f" "$(echo "$ask_usd / $rate" | bc -l)")
    high_price=$(printf "%.2f" "$(echo "$high_usd / $rate" | bc -l)")
    low_price=$(printf "%.2f" "$(echo "$low_usd / $rate" | bc -l)")

    # Units conversion
    unit_ounce=$(printf "%.2f" "$(echo "$unit_ounce_usd / $rate" | bc -l)")
    unit_gram=$(printf "%.2f" "$(echo "$unit_gram_usd / $rate" | bc -l)")
    unit_kilo=$(printf "%.2f" "$(echo "$unit_kilo_usd / $rate" | bc -l)")
    unit_pennyweight=$(printf "%.2f" "$(echo "$unit_pennyweight_usd / $rate" | bc -l)")
    unit_tola=$(printf "%.2f" "$(echo "$unit_tola_usd / $rate" | bc -l)")
    unit_tael=$(printf "%.2f" "$(echo "$unit_tael_usd / $rate" | bc -l)")

    display_currency_data "$currency" "$timestamp" "$bid_price" "$ask_price" "$high_price" "$low_price"
    save_to_file "$currency" "$timestamp" "$bid_price" "$ask_price" "$high_price" "$low_price"

    sleep 1
done

# ----------------------------
# Summary Report
# ----------------------------
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

