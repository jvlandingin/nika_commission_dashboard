# Payment Data Model
# Handles loading/saving payment records

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

  # Replace entire table
  dbWriteTable(con, "payments", data_to_save, overwrite = TRUE)

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
      payments_raw <- read_sheet(GOOGLE_SHEET_ID, sheet = "Payments")

      # Handle empty sheet (user deleted all rows)
      if (nrow(payments_raw) == 0) {
        return(data.frame(
          id = integer(),
          project_id = integer(),
          payment_date = as.Date(character()),
          amount = numeric(),
          currency = character(),
          exchange_rate = numeric(),
          fee = numeric(),
          payment_method = character(),
          notes = character(),
          stringsAsFactors = FALSE
        ))
      }

      # Convert types carefully, handling potential list columns from Google Sheets
      payments <- payments_raw %>%
        mutate(
          payment_date = as.Date(payment_date),
          id = as.integer(unlist(id)),
          project_id = as.integer(unlist(project_id)),
          amount = as.numeric(unlist(amount)),
          exchange_rate = as.numeric(unlist(exchange_rate)),
          fee = as.numeric(unlist(fee)),
          currency = as.character(unlist(currency)),
          payment_method = as.character(unlist(payment_method)),
          notes = as.character(unlist(notes))
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

      # Write to sheet (overwrite entire sheet)
      sheet_write(data, ss = GOOGLE_SHEET_ID, sheet = "Payments")

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
    fee = numeric(),
    payment_method = character(),
    notes = character(),
    stringsAsFactors = FALSE
  ))
}

#' Save payments data to both SQLite and Google Sheets
#' @param data Payments dataframe
save_payments_data <- function(data) {
  # Save to SQLite (fast, local)
  save_payments_to_sqlite(data)

  # Save to Google Sheets (persistent, cloud)
  save_payments_to_google_sheets(data)
}
