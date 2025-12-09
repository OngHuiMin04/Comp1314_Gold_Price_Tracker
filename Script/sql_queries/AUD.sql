SELECT gp.price_timestamp_ny,
       gp.bid_price,
       gp.ask_price,
       gp.high_price,
       gp.low_price
FROM gold_prices gp
JOIN currencies c
    ON gp.currency_id = c.currencies_id
WHERE c.currency_name = 'AUD'
ORDER BY gp.price_timestamp_ny;
