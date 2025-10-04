# Phase 1 Implementation Guide: Multi-Currency & Payment Records

## Overview

This guide provides step-by-step instructions to complete Phase 1 of the multi-currency payment system.

------------------------------------------------------------------------

## Step 1: Update Sample Data with Currency Field

**File:** `R/data_model.R`

**Location:** In the `load_sample_data()` function, around line 330

**Change:** Add `currency` field after `payment_status`

``` r
# Current (around line 297-299):
status = sample(statuses, 25, replace = TRUE, prob = c(0.4, 0.5, 0.1)),
payment_status = sample(payment_statuses, 25, replace = TRUE, prob = c(0.5, 0.2, 0.3)),
amount_paid = 0,

# Change to:
status = sample(statuses, 25, replace = TRUE, prob = c(0.4, 0.5, 0.1)),
payment_status = sample(payment_statuses, 25, replace = TRUE, prob = c(0.5, 0.2, 0.3)),
currency = sample(c("USD", "PHP"), 25, replace = TRUE, prob = c(0.7, 0.3)),
amount_paid = 0,
```

------------------------------------------------------------------------

## Step 2: Add Currency Dropdown to New Project Form

**File:** `ui.R`

**Location:** In the New Project tab, after the `budget` input (around line 119)

**Add this code:**

``` r
# After:
numericInput("budget", "Budget (₱):", value = 0, min = 0),

# Add:
selectInput(
  "currency",
  "Currency:",
  choices = CURRENCIES,
  selected = "USD"
),
```

**Also update the budget label** to be currency-neutral:

``` r
# Change from:
numericInput("budget", "Budget (₱):", value = 0, min = 0),

# To:
numericInput("budget", "Budget:", value = 0, min = 0),
```

------------------------------------------------------------------------

## Step 3: Update Server to Handle Currency Field

**File:** `server.R`

**Location:** In the `observeEvent(input$add_project)` block (around line 280)

**Change:** Add `currency` field to new project data frame

``` r
# Current (around line 274-285):
new_project <- data.frame(
  id = max(projects_data()$id) + 1,
  project_name = input$project_name,
  project_type = input$project_type,
  start_date = input$start_date,
  deadline = input$deadline,
  budget = input$budget,
  amount_paid = input$amount_paid,
  status = input$status,
  payment_status = input$payment_status,
  description = input$description,
  stringsAsFactors = FALSE
)

# Change to:
new_project <- data.frame(
  id = max(projects_data()$id) + 1,
  project_name = input$project_name,
  project_type = input$project_type,
  start_date = input$start_date,
  deadline = input$deadline,
  budget = input$budget,
  currency = input$currency,
  amount_paid = input$amount_paid,
  status = input$status,
  payment_status = input$payment_status,
  description = input$description,
  stringsAsFactors = FALSE
)
```

------------------------------------------------------------------------

## Step 4: Create Payment Data Model Functions

**File:** `R/data_model.R`

**Location:** Add at the end of the file, before the sample data section

**Add these functions:**

