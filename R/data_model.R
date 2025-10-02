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
      status TEXT,
      description TEXT
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
      # Authenticate with specific email
      gs4_auth(
        email = "johnvincentland@gmail.com"
      )

      # Read the sheet
      projects <- read_sheet(GOOGLE_SHEET_ID, sheet = 1) %>%
        mutate(
          start_date = as.Date(start_date),
          deadline = as.Date(deadline),
          id = as.integer(id),
          budget = as.numeric(budget)
        )

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
      # Use same email for authentication
      gs4_auth(
        email = "johnvincentland@gmail.com"
      )

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
