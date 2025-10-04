# Currency Conversion Utilities
# Handles exchange rate fetching and currency conversions

#' Fetch current USD to PHP exchange rate from API
#' @return Numeric exchange rate (1 USD = X PHP)
fetch_exchange_rate <- function() {
  tryCatch(
    {
      # Using exchangerate-api.com (free tier: 1500 requests/month)
      url <- "https://api.exchangerate-api.com/v4/latest/USD"

      response <- GET(url)

      if (status_code(response) == 200) {
        data <- content(response, as = "parsed")
        rate <- data$rates$PHP

        message(paste("Fetched exchange rate: 1 USD =", rate, "PHP"))
        return(rate)
      } else {
        warning("Failed to fetch exchange rate, using default: 58")
        return(58)  # Fallback rate
      }
    },
    error = function(e) {
      warning(paste("Error fetching exchange rate:", e$message, "- using default: 58"))
      return(58)  # Fallback rate
    }
  )
}

#' Convert amount from one currency to another
#' @param amount Numeric amount to convert
#' @param from_currency Source currency ("USD" or "PHP")
#' @param to_currency Target currency ("USD" or "PHP")
#' @param exchange_rate Exchange rate (1 USD = X PHP)
#' @return Numeric converted amount
convert_currency <- function(amount, from_currency, to_currency, exchange_rate) {
  if (from_currency == to_currency) {
    return(amount)
  }

  if (from_currency == "USD" && to_currency == "PHP") {
    return(amount * exchange_rate)
  } else if (from_currency == "PHP" && to_currency == "USD") {
    return(amount / exchange_rate)
  } else {
    warning("Unsupported currency conversion")
    return(amount)
  }
}

#' Format currency amount with symbol (vectorized)
#' @param amount Numeric amount (can be vector)
#' @param currency Currency code ("USD" or "PHP") (can be vector)
#' @return Formatted string with currency symbol (vector if inputs are vectors)
format_currency_display <- function(amount, currency) {
  # Handle NA/NaN values
  if (length(amount) == 0) return(character(0))

  # Ensure amount is numeric
  amount <- as.numeric(amount)

  # Vectorized version using ifelse
  symbol <- ifelse(currency == "USD", "$", "₱")
  formatted_amount <- formatC(amount, format = "f", big.mark = ",", digits = 2)
  return(paste0(symbol, formatted_amount))
}

#' Convert project amounts to display currency
#' @param projects Dataframe of projects with budget, amount_paid, and currency columns
#' @param display_currency Target currency ("USD" or "PHP")
#' @param exchange_rate Current exchange rate (1 USD = X PHP)
#' @return Dataframe with budget and amount_paid converted to display currency
convert_projects_to_display_currency <- function(projects, display_currency, exchange_rate = 58) {
  # If no projects, return empty dataframe
  if (nrow(projects) == 0) return(projects)

  # Convert budget and amount_paid to display currency
  projects %>%
    mutate(
      budget = case_when(
        currency == display_currency ~ budget,
        display_currency == "USD" ~ budget / exchange_rate,  # Convert PHP to USD
        display_currency == "PHP" ~ budget * exchange_rate   # Convert USD to PHP
      ),
      amount_paid = case_when(
        is.na(amount_paid) ~ NA_real_,  # Preserve NA values
        currency == display_currency ~ amount_paid,
        display_currency == "USD" ~ amount_paid / exchange_rate,  # Convert PHP to USD
        display_currency == "PHP" ~ amount_paid * exchange_rate   # Convert USD to PHP
      )
    )
}

#' Get latest exchange rate from payments or fetch new one
#' @param payments_data Dataframe of payments (optional)
#' @return Numeric exchange rate
get_latest_exchange_rate <- function(payments_data = NULL) {
  # Try to get most recent exchange rate from payments
  if (!is.null(payments_data) && nrow(payments_data) > 0) {
    latest_rate <- payments_data %>%
      arrange(desc(payment_date)) %>%
      filter(!is.na(exchange_rate)) %>%
      head(1) %>%
      pull(exchange_rate)

    if (length(latest_rate) > 0 && !is.na(latest_rate)) {
      return(latest_rate)
    }
  }

  # Otherwise fetch from API
  return(fetch_exchange_rate())
}