``` r
# Payment Data Functions ----

#' Load payments from SQLite database
#' @return Dataframe of payments
load_payments_from_sqlite <- function() {
  con <- get_db_connection()

  if (dbExistsTable(con, "payments")) {
    payments <- dbReadTable(con, "payments") %>%
      mutate(payment_date = as.Date(payment_date))
  } else {
    payments <- data.frame()
  }

  dbDisconnect(con)
  return(payments)
}

#' Save payments to SQLite database
#' @param data Payments dataframe
save_payments_to_sqlite <- function(data) {
  con <- get_db_connection()

  # Convert dates to character for SQLite storage
  data_to_save <- data %>%
    mutate(payment_date = as.character(payment_date))

  # Append to table (don't overwrite)
  dbWriteTable(con, "payments", data_to_save, append = TRUE)

  dbDisconnect(con)
}

#' Load payments from Google Sheets
#' @return Dataframe of payments
load_payments_from_google_sheets <- function() {
  tryCatch(
    {
      # Use same authentication as projects
      service_account_json <- Sys.getenv("GS4_SERVICE_ACCOUNT")

      if (nzchar(service_account_json)) {
        temp_json <- tempfile(fileext = ".json")
        cat(service_account_json, file = temp_json)
        gs4_auth(path = temp_json)
        on.exit(unlink(temp_json))
      } else if (file.exists(".secrets/service-account.json")) {
        gs4_auth(path = ".secrets/service-account.json")
      } else if (file.exists(".secrets/gs4-token.rds")) {
        gs4_auth(token = readRDS(".secrets/gs4-token.rds"))
      } else {
        gs4_auth(email = "johnvincentland@gmail.com")
      }

      # Read from "Payments" sheet
      payments <- read_sheet(GOOGLE_SHEET_ID, sheet = "Payments") %>%
        mutate(
          payment_date = as.Date(payment_date),
          id = as.integer(id),
          project_id = as.integer(project_id),
          amount = as.numeric(amount),
          exchange_rate = as.numeric(exchange_rate)
        )

      return(payments)
    },
    error = function(e) {
      message("Error loading payments from Google Sheets: ", e$message)
      return(NULL)
    }
  )
}

#' Save payments to Google Sheets
#' @param data Payments dataframe
save_payments_to_google_sheets <- function(data) {
  tryCatch(
    {
      # Use same authentication as projects
      service_account_json <- Sys.getenv("GS4_SERVICE_ACCOUNT")

      if (nzchar(service_account_json)) {
        temp_json <- tempfile(fileext = ".json")
        cat(service_account_json, file = temp_json)
        gs4_auth(path = temp_json)
        on.exit(unlink(temp_json))
      } else if (file.exists(".secrets/service-account.json")) {
        gs4_auth(path = ".secrets/service-account.json")
      } else if (file.exists(".secrets/gs4-token.rds")) {
        gs4_auth(token = readRDS(".secrets/gs4-token.rds"))
      } else {
        gs4_auth(email = "johnvincentland@gmail.com")
      }

      # Get existing data
      existing <- load_payments_from_google_sheets()

      if (is.null(existing) || nrow(existing) == 0) {
        # First write - create sheet with data
        sheet_write(data, ss = GOOGLE_SHEET_ID, sheet = "Payments")
      } else {
        # Append new rows
        sheet_append(data, ss = GOOGLE_SHEET_ID, sheet = "Payments")
      }

      message("Successfully saved payments to Google Sheets")
      return(TRUE)
    },
    error = function(e) {
      message("Error saving payments to Google Sheets: ", e$message)
      return(FALSE)
    }
  )
}

#' Load all payments data (priority: Google Sheets > SQLite)
#' @return Dataframe of payments
load_payments_data <- function() {
  # Try Google Sheets first
  payments <- load_payments_from_google_sheets()

  if (!is.null(payments) && nrow(payments) > 0) {
    message("Loaded payments from Google Sheets")
    save_payments_to_sqlite(payments)
    return(payments)
  }

  # Try SQLite next
  init_database()
  payments <- load_payments_from_sqlite()

  if (nrow(payments) > 0) {
    message("Loaded payments from SQLite")
    return(payments)
  }

  # Return empty dataframe with correct structure
  message("No payments found")
  return(data.frame(
    id = integer(),
    project_id = integer(),
    payment_date = as.Date(character()),
    amount = numeric(),
    currency = character(),
    exchange_rate = numeric(),
    payment_method = character(),
    notes = character(),
    stringsAsFactors = FALSE
  ))
}

#' Save a new payment
#' @param data Single payment as dataframe
save_payment <- function(data) {
  # Save to SQLite
  save_payments_to_sqlite(data)

  # Save to Google Sheets
  save_payments_to_google_sheets(data)
}
```

------------------------------------------------------------------------

