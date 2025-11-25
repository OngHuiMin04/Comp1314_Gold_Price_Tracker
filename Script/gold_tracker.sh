#!/bin/bash
# ============================
# GOLD PRICE TRACKER
# ============================

# ----------------------------
# Configuration
# ----------------------------
PAGE="https://www.kitco.com/charts/gold"
CURRENCIES=("USD" "EUR" "GBP" "AUD" "CNY")
DATA_DIR="./gold_data"
LOG_FILE="$DATA_DIR/gold_tracker.log"

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# ----------------------------
# Logging function
# ----------------------------
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# ----------------------------
# Display currency data
# ----------------------------
display_currency_data() {
    local currency=$1
    local timestamp=$2
    local bid_price=$3
    local ask_price=$4
    local ask_high=$5
    local ask_low=$6

    # Units conversion
    local ounce=$(printf "%.2f" "$bid_price")
    local gram=$(printf "%.2f" "$(echo "scale=4; $bid_price / 31.1034768" | bc)")
    local kilo=$(printf "%.2f" "$(echo "scale=4; $bid_price * 32.1507466" | bc)")
    local pennyweight=$(printf "%.2f" "$(echo "scale=4; $bid_price / 20" | bc)")
    local tola=$(printf "%.2f" "$(echo "scale=4; $bid_price * 0.375" | bc)")
    local tael=$(printf "%.2f" "$(echo "scale=4; $bid_price * 1.20337" | bc)")

    echo "=========================================="
    echo " GOLD PRICE - $currency"
    echo "=========================================="
    printf "%-15s : %s\n" "Bid Price"      "$bid_price"
    printf "%-15s : %s\n" "Ask Price"      "$ask_price"
    printf "%-15s : %s\n" "Ask High Price" "$ask_high"
    printf "%-15s : %s\n" "Ask Low Price"  "$ask_low"
    echo "--- Units ---"
    printf "%-15s : %s\n" "Ounce"    "$ounce"
    printf "%-15s : %s\n" "Gram"     "$gram"
    printf "%-15s : %s\n" "Kilo"     "$kilo"
    printf "%-15s : %s\n" "Pennyweight" "$pennyweight"
    printf "%-15s : %s\n" "Tola"     "$tola"
    printf "%-15s : %s\n" "Tael"     "$tael"
    printf "%-15s : %s\n" "Data Time" "$timestamp"
    printf "%-15s : %s\n" "Script Run" "$(TZ="Asia/Kuala_Lumpur" date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "------------------------------------------"
}

# ----------------------------
# Save data to CSV file
# ----------------------------
save_to_file() {
    local currency=$1
    local timestamp=$2
    local bid_price=$3
    local ask_price=$4
    local ask_high=$5
    local ask_low=$6

    local data_file="$DATA_DIR/${currency}_gold_prices.csv"

    if [ ! -f "$data_file" ]; then
        echo "timestamp,bid_price,ask_price,ask_high,ask_low,script_run_time" > "$data_file"
    fi

    echo "$timestamp,$bid_price,$ask_price,$ask_high,$ask_low,$(TZ="Asia/Kuala_Lumpur" date '+%Y-%m-%d %H:%M:%S %Z')" >> "$data_file"

    log_message "Data saved for $currency: $bid_price / $ask_price"
    echo ""
}

# ----------------------------
# Start tracking
# ----------------------------
log_message "Starting gold price tracker..."

# Fetch the webpage
if curl --head --silent --fail "$PAGE" > /dev/null; then
    rawdata=$(curl -s "$PAGE")
else
    echo "Website is not reachable at the moment"
    log_message "ERROR: Website is not reachable"
    exit 1
fi

# ----------------------------
# Extract base USD price
# ----------------------------
base_price=$(echo "$rawdata" | awk -F'<div class="mb-2 text-right">' '{print $2}' | awk -F'>' '{print $2}' | awk -F'<' '{print $1}' | tr -d '\n' | tr -d ',')

