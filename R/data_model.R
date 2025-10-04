library(dplyr)
library(lubridate)
library(purrr)
library(ggplot2)
library(RSQLite)
library(DBI)
library(googlesheets4)

# Google Sheets configuration
GOOGLE_SHEET_ID <- "1zN9mS178n5LZMJ6bEPmEnsMh1bPoQ6YhAY_HDzvuPhQ"

# SQLite Database Functions ----

#' Get database connection
#' @return SQLite connection object
get_db_connection <- function() {
  # Create data directory if it doesn't exist
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  dbConnect(SQLite(), "data/projects.db")
}

#' Initialize SQLite database with schema
init_database <- function() {
  con <- get_db_connection()

  # Create projects table if it doesn't exist
  dbExecute(
    con,
    "
    CREATE TABLE IF NOT EXISTS projects (
      id INTEGER PRIMARY KEY,
      project_name TEXT NOT NULL,
      project_type TEXT,
      start_date TEXT,
      deadline TEXT,
      budget REAL,
      currency TEXT,
      status TEXT,
      payment_status TEXT,
      amount_paid REAL,
      description TEXT
    )
  "
  )

  # Create payments table if it doesn't exist
  dbExecute(
    con,
    "
    CREATE TABLE IF NOT EXISTS payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id INTEGER NOT NULL,
      payment_date TEXT NOT NULL,
      amount REAL NOT NULL,
      currency TEXT NOT NULL,
      exchange_rate REAL,
      payment_method TEXT,
      notes TEXT,
      FOREIGN KEY (project_id) REFERENCES projects(id)
    )
  "
  )

  dbDisconnect(con)
}

#' Load projects from SQLite database
#' @return Dataframe of projects
load_from_sqlite <- function() {
  con <- get_db_connection()

  if (dbExistsTable(con, "projects")) {
    projects <- dbReadTable(con, "projects") %>%
      mutate(
        start_date = as.Date(start_date),
        deadline = as.Date(deadline)
      )

    # Add payment_status column if it doesn't exist (for backwards compatibility)
    if (!"payment_status" %in% names(projects)) {
      projects <- projects %>%
        mutate(payment_status = "Unpaid")
    }

    # Add amount_paid column if it doesn't exist (for backwards compatibility)
    if (!"amount_paid" %in% names(projects)) {
      projects <- projects %>%
        mutate(amount_paid = 0)
    }

    # Add currency column if it doesn't exist (for backwards compatibility)
    if (!"currency" %in% names(projects)) {
      projects <- projects %>%
        mutate(currency = "USD")  # Default to USD
    }
  } else {
    projects <- data.frame()
  }

  dbDisconnect(con)
  return(projects)
}

#' Save projects to SQLite database
#' @param data Projects dataframe
save_to_sqlite <- function(data) {
  con <- get_db_connection()

  # Convert dates to character for SQLite storage
  data_to_save <- data %>%
    mutate(
      start_date = as.character(start_date),
      deadline = as.character(deadline)
    )

  # Replace entire table
  dbWriteTable(con, "projects", data_to_save, overwrite = TRUE)

  dbDisconnect(con)
}

# Google Sheets Functions ----

#' Load projects from Google Sheets
#' @return Dataframe of projects
load_from_google_sheets <- function() {
  tryCatch(
    {
      # Try service account from environment variable first (for deployment)
      service_account_json <- Sys.getenv("GS4_SERVICE_ACCOUNT")

      if (nzchar(service_account_json)) {
        # Write to temp file and authenticate
        temp_json <- tempfile(fileext = ".json")
        cat(service_account_json, file = temp_json)
        message("Using service account from environment variable")
        gs4_auth(path = temp_json)
        on.exit(unlink(temp_json))
      } else if (file.exists(".secrets/service-account.json")) {
        # Use local service account file (for local development)
        message("Using local service account file")
        gs4_auth(path = ".secrets/service-account.json")
      } else if (file.exists(".secrets/gs4-token.rds")) {
        # Use cached token (local development with personal account)
        message("Using cached token")
        gs4_auth(token = readRDS(".secrets/gs4-token.rds"))
      } else {
        # Last resort: try interactive auth (local development only)
        message("Using interactive auth with email")
        gs4_auth(email = "johnvincentland@gmail.com")
      }

      # Read the sheet
      projects <- read_sheet(GOOGLE_SHEET_ID, sheet = 1) %>%
        mutate(
          start_date = as.Date(start_date),
          deadline = as.Date(deadline),
          id = as.integer(id),
          budget = as.numeric(budget)
        )

      # Add payment_status column if it doesn't exist (for backwards compatibility)
      if (!"payment_status" %in% names(projects)) {
        projects <- projects %>%
          mutate(payment_status = "Unpaid")
      }

      # Add amount_paid column if it doesn't exist (for backwards compatibility)
      if (!"amount_paid" %in% names(projects)) {
        projects <- projects %>%
          mutate(amount_paid = 0)
      }

      # Add currency column if it doesn't exist (for backwards compatibility)
      if (!"currency" %in% names(projects)) {
        projects <- projects %>%
          mutate(currency = "USD")  # Default to USD
      }

      return(projects)
    },
    error = function(e) {
      message("Error loading from Google Sheets: ", e$message)
      return(NULL)
    }
  )
}