## Step 5: Add Payment Records Tab to UI

**File:** `ui.R`

**Location:** In the sidebar menu (around line 8-16)

**Add after "Manage Projects" menu item:**

``` r
menuItem(
  "Manage Projects",
  tabName = "manage_projects",
  icon = icon("table")
),
menuItem(
  "Payment Records",
  tabName = "payment_records",
  icon = icon("money-bill-wave")
)
```

------------------------------------------------------------------------

## Step 6: Create Payment Records Tab Content

**File:** `ui.R`

**Location:** In `tabItems`, after the "Manage Projects" tab (around line 192)

**Add this entire tab:**

``` r
# Payment Records tab
tabItem(
  tabName = "payment_records",
  fluidRow(
    box(
      title = "Record New Payment",
      status = "primary",
      solidHeader = TRUE,
      width = 12,
      fluidRow(
        column(
          width = 4,
          selectInput(
            "payment_project_id",
            "Project:",
            choices = NULL  # Will be populated dynamically
          ),
          dateInput(
            "payment_date",
            "Payment Date:",
            value = Sys.Date()
          )
        ),
        column(
          width = 4,
          numericInput(
            "payment_amount",
            "Amount:",
            value = 0,
            min = 0
          ),
          selectInput(
            "payment_currency",
            "Currency:",
            choices = CURRENCIES,
            selected = "USD"
          )
        ),
        column(
          width = 4,
          selectInput(
            "payment_method",
            "Payment Method:",
            choices = PAYMENT_METHODS,
            selected = "Bank Transfer"
          ),
          textInput(
            "payment_notes",
            "Notes (optional):",
            value = ""
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          actionButton(
            "add_payment",
            "Record Payment",
            icon = icon("save"),
            class = "btn-success"
          ),
          tags$span(
            id = "exchange_rate_display",
            style = "margin-left: 20px; color: #666;",
            ""
          )
        )
      )
    )
  ),
  fluidRow(
    box(
      title = "Payment History",
      status = "info",
      solidHeader = TRUE,
      width = 12,
      DT::dataTableOutput("payments_table")
    )
  )
)
```

------------------------------------------------------------------------

## Step 7: Wire Up Payment Recording in Server

**File:** `server.R`

**Location:** Add after the project management code, before the final closing brace

**Add this code:**

