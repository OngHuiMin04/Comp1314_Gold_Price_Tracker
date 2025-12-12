# COMP1314 Gold Price Tracker

## Project Overview
This project is a **Gold Price Tracker** developed for the COMP1314 coursework.  
It automatically collects live gold price data from an external website, stores
historical records in a MySQL database, and generates visual plots using Gnuplot.

The project demonstrates:
- Unix shell scripting
- Data scraping and cleaning
- MySQL database design and normalization
- Automation using crontab
- Data visualization using Gnuplot
- Version control using Git and GitHub

---

## Data Source
- **Website**: https://www.kitco.com/charts/gold  
- **Currencies Tracked**:
  - USD
  - EUR
  - GBP
  - AUD
  - CNY

---

## Project Structure
Comp1314_Gold_Price_Tracker/
│
├── Script/
│ ├── gold_tracker.sh # Main tracker (scraping + CSV output)
│ ├── gold_scrapper.sh # Insert data into MySQL
│ ├── plot_gold.sh # Generate plots using Gnuplot
│ ├── raw.html # Raw HTML downloaded from Kitco
│ ├── gold_data/ # CSV historical data
│ ├── plots/ # Generated PNG plots
│ ├── log/ # Log files
│ └── sql_queries/ # Auto-generated SQL queries
│
├── SQL/
│ └── goldtracker_schema.sql # MySQL database schema
│
├── ERD Diagram/
│ └── goldtracker_erd.pdf # Database ERD
│
├── Crontab_Script
│
└── README.md

---

## Technologies Used
- **Operating System**: Windows with WSL (Ubuntu)
- **Scripting Language**: Bash
- **Database**: MySQL 8
- **Plotting Tool**: Gnuplot
- **Automation**: Crontab
- **Version Control**: Git & GitHub

---

## Database Design
The project uses a MySQL database named **`goldtracker`**.

### Tables
- **currencies**  
  Stores currency name and exchange rate (ctousd)

- **gold_prices**  
  Stores bid, ask, high, and low prices with timestamps

- **unit_prices**  
  Stores gold prices by unit (ounce, gram, kilo, etc.)

- **logs**  
  Stores execution and insertion logs

The database follows normalization principles and uses foreign keys.

---

## Setup Instructions

### 1. Install Required Packages (WSL)
```bash
sudo apt update
sudo apt install mysql-server gnuplot curl -y
```
---

### 2. Start MySQL
```bash
sudo service mysql start
mysql -u root
```
---

### 3. Create Database and Tables
```bash
mysql -u root < SQL/goldtracker_schema.sql
```
---

## Running the Project

### Step 1: Run the Gold Tracker
```bash
cd Script
chmod +x gold_tracker.sh
./gold_tracker.sh
```
This script:

- Downloads the gold price webpage
- Extracts and cleans price data
- Saves data into CSV files
- Passes data to the MySQL insertion script

---

### Step 2: Insert Data into MySQL
```bash
chmod +x gold_scrapper.sh
./gold_scrapper.sh
```
This script:

- Inserts cleaned data into MySQL
- Prevents invalid or empty inserts
- Records logs for each execution

---

### Step 2: Insert Data into MySQL
```bash
chmod +x gold_scrapper.sh
./gold_scrapper.sh
```
This script:

- Inserts cleaned data into MySQL
- Prevents invalid or empty inserts
- Records logs for each execution

---

### Step 3: Generate Plots
```bash
chmod +x plot_gold.sh
./plot_gold.sh
```
This generates 10 plots, including:
- Bid vs Ask (for each currency)
- High vs Low (for each currency)

Plots are saved in:
Script/plots/

---

## Automation with Crontab
To automate hourly data collection:
crontab -e

Add the following line:
0 * * * * /mnt/c/Users/Amanda\ Ong/Documents/Github/Comp1314_Gold_Price_Tracker/Script/gold_tracker.sh
This allows the tracker to run automatically every hour.

## Error Handling
The scripts handle:
- No internet connection
- Website unreachable
- Missing or zero price values
- Invalid SQL inserts

Errors are logged without stopping the entire system.

## Version Control
- All scripts are managed using GitHub
- Commits were made regularly across multiple days
- The repository reflects incremental development and debugging

## Conclusion
This Gold Price Tracker successfully meets all coursework requirements by:
- Automating data collection
- Storing historical data in MySQL
- Generating meaningful plots
- Demonstrating effective use of Linux tools and Git

## Author
**Ong Hui Min**  
University of Southampton Malaysia  
BSc Computer Science (Year 1)

GitHub: https://github.com/OngHuiMin04

## Academic Integrity
This project developed for **COMP1314 Coursework** and complies with the University of Southampton Malaysia academic integrity policy.
All sources used for reference are acknowledged, and the implementation represents original student work.