if [ -z "$base_price" ] || [ "$base_price" = "0.00" ]; then
    base_price=$(echo "$rawdata" | grep -oP '[0-9]{1,4},?[0-9]*\.[0-9]{2}' | head -1 | tr -d ',')
fi

if [ -z "$base_price" ] || [ "$base_price" = "0.00" ]; then
    echo "ERROR: Could not extract gold price"
    log_message "ERROR: Could not extract gold price"
    exit 1
fi

log_message "Successfully extracted base USD gold price: $base_price"

# ----------------------------
# Timestamp
# ----------------------------
timestamp=$(TZ="America/New_York" date '+%b %d, %Y at %I:%M %p %Z')

echo "GOLD PRICE TRACKER"
echo "=================="
echo "Tracking: ${CURRENCIES[*]}"
echo "Base USD Price: $base_price"
echo ""

# ----------------------------
# Process each currency
# ----------------------------
for currency in "${CURRENCIES[@]}"; do
    log_message "Processing $currency..."

    if [ "$currency" != "USD" ]; then
        exchange_rate=$(echo "$rawdata" | awk -F"$currency" '{print $2}' | awk -F'"bid":' '{print $2}' | awk -F',"' '{print $1}' | tr -d '\n')
        if [ -z "$exchange_rate" ] || [ "$exchange_rate" = "0.00" ]; then
            exchange_rate=$(echo "$rawdata" | grep -oP "\"$currency\"[^}]*\"bid\":[0-9]+\.[0-9]+" | awk -F'"bid":' '{print $2}' | head -1)
        fi
        if [ -z "$exchange_rate" ] || [ "$exchange_rate" = "0.00" ]; then
            log_message "ERROR: Could not extract exchange rate for $currency - skipping"
            echo ""
            continue
        fi

        bid_price=$(echo "$base_price * $exchange_rate" | bc)
        bid_price=$(printf "%.2f" "$bid_price")
    else
        bid_price="$base_price"
    fi

    ask_price=$(echo "$bid_price + 2.00" | bc)

    # ----------------------------
    # Ask high/low tracking
    # ----------------------------
    data_file="$DATA_DIR/${currency}_gold_prices.csv"
    if [ -f "$data_file" ]; then
        prev_ask_high=$(awk -F',' 'NR>1 {print $4}' "$data_file" | sort -nr | head -1)
        prev_ask_low=$(awk -F',' 'NR>1 {print $5}' "$data_file" | sort -n | head -1)

        ask_high_price=$(awk -v ask="$ask_price" -v prev="$prev_ask_high" 'BEGIN{if(ask>prev) print ask; else print prev}')
        ask_low_price=$(awk -v ask="$ask_price" -v prev="$prev_ask_low" 'BEGIN{if(ask<prev) print ask; else print prev}')
    else
        ask_high_price="$ask_price"
        ask_low_price="$ask_price"
    fi

    # ----------------------------
    # Display & Save
    # ----------------------------
    display_currency_data "$currency" "$timestamp" "$bid_price" "$ask_price" "$ask_high_price" "$ask_low_price"
    save_to_file "$currency" "$timestamp" "$bid_price" "$ask_price" "$ask_high_price" "$ask_low_price"

    sleep 2
done

# ----------------------------
# Summary Report
# ----------------------------
echo ""
echo "SUMMARY REPORT"
echo "=============="
for currency in "${CURRENCIES[@]}"; do
    data_file="$DATA_DIR/${currency}_gold_prices.csv"
    if [ -f "$data_file" ]; then
        record_count=$(($(wc -l < "$data_file") - 1))
        echo "$currency: $record_count records stored"
    else
        echo "$currency: No data file"
    fi
done

echo ""
echo "Data files location: $DATA_DIR"
echo "Log file: $LOG_FILE"
log_message "Gold price tracker completed successfully"

