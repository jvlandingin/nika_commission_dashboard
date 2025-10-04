# Global configuration and package loading
# This file is automatically sourced before ui.R and server.R

# Load required packages
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(lubridate)
library(purrr)
library(ggplot2)
library(RSQLite)
library(DBI)
library(googlesheets4)
library(gargle)
library(httr)
library(jsonlite)

# Source all utility files
source("R/data_model.R")
source("R/payments_model.R")
source("R/utils_statistics.R")
source("R/utils_charts.R")
source("R/utils_currency.R")

# Global variables and configuration
PROJECT_TYPES <- c("Commission", "Personal", "Client Work", "Portfolio")
PROJECT_STATUSES <- c("Active", "Completed", "On Hold", "Cancelled")
PAYMENT_STATUSES <- c("Paid", "Partially Paid", "Unpaid")
CURRENCIES <- c("USD", "PHP")
PAYMENT_METHODS <- c("Cash", "Bank Transfer", "PayPal", "Wise", "Crypto", "Other")
DATA_FILE <- "data/projects_data.rds"