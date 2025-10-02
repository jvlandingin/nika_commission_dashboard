# Statistics Calculation Functions
# Contains all business logic for calculating dashboard statistics

#' Calculate the count of active projects
#' @param data Projects dataframe
#' @return Integer count of active projects
calc_active_projects <- function(data) {
  data %>%
    filter(status == "Active") %>%
    nrow()
}

#' Calculate average age of active projects in days
#' @param data Projects dataframe
#' @return Numeric average age in days
calc_avg_age <- function(data) {
  avg_age <- data %>%
    filter(status == "Active") %>%
    mutate(age_days = as.numeric(Sys.Date() - start_date)) %>%
    summarise(avg = round(mean(age_days, na.rm = TRUE), 1)) %>%
    pull(avg)

  if (is.na(avg_age)) avg_age <- 0
  return(avg_age)
}

#' Calculate age of oldest active project
#' @param data Projects dataframe
#' @return Numeric age in days of oldest project
calc_oldest_project <- function(data) {
  oldest <- data %>%
    filter(status == "Active") %>%
    mutate(age_days = as.numeric(Sys.Date() - start_date)) %>%
    arrange(desc(age_days)) %>%
    slice(1) %>%
    pull(age_days)

  if (length(oldest) == 0) oldest <- 0
  return(oldest)
}

#' Calculate total received revenue (actual amount paid)
#' @param data Projects dataframe
#' @return Numeric total received revenue
calc_total_revenue <- function(data) {
  data %>%
    summarise(total = sum(amount_paid, na.rm = TRUE)) %>%
    pull(total)
}

#' Calculate project completion rate as percentage
#' @param data Projects dataframe
#' @return Numeric completion rate percentage
calc_completion_rate <- function(data) {
  total_projects <- nrow(data)
  completed_projects <- data %>%
    filter(status == "Completed") %>%
    nrow()

  rate <- if (total_projects > 0) {
    round((completed_projects / total_projects) * 100, 1)
  } else {
    0
  }

  return(rate)
}

#' Calculate average project duration for completed projects
#' @param data Projects dataframe
#' @return Numeric average duration in days
calc_avg_duration <- function(data) {
  avg_duration <- data %>%
    filter(status == "Completed") %>%
    mutate(duration = as.numeric(deadline - start_date)) %>%
    summarise(avg = round(mean(duration, na.rm = TRUE), 1)) %>%
    pull(avg)

  if (is.na(avg_duration)) avg_duration <- 0
  return(avg_duration)
}

#' Format currency for display (Philippine Pesos)
#' @param amount Numeric amount
#' @return Character formatted currency string
format_currency <- function(amount) {
  paste0("₱", formatC(amount, format = "f", big.mark = ",", digits = 0))
}
