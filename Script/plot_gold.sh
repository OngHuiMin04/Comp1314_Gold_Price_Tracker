#!/bin/bash

# =====================================================
# GOLD PLOT SCRIPT (FINAL VERSION)
# =====================================================

DB="goldtracker"
DB_USER="root"
DB_PASS=""   # Leave empty if no password

PLOT_DIR="./plots"
mkdir -p "$PLOT_DIR"

# =====================================================
# EXPORT SQL DATA TO TEXT FILES
# =====================================================
export_data() {
    CURR=$1
    OUTFILE="$PLOT_DIR/${CURR}_sql_data.txt"

    echo "Exporting $CURR data to $OUTFILE ..."

    mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB" -e "
        SELECT
            gp.gold_prices_id,
            gp.price_timestamp_ny,
            gp.script_timestamp_my,
            gp.bid_price,
            gp.ask_price,
            gp.high_price,
            gp.low_price
        FROM gold_prices gp
        JOIN currencies c ON gp.currency_id = c.currencies_id
        WHERE c.currency_name = '$CURR'
        ORDER BY gp.gold_prices_id;
    " > "$OUTFILE"
}

# Export all currencies
export_all() {
    for CURR in USD EUR GBP AUD CNY; do
        export_data "$CURR"
    done
}

# =====================================================
# COMMON GNUPLOT SETTINGS
# =====================================================
COMMON_SETTINGS="
set terminal png size 1600,900
set datafile separator whitespace
set key autotitle columnhead
set style data lines
set grid
"

# =====================================================
# PLOT BID/ASK/HIGH/LOW FOR A CURRENCY
# =====================================================
plot_currency() {
    CURR=$1
    INPUT="$PLOT_DIR/${CURR}_sql_data.txt"
    OUTPUT="$PLOT_DIR/${CURR}_price_plot.png"

    echo "Plotting $CURR → $OUTPUT"

gnuplot <<EOF
$COMMON_SETTINGS
set output "$OUTPUT"
set title "$CURR Gold Price (From MySQL)"
set xlabel "Record Index"
set ylabel "Price"

plot \
    "$INPUT" using 1:4 with lines lw 2 title "Bid", \
    "$INPUT" using 1:5 with lines lw 2 title "Ask", \
    "$INPUT" using 1:6 with lines lw 2 title "High", \
    "$INPUT" using 1:7 with lines lw 2 title "Low"
EOF
}

# =====================================================
# PLOT ALL CURRENCIES TOGETHER (BID ONLY)
# =====================================================
plot_all_bid() {
    OUT="$PLOT_DIR/all_currency_bid_price.png"

    echo "Plotting ALL → $OUT"

gnuplot <<EOF
$COMMON_SETTINGS
set output "$OUT"
set title "All Currencies - Bid Price Comparison"
set xlabel "Record Index"
set ylabel "Bid Price"

plot \
    "$PLOT_DIR/USD_sql_data.txt" using 1:4 with lines lw 2 title "USD", \
    "$PLOT_DIR/EUR_sql_data.txt" using 1:4 with lines lw 2 title "EUR", \
    "$PLOT_DIR/GBP_sql_data.txt" using 1:4 with lines lw 2 title "GBP", \
    "$PLOT_DIR/AUD_sql_data.txt" using 1:4 with lines lw 2 title "AUD", \
    "$PLOT_DIR/CNY_sql_data.txt" using 1:4 with lines lw 2 title "CNY"
EOF
}

# =====================================================
# RUN EVERYTHING
# =====================================================
echo "======================================="
echo " Exporting MySQL Data..."
echo "======================================="
export_all

echo "======================================="
echo " Plotting Each Currency..."
echo "======================================="
for CURR in USD EUR GBP AUD CNY; do
    plot_currency "$CURR"
done

echo "======================================="
echo " Plotting ALL Currency Comparison..."
echo "======================================="
plot_all_bid

echo "======================================="
echo " Plot Script Completed Successfully!"
echo "Plots saved in: $PLOT_DIR"
echo "======================================="
