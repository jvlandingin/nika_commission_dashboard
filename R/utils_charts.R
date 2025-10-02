# Chart Generation Functions
# Contains all logic for creating dashboard charts

#' Create monthly new commissions chart
#' @param data Projects dataframe
#' @param date_range Vector of two dates (start, end)
#' @return Plotly chart object
create_new_commissions_chart <- function(data, date_range) {
  monthly_new <- data %>%
    filter(start_date >= date_range[1] & start_date <= date_range[2]) %>%
    mutate(month = floor_date(start_date, "month")) %>%
    group_by(month) %>%
    summarise(count = n(), .groups = "drop") %>%
    arrange(month)

  p <- ggplot(monthly_new, aes(x = month, y = count)) +
    geom_col(fill = "steelblue") +
    labs(x = "Month", y = "New Projects", title = "") +
    theme_minimal()

  ggplotly(p)
}

#' Create monthly active commissions chart
#' @param data Projects dataframe
#' @param date_range Vector of two dates (start, end)
#' @return Plotly chart object
create_active_commissions_chart <- function(data, date_range) {
  # Calculate active projects per month within the date range
  all_months <- seq(
    from = floor_date(date_range[1], "month"),
    to = floor_date(date_range[2], "month"),
    by = "month"
  )

  monthly_active <- map_dfr(all_months, function(month) {
    active_count <- data %>%
      filter(
        start_date <= month,
        (is.na(deadline) | deadline >= month),
        status == "Active"
      ) %>%
      nrow()

    tibble(month = month, active_count = active_count)
  })

  p <- ggplot(monthly_active, aes(x = month, y = active_count)) +
    geom_col(fill = "darkgreen") +
    labs(x = "Month", y = "Active Projects", title = "") +
    theme_minimal()

  ggplotly(p)
}

#' Create monthly revenue chart
#' @param data Projects dataframe
#' @param date_range Vector of two dates (start, end)
#' @return Plotly chart object
create_monthly_revenue_chart <- function(data, date_range) {
  monthly_revenue <- data %>%
    filter(start_date >= date_range[1] & start_date <= date_range[2]) %>%
    mutate(month = floor_date(start_date, "month")) %>%
    group_by(month) %>%
    summarise(revenue = sum(budget, na.rm = TRUE), .groups = "drop") %>%
    arrange(month)

  p <- ggplot(monthly_revenue, aes(x = month, y = revenue)) +
    geom_col(fill = "#2ecc71") +
    labs(x = "Month", y = "Revenue (₱)", title = "") +
    scale_y_continuous(labels = scales::comma) +
    theme_minimal()

  ggplotly(p)
}

#' Create project status proportion pie chart
#' @param data Projects dataframe
#' @return Plotly chart object
create_status_pie_chart <- function(data) {
  status_counts <- data %>%
    group_by(status) %>%
    summarise(count = n(), .groups = "drop") %>%
    mutate(percentage = round(count / sum(count) * 100, 1))

  plot_ly(
    data = status_counts,
    labels = ~status,
    values = ~count,
    type = "pie",
    textposition = "inside",
    textinfo = "label+percent",
    marker = list(
      colors = c("#3498db", "#95a5a6", "#e74c3c", "#f39c12"),
      line = list(color = "#ffffff", width = 2)
    ),
    showlegend = TRUE
  ) %>%
    layout(
      title = "",
      margin = list(l = 20, r = 20, t = 20, b = 20)
    )
}
