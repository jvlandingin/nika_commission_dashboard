# Multi-Currency Payment System Documentation

## Overview

This document describes the multi-currency payment tracking system implemented in the Digital Artist Dashboard. The system supports USD and PHP currencies with automatic exchange rate fetching and conversion.

## Features Implemented (Phase 1)

### 1. Multi-Currency Project Support
- Projects can be created in either USD or PHP
- Currency is selected when creating a new project
- Budget and payments are tracked in the project's base currency

### 2. Payment Records System
- Separate payment tracking independent of projects
- Each payment records:
  - Amount and currency (USD or PHP)
  - Payment date
  - Payment method (Cash, Bank Transfer, PayPal, Gcash, Crypto, Other)
  - Exchange rate at time of payment
  - Optional notes

### 3. Automatic Exchange Rate Fetching
- Fetches live USD to PHP exchange rates from [exchangerate-api.com](https://www.exchangerate-api.com/)
- Free tier: 1,500 requests/month
- Fallback rate: 58 PHP per USD if API fails
- Exchange rate is stored with each payment for historical accuracy

### 4. Payment History Table
- Displays all payments with:
  - Project name
  - Payment date
  - Original amount with currency symbol
  - USD equivalent
  - PHP equivalent
  - Exchange rate used
  - Payment method
  - Notes
- Sortable and filterable columns
- Export to CSV/Excel

### 5. Auto-Update Project Status
- When a payment is recorded, the system automatically:
  - Calculates total payments (with currency conversion if needed)
  - Updates project's `amount_paid` field
  - Updates `payment_status` to:
    - **"Paid"** if total paid ≥ budget
    - **"Partially Paid"** if total paid > 0 but < budget
    - **"Unpaid"** if total paid = 0

### 6. Payment Management
- **Add payments**: Record new payments via Payment Records tab
- **Delete payments**: Select rows and delete with confirmation dialog
- **Refresh from Google Sheets**: Sync payments from cloud storage

## Architecture

### Database Schema

#### Projects Table
```
projects (
  id INTEGER PRIMARY KEY,
  project_name TEXT NOT NULL,
  project_type TEXT,
  start_date TEXT,
  deadline TEXT,
  budget REAL,
  currency TEXT,              -- NEW: "USD" or "PHP"
  status TEXT,
  payment_status TEXT,        -- Auto-updated: "Paid", "Partially Paid", "Unpaid"
  amount_paid REAL,          -- Auto-calculated from payments
  description TEXT
)
```

#### Payments Table
```
payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  payment_date TEXT NOT NULL,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,     -- "USD" or "PHP"
  exchange_rate REAL,         -- Stored for historical accuracy
  payment_method TEXT,
  notes TEXT,
  FOREIGN KEY (project_id) REFERENCES projects(id)
)
```

### Data Storage

The system uses a **dual-storage approach**:

1. **Google Sheets** (Source of Truth)
   - "Data" sheet for projects
   - "Payments" sheet for payment records
   - Cloud-based, accessible from anywhere
   - Manual edits possible

2. **SQLite** (Local Cache)
   - Fast local access
   - Automatic sync from Google Sheets
   - Used when Google Sheets is unavailable

### File Structure

```
R/
├── data_model.R          # Project data CRUD operations
├── payments_model.R      # Payment data CRUD operations (NEW)
├── utils_currency.R      # Currency utilities (NEW)
├── utils_statistics.R    # Statistics calculations
└── utils_charts.R        # Chart generation

global.R                  # Global configuration
ui.R                      # UI definition
server.R                  # Server logic
```

## Key Functions

### Currency Utilities (`R/utils_currency.R`)

#### `fetch_exchange_rate()`
Fetches current USD to PHP exchange rate from API.

**Returns:** Numeric exchange rate (e.g., 57.99)

**Example:**
```r
rate <- fetch_exchange_rate()
# Fetched exchange rate: 1 USD = 57.99 PHP
```

#### `convert_currency(amount, from_currency, to_currency, exchange_rate)`
Converts an amount between USD and PHP.

**Parameters:**
- `amount`: Numeric amount to convert
- `from_currency`: Source currency ("USD" or "PHP")
- `to_currency`: Target currency ("USD" or "PHP")
- `exchange_rate`: Exchange rate (1 USD = X PHP)

**Example:**
```r
convert_currency(100, "USD", "PHP", 58)  # Returns 5800
convert_currency(5800, "PHP", "USD", 58) # Returns 100
```

#### `format_currency_display(amount, currency)`
Formats an amount with the appropriate currency symbol. Vectorized to handle multiple amounts.

**Example:**
```r
format_currency_display(100, "USD")  # Returns "$100.00"
format_currency_display(5800, "PHP") # Returns "₱5,800.00"

# Handles NA values
format_currency_display(c(100, NA, 200), "USD")  # Returns c("$100.00", NA, "$200.00")
```

#### `convert_projects_to_display_currency(projects, display_currency, exchange_rate)` ✨ NEW (Phase 2)
Converts project budgets and amounts to a target display currency without modifying source data.

**Parameters:**
- `projects`: Dataframe of projects
- `display_currency`: Target currency ("USD" or "PHP")
- `exchange_rate`: Exchange rate (1 USD = X PHP)

**Returns:** Projects dataframe with converted amounts

**Example:**
```r
# Convert USD projects to PHP for display
converted <- convert_projects_to_display_currency(projects, "PHP", 57.99)
# Project with budget $1000 now shows ₱57,990
```

**Important:** Uses `case_when()` to properly handle NA values in `amount_paid`.

#### `get_latest_exchange_rate(payments_data)` ✨ NEW (Phase 2)
Smart exchange rate selection: uses latest payment rate or fetches from API.

**Parameters:**
- `payments_data`: Dataframe of payments (optional)

**Returns:** Numeric exchange rate

**Logic:**
1. Checks payments for most recent rate
2. Falls back to API if no payments or rate is NA

**Example:**
```r
rate <- get_latest_exchange_rate(payments_data())
# Returns 57.99 if that was the latest payment's rate
# Otherwise fetches current rate from API
```

### Payment Data Model (`R/payments_model.R`)

#### `load_payments_data()`
Loads payment records with priority: Google Sheets > SQLite.

**Returns:** Dataframe of payments

#### `save_payments_data(data)`
Saves payments to both Google Sheets and SQLite.

**Parameters:**
- `data`: Payments dataframe

## Usage Guide

### Creating a Project with Currency

1. Go to **New Project** tab
2. Fill in project details
3. Select currency (USD or PHP)
4. Set budget in the selected currency
5. Click **Add Project**

**Note:** `amount_paid` and `payment_status` are auto-calculated, no need to set them.

### Recording a Payment

1. Go to **Payment Records** tab
2. Select project from dropdown (shows project name and currency)
3. Enter payment amount
4. Select payment currency (USD or PHP)
5. Select payment date (defaults to today)
6. Choose payment method
7. Add optional notes
8. Click **Add**

**What happens:**
- Exchange rate is fetched automatically from API
- Payment is saved to Google Sheets and SQLite
- Project's `amount_paid` is updated (with currency conversion if needed)
- Project's `payment_status` is auto-updated

### Viewing Payment History

The **Payment History** table shows:
- All payments sorted by date (newest first)
- Original amount with currency symbol
- USD equivalent (for comparison)
- PHP equivalent (for comparison)
- Exchange rate used for the payment

**Features:**
- Filter columns by typing in filter boxes
- Sort by clicking column headers
- Export to CSV/Excel
- Copy to clipboard

### Deleting Payments

1. Select payment rows (checkboxes appear on click)
2. Click **Delete Selected** button
3. Confirm deletion in the dialog
4. Payments are removed from Google Sheets and SQLite

### Refreshing from Google Sheets

If you manually edit payments in Google Sheets:
1. Click **Refresh** button in Payment Records tab
2. App syncs with Google Sheets
3. Local SQLite cache is updated

**Handles:**
- Empty sheets (when all payments are deleted)
- New payments added manually
- Edited payments

## Currency Conversion Logic

### When Recording a Payment

The system calculates totals in the **project's base currency**:

**Example 1: USD project, USD payment**
- Project budget: $1,000 USD
- Payment: $500 USD
- Total paid: $500 USD (no conversion)

**Example 2: USD project, PHP payment**
- Project budget: $1,000 USD
- Payment: ₱2,900 PHP (rate: 58)
- Total paid: $550 USD ($500 existing + ₱2,900/58 = $50)

**Example 3: PHP project, USD payment**
- Project budget: ₱58,000 PHP
- Payment: $100 USD (rate: 58)
- Total paid: ₱35,800 PHP (₱29,000 existing + $100*58 = ₱5,800)

### Payment Status Updates

After calculating total paid:
```
if (total_paid >= budget):
    payment_status = "Paid"
else if (total_paid > 0):
    payment_status = "Partially Paid"
else:
    payment_status = "Unpaid"
```

## Google Sheets Setup

### Payments Sheet Structure

Create a sheet named **"Payments"** with these columns (case-sensitive):

| Column Name | Type | Description |
|-------------|------|-------------|
| `id` | Integer | Payment ID (auto-increments) |
| `project_id` | Integer | Project ID (from Data sheet) |
| `payment_date` | Date | Date payment received |
| `amount` | Number | Payment amount |
| `currency` | Text | "USD" or "PHP" |
| `exchange_rate` | Number | USD to PHP rate (e.g., 57.99) |
| `payment_method` | Text | Payment method |
| `notes` | Text | Optional notes |

**Important:**
- Column names must match exactly
- First row should be headers
- App will auto-populate data when you record payments

## API Configuration

### Exchange Rate API

**Provider:** [exchangerate-api.com](https://www.exchangerate-api.com/)
**Endpoint:** `https://api.exchangerate-api.com/v4/latest/USD`
**Rate Limit:** 1,500 requests/month (free tier)

**Response format:**
```json
{
  "base": "USD",
  "date": "2025-10-04",
  "rates": {
    "PHP": 57.99,
    ...
  }
}
```

**Fallback:** If API fails, uses default rate of 58 PHP per USD.

## Features Implemented (Phase 2)

### 1. Currency Toggle on Dashboard ✅

The dashboard now includes a currency display toggle that allows you to view all statistics in either USD or PHP.

**Location:** Dashboard tab, "Dashboard Filters" box

**Features:**
- Radio buttons to select display currency (USD or PHP)
- Automatically converts all project budgets and amounts to selected currency
- Uses smart exchange rate selection:
  - First tries to use latest exchange rate from recorded payments
  - Falls back to API if no payments exist
- Preserves original project currencies (no data modification)

**What gets converted:**
- Total Revenue value box
- Project budgets in tables
- Project amount_paid in tables

**Technical Implementation:**
- New reactive: `display_data()` - converts filtered projects to display currency
- New function: `convert_projects_to_display_currency()` - handles conversion logic
- New function: `get_latest_exchange_rate()` - smart rate selection
- Uses `case_when()` for proper NA handling in conversions

### 2. Smart Exchange Rate Selection

The system now intelligently selects exchange rates:

**Priority:**
1. **Latest payment rate** (most accurate, reflects actual transaction)
2. **API rate** (fallback if no payments exist)

**Example:**
```r
# If your latest payment used rate 57.99, dashboard uses 57.99
# If no payments, fetches current rate from API
get_latest_exchange_rate(payments_data())
```

## Future Enhancements (Phase 3+)

### Planned Features

1. **Enhanced Payment Management**
   - Edit existing payments
   - Payment history per project
   - Bulk payment import

2. **Advanced Calculations**
   - Remove manual `amount_paid` field completely
   - Calculate entirely from payments table
   - Track payment trends over time

3. **Additional Currencies**
   - Support more currencies (EUR, GBP, JPY, etc.)
   - Multi-currency conversion chains

## Troubleshooting

### Issue: Exchange rate not fetching

**Symptoms:** Default rate (58) always used

**Solutions:**
1. Check internet connection
2. Verify API is not rate-limited (1,500 requests/month)
3. Check console for error messages

### Issue: Payments not syncing to Google Sheets

**Symptoms:** "Failed to refresh payments" error

**Solutions:**
1. Check service account authentication
2. Verify "Payments" sheet exists with correct column names
3. Check Google Sheets permissions

### Issue: Payment status not updating

**Symptoms:** Shows "Unpaid" despite payments

**Solutions:**
1. Check currency conversions are correct
2. Verify exchange rates are being stored
3. Refresh the page and check again

### Issue: Empty payments table shows error

**Symptoms:** Error when viewing Payment Records tab with no payments

**Solutions:**
1. Click "Refresh" to sync with Google Sheets
2. If Google Sheets is empty, system will show "No payments recorded yet"

### Issue: Currency conversion shows wrong amounts (FIXED in Phase 2)

**Symptoms:**
- All projects show same converted amount
- Conversions seem incorrect (e.g., 650 USD → ₱223,261.50)

**Root Cause:** `ifelse()` doesn't handle NA values properly in vectorized operations, causing value recycling.

**Fix Applied:** Replaced `ifelse()` with `case_when()` in `convert_projects_to_display_currency()`:
- Explicitly preserves NA values
- Properly handles row-by-row conversion
- More readable conditional logic

**Verification:**
```r
# Before fix: All projects showed ₱31,894.50 (550 * 57.99)
# After fix:
#   - 550 USD → ₱31,894.50 ✓
#   - 100 USD → ₱5,799.00 ✓
#   - NA remains NA ✓
```

## Development Notes

### Adding a New Currency

1. Add to `CURRENCIES` in `global.R`:
   ```r
   CURRENCIES <- c("USD", "PHP", "EUR")
   ```

2. Update `fetch_exchange_rate()` to fetch new rate:
   ```r
   # Fetch EUR rate as well
   eur_rate <- data$rates$EUR
   ```

3. Update conversion logic in `convert_currency()`

4. Update display formatting in `format_currency_display()`

### Modifying Payment Methods

Edit `PAYMENT_METHODS` in `global.R`:
```r
PAYMENT_METHODS <- c("Cash", "Bank Transfer", "PayPal", "Gcash", "Crypto", "Other", "Your New Method")
```

## References

- [Exchange Rate API Documentation](https://www.exchangerate-api.com/docs/overview)
- [Google Sheets API (googlesheets4)](https://googlesheets4.tidyverse.org/)
- [Shiny Documentation](https://shiny.rstudio.com/)
- [DT (DataTables) Documentation](https://rstudio.github.io/DT/)