#' Save projects to Google Sheets
#' @param data Projects dataframe
save_to_google_sheets <- function(data) {
  tryCatch(
    {
      # Try service account from environment variable first (for deployment)
      service_account_json <- Sys.getenv("GS4_SERVICE_ACCOUNT")

      if (nzchar(service_account_json)) {
        # Write to temp file and authenticate
        temp_json <- tempfile(fileext = ".json")
        cat(service_account_json, file = temp_json)
        message("Using service account from environment variable")
        gs4_auth(path = temp_json)
        on.exit(unlink(temp_json))
      } else if (file.exists(".secrets/service-account.json")) {
        # Use local service account file (for local development)
        message("Using local service account file")
        gs4_auth(path = ".secrets/service-account.json")
      } else if (file.exists(".secrets/gs4-token.rds")) {
        # Use cached token (local development with personal account)
        message("Using cached token")
        gs4_auth(token = readRDS(".secrets/gs4-token.rds"))
      } else {
        # Last resort: try interactive auth (local development only)
        message("Using interactive auth with email")
        gs4_auth(email = "johnvincentland@gmail.com")
      }

      # Write to sheet (overwrite)
      sheet_write(data, ss = GOOGLE_SHEET_ID, sheet = 1)

      message("Successfully saved to Google Sheets")
      return(TRUE)
    },
    error = function(e) {
      message("Error saving to Google Sheets: ", e$message)
      return(FALSE)
    }
  )
}

# Main Data Functions ----

#' Load projects data (priority: Google Sheets > SQLite > Sample Data)
#' @return Dataframe of projects
load_projects_data <- function() {
  # Try Google Sheets first (persistent backend)
  projects <- load_from_google_sheets()

  if (!is.null(projects) && nrow(projects) > 0) {
    message("Loaded data from Google Sheets")
    # Also save to local SQLite for faster access
    save_to_sqlite(projects)
    return(projects)
  }

  # Try SQLite next
  init_database()
  projects <- load_from_sqlite()

  if (nrow(projects) > 0) {
    message("Loaded data from SQLite")
    return(projects)
  }

  # Fall back to sample data
  message("No existing data found. Loading sample data")
  sample_data <- load_sample_data()
  save_to_sqlite(sample_data)
  return(sample_data)
}

#' Save projects data to both SQLite and Google Sheets
#' @param data Projects dataframe
save_projects_data <- function(data) {
  # Save to SQLite (fast, local)
  save_to_sqlite(data)

  # Save to Google Sheets (persistent, cloud)
  save_to_google_sheets(data)
}

# Sample Data Generation ----

load_sample_data <- function() {
  set.seed(42)

  project_types <- c("Commission", "Personal", "Client Work", "Portfolio")
  statuses <- c("Active", "Completed", "On Hold")
  payment_statuses <- c("Paid", "Partially Paid", "Unpaid")

  # Generate sample projects spanning the last 12 months
  start_dates <- sample(
    seq(Sys.Date() - 365, Sys.Date(), by = "day"),
    25,
    replace = TRUE
  )

  sample_projects <- data.frame(
    id = 1:25,
    project_name = c(
      "Fantasy Portrait Commission",
      "Logo Design for Cafe",
      "Book Cover Illustration",
      "Wedding Portrait",
      "Digital Character Design",
      "Brand Identity Package",
      "Album Cover Art",
      "Website Banner Design",
      "Pet Portrait Commission",
      "Game Asset Creation",
      "Social Media Graphics",
      "Poster Design",
      "Personal Art Project",
      "Corporate Illustration",
      "T-Shirt Design",
      "Storyboard Creation",
      "Icon Set Design",
      "Magazine Illustration",
      "Event Flyer Design",
      "Product Packaging Design",
      "Mural Concept Art",
      "Animation Frame Design",
      "Business Card Design",
      "Children's Book Art",
      "Digital Painting Study"
    ),
    project_type = sample(project_types, 25, replace = TRUE),
    start_date = start_dates,
    deadline = start_dates + sample(7:90, 25, replace = TRUE),
    budget = sample(
      c(50, 100, 150, 200, 300, 500, 750, 1000, 1500, 2000),
      25,
      replace = TRUE
    ),
    status = sample(statuses, 25, replace = TRUE, prob = c(0.4, 0.5, 0.1)),
    payment_status = sample(payment_statuses, 25, replace = TRUE, prob = c(0.5, 0.2, 0.3)),
    currency = sample(c("USD", "PHP"), 25, replace = TRUE, prob = c(0.7, 0.3)),
    amount_paid = 0,
    description = c(
      "Detailed fantasy character portrait with magical elements",
      "Modern logo design for local coffee shop",
      "Science fiction book cover with spaceship theme",
      "Romantic wedding portrait in watercolor style",
      "Original character design for indie game",
      "Complete brand identity including logo and colors",
      "Abstract album cover for electronic music artist",
      "Hero banner for technology company website",
      "Realistic pet portrait in digital medium",
      "Game sprites and environmental assets",
      "Social media post templates and graphics",
      "Event poster with vintage aesthetic",
      "Personal exploration of abstract art techniques",
      "Technical illustration for corporate presentation",
      "Creative t-shirt design for fashion brand",
      "Detailed storyboard for commercial project",
      "Minimalist icon set for mobile application",
      "Editorial illustration for lifestyle magazine",
      "Promotional flyer for music festival",
      "Packaging design for artisanal food product",
      "Concept art for public mural installation",
      "Animation keyframes for short film",
      "Professional business card design",
      "Whimsical illustrations for children's story",
      "Digital painting practice and technique study"
    ),
    stringsAsFactors = FALSE
  )

  # Ensure some projects are definitely active and recent
  sample_projects$status[1:8] <- "Active"
  sample_projects$start_date[1:4] <- Sys.Date() - c(5, 15, 30, 45)

  return(sample_projects)
}
