#!/bin/bash
# ALWAYS switch to Script folder (IMPORTANT for cron)
cd /mnt/c/Users/Amanda\ Ong/Documents/Github/Comp1314_Gold_Price_Tracker/Script
DB="goldtracker"
DB_USER="root"
PLOT_DIR="./plots"
LOG_DIR="./log"
SQL_DIR="./sql_queries"

mkdir -p "$PLOT_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$SQL_DIR"

CURRENCIES=("USD" "EUR" "GBP" "AUD" "CNY")

# =====================================================
# 1. Create SQL files + LOG dump for every currency
# =====================================================
make_sql_file() {
    local C="$1"
    local SQLFILE="$SQL_DIR/${C}.sql"
    local LOGFILE="$LOG_DIR/${C}.data"

    cat > "$SQLFILE" <<EOF
SELECT gp.script_timestamp_my,
       gp.bid_price,
       gp.ask_price,
       gp.high_price,
       gp.low_price
FROM gold_prices gp
JOIN currencies c
    ON gp.currency_id = c.currencies_id
WHERE c.currency_name = '$C'
ORDER BY gp.price_timestamp_ny;
EOF

    # dump SQL output to log file
    mysql -u "$DB_USER" -D "$DB" -N < "$SQLFILE" > "$LOGFILE"
}

# generate SQL + logs
for C in "${CURRENCIES[@]}"; do
    make_sql_file "$C"
done

# =====================================================
# 2. Generate plots
# =====================================================
for C in "${CURRENCIES[@]}"; do

gnuplot <<EOF
set terminal png size 1700,900

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"

# ======================================================
# (UPDATED) Malaysia Time Axis Formatting
# You requested: Wed 10 Dec 2025 21:35
# ======================================================
set format x "%a %d %b %Y\n%H:%M"
# %a  = Mon, Tue, Wed...
# %d  = day number
# %b  = Dec, Jan, Feb...
# %Y  = 2025
# %H:%M = 24-hour time

set xtics rotate by -45
set xtics font ",10"
set ytics font ",10"
set grid
set key outside
set datafile separator "\t"

# ============================
# BID VS ASK
# ============================
set output "${PLOT_DIR}/bid_vs_ask_${C}.png"
set title "Bid vs Ask - ${C}"
set xlabel "Timestamp (Malaysia Time)"
set ylabel "Price"

plot "< mysql -u $DB_USER -D $DB -N < ${SQL_DIR}/${C}.sql" using 1:2 with linespoints lw 2 pt 7 title "${C} Bid", \
     "< mysql -u $DB_USER -D $DB -N < ${SQL_DIR}/${C}.sql" using 1:3 with linespoints lw 2 pt 7 title "${C} Ask"

# ============================
# HIGH VS LOW
# ============================
set output "${PLOT_DIR}/high_vs_low_${C}.png"
set title "High vs Low - ${C}"
set xlabel "Timestamp (Malaysia Time)"
set ylabel "Price"

plot "< mysql -u $DB_USER -D $DB -N < ${SQL_DIR}/${C}.sql" using 1:4 with linespoints lw 2 pt 7 title "${C} High", \
     "< mysql -u $DB_USER -D $DB -N < ${SQL_DIR}/${C}.sql" using 1:5 with linespoints lw 2 pt 7 title "${C} Low"

EOF

done

echo "DONE! Logs saved in ./log/ and 10 plots saved in ./plots/"