``` r
# Payment Records ----

# Load payments data
payments_data <- reactiveVal(load_payments_data())

# Update project dropdown choices when projects change
observe({
  projects <- projects_data()
  choices <- setNames(projects$id, paste0(projects$project_name, " (", projects$currency, " ", projects$budget, ")"))
  updateSelectInput(session, "payment_project_id", choices = choices)
})

# Record new payment
observeEvent(input$add_payment, {
  # Validate amount
  if (input$payment_amount <= 0) {
    showNotification(
      "Please enter a valid payment amount",
      type = "error",
      duration = 3
    )
    return()
  }

  # Fetch exchange rate
  exchange_rate <- fetch_exchange_rate()

  # Create new payment
  new_payment <- data.frame(
    id = ifelse(nrow(payments_data()) == 0, 1, max(payments_data()$id, na.rm = TRUE) + 1),
    project_id = as.integer(input$payment_project_id),
    payment_date = input$payment_date,
    amount = input$payment_amount,
    currency = input$payment_currency,
    exchange_rate = exchange_rate,
    payment_method = input$payment_method,
    notes = input$payment_notes,
    stringsAsFactors = FALSE
  )

  # Add to payments data
  updated_payments <- rbind(payments_data(), new_payment)
  payments_data(updated_payments)

  # Save to database
  save_payment(new_payment)

  # Show exchange rate info
  if (input$payment_currency == "USD") {
    equiv <- input$payment_amount * exchange_rate
    msg <- paste0("$", input$payment_amount, " = ₱", formatC(equiv, format = "f", big.mark = ",", digits = 2))
  } else {
    equiv <- input$payment_amount / exchange_rate
    msg <- paste0("₱", input$payment_amount, " = $", formatC(equiv, format = "f", big.mark = ",", digits = 2))
  }

  showNotification(
    paste("Payment recorded!", msg, "| Rate: 1 USD = ₱", exchange_rate),
    type = "message",
    duration = 5
  )

  # Clear form
  updateNumericInput(session, "payment_amount", value = 0)
  updateTextInput(session, "payment_notes", value = "")
})

# Display payments table
output$payments_table <- DT::renderDataTable(
  {
    payments <- payments_data()

    if (nrow(payments) == 0) {
      return(data.frame(Message = "No payments recorded yet"))
    }

    # Join with projects to show project names
    projects <- projects_data()

    payments %>%
      left_join(projects %>% select(id, project_name), by = c("project_id" = "id")) %>%
      arrange(desc(payment_date)) %>%
      select(
        Date = payment_date,
        Project = project_name,
        Amount = amount,
        Currency = currency,
        `Exchange Rate` = exchange_rate,
        Method = payment_method,
        Notes = notes
      ) %>%
      mutate(
        Amount = ifelse(Currency == "USD",
                       paste0("$", formatC(Amount, format = "f", big.mark = ",", digits = 2)),
                       paste0("₱", formatC(Amount, format = "f", big.mark = ",", digits = 2))),
        `Exchange Rate` = paste0("1 USD = ₱", formatC(`Exchange Rate`, format = "f", digits = 2))
      )
  },
  options = list(
    pageLength = 10,
    scrollX = TRUE,
    order = list(list(0, 'desc'))  # Sort by date descending
  ),
  rownames = FALSE
)
```

------------------------------------------------------------------------

## Step 8: Testing Checklist

After implementing all steps above:

### Test 1: Currency Field

-   [ ] Create a new project with USD currency
-   [ ] Create a new project with PHP currency
-   [ ] Verify currency appears in Manage Projects table
-   [ ] Verify existing projects default to USD

### Test 2: Payment Recording

-   [ ] Go to Payment Records tab
-   [ ] Record a payment in USD
-   [ ] Verify exchange rate is fetched and displayed
-   [ ] Record a payment in PHP
-   [ ] Verify payment appears in payment history table

### Test 3: Data Persistence

-   [ ] Refresh the app
-   [ ] Verify payments are still there
-   [ ] Check Google Sheets "Payments" sheet for saved data
-   [ ] Verify SQLite database has payments table

### Test 4: Exchange Rate

-   [ ] Record a USD payment, note the PHP equivalent shown
-   [ ] Verify the exchange rate is reasonable (around 1 USD = 55-60 PHP)
-   [ ] Check that the exchange_rate is stored with the payment

------------------------------------------------------------------------

## Troubleshooting

### Issue: Exchange rate API fails

**Solution:** The code uses a fallback rate of 58 PHP per USD. Check console for warnings.

### Issue: Google Sheets "Payments" sheet not found

**Solution:** Make sure you've created a sheet named exactly "Payments" (case-sensitive) in your Google Sheets file.

### Issue: Payment dropdown is empty

**Solution:** Make sure you have at least one project in the projects table.

### Issue: Payments not saving

**Solution:** Check console for error messages. Verify Google Sheets permissions.

------------------------------------------------------------------------

## What's NOT Included in Phase 1

These features will be added in Phase 2: - Currency toggle on dashboard (USD/PHP view) - Converting all statistics to selected currency - Auto-calculating payment_status from payments - Removing amount_paid field - Edit/delete payments - Payment history per project view - Advanced payment filters

------------------------------------------------------------------------

## Next Steps After Phase 1

Once you've tested everything and it works: 1. Commit your changes to git 2. Test on deployment (Posit Cloud) 3. Use the app for a while to see how it feels 4. Then we can start Phase 2 with the advanced features

Good luck! Let me know if you encounter any issues.