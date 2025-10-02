# Server Logic
# Defines the server-side logic for the Digital Artist Dashboard

server <- function(input, output, session) {
  # Reactive data - Load from database
  projects_data <- reactiveVal(load_projects_data())

  # Refresh data from Google Sheets
  observeEvent(input$refresh_data, {
    showNotification(
      "Refreshing data from Google Sheets...",
      type = "message",
      duration = 2,
      id = "refresh_notification"
    )

    # Load fresh data from Google Sheets
    fresh_data <- load_from_google_sheets()

    if (!is.null(fresh_data) && nrow(fresh_data) > 0) {
      projects_data(fresh_data)
      # Also update local SQLite cache
      save_to_sqlite(fresh_data)

      showNotification(
        "Data refreshed successfully!",
        type = "message",
        duration = 3
      )
    } else {
      showNotification(
        "Failed to refresh data from Google Sheets",
        type = "error",
        duration = 5
      )
    }
  })

  # Filtered data based on date range
  filtered_data <- reactive({
    req(input$date_range)
    projects_data() %>%
      filter(start_date >= input$date_range[1] & start_date <= input$date_range[2])
  })

  # Dashboard statistics value boxes (filtered by date range)
  output$active_projects <- renderValueBox({
    active_count <- calc_active_projects(filtered_data())

    valueBox(
      value = active_count,
      subtitle = tags$span(
        "Active Projects ",
        tags$i(
          class = "fa fa-info-circle",
          style = "cursor: pointer;",
          title = "Count of projects with 'Active' status within the selected date range"
        )
      ),
      icon = icon("tasks"),
      color = "blue"
    )
  })

  output$avg_age <- renderValueBox({
    avg_age <- calc_avg_age(filtered_data())

    valueBox(
      value = paste(avg_age, "days"),
      subtitle = tags$span(
        "Avg. Age of Active Projects ",
        tags$i(
          class = "fa fa-info-circle",
          style = "cursor: pointer;",
          title = "Average number of days since active projects started (calculated from start_date to today)"
        )
      ),
      icon = icon("calendar"),
      color = "yellow"
    )
  })

  output$oldest_project <- renderValueBox({
    oldest <- calc_oldest_project(filtered_data())

    valueBox(
      value = paste(oldest, "days"),
      subtitle = tags$span(
        "Oldest Active Project ",
        tags$i(
          class = "fa fa-info-circle",
          style = "cursor: pointer;",
          title = "Number of days since the oldest active project started"
        )
      ),
      icon = icon("clock"),
      color = "red"
    )
  })

  output$total_revenue <- renderValueBox({
    total <- calc_total_revenue(filtered_data())

    valueBox(
      value = format_currency(total),
      subtitle = tags$span(
        "Total Revenue ",
        tags$i(
          class = "fa fa-info-circle",
          style = "cursor: pointer;",
          title = "Sum of all project budgets within the selected date range"
        )
      ),
      icon = icon("dollar-sign"),
      color = "green"
    )
  })

  output$completion_rate <- renderValueBox({
    rate <- calc_completion_rate(filtered_data())

    valueBox(
      value = paste0(rate, "%"),
      subtitle = tags$span(
        "Completion Rate ",
        tags$i(
          class = "fa fa-info-circle",
          style = "cursor: pointer;",
          title = "Percentage of projects with 'Completed' status out of all projects in the date range"
        )
      ),
      icon = icon("check-circle"),
      color = "purple"
    )
  })

  output$avg_duration <- renderValueBox({
    avg_duration <- calc_avg_duration(filtered_data())

    valueBox(
      value = paste(avg_duration, "days"),
      subtitle = tags$span(
        "Avg. Project Duration ",
        tags$i(
          class = "fa fa-info-circle",
          style = "cursor: pointer;",
          title = "Average duration between start_date and deadline for completed projects only"
        )
      ),
      icon = icon("hourglass-half"),
      color = "orange"
    )
  })

  # Charts (using filtered data)
  output$new_commissions_chart <- renderPlotly({
    req(input$date_range)
    create_new_commissions_chart(filtered_data(), input$date_range)
  })

  output$active_commissions_chart <- renderPlotly({
    req(input$date_range)
    create_active_commissions_chart(filtered_data(), input$date_range)
  })

  output$monthly_revenue_chart <- renderPlotly({
    req(input$date_range)
    create_monthly_revenue_chart(filtered_data(), input$date_range)
  })

  output$status_pie_chart <- renderPlotly({
    create_status_pie_chart(filtered_data())
  })

  # Add new project
  observeEvent(input$add_project, {
    new_project <- data.frame(
      id = max(projects_data()$id) + 1,
      project_name = input$project_name,
      project_type = input$project_type,
      start_date = input$start_date,
      deadline = input$deadline,
      budget = input$budget,
      status = input$status,
      description = input$description,
      stringsAsFactors = FALSE
    )

    updated_data <- rbind(projects_data(), new_project)
    projects_data(updated_data)

    # Save to database
    save_projects_data(updated_data)

    # Clear form
    updateTextInput(session, "project_name", value = "")
    updateTextAreaInput(session, "description", value = "")
    updateNumericInput(session, "budget", value = 0)

    showNotification(
      "Project added successfully!",
      type = "message",
      duration = 3
    )
  })

  # Recent projects table
  output$recent_projects <- DT::renderDataTable(
    {
      projects_data() %>%
        arrange(desc(start_date)) %>%
        head(5) %>%
        select(project_name, project_type, start_date, status, budget)
    },
    options = list(dom = 't', pageLength = 5)
  )

  # All projects table with editing
  output$all_projects <- DT::renderDataTable(
    {
      # Sort by most recent start_date first
      projects_data() %>%
        arrange(desc(start_date))
    },
    editable = list(
      target = 'cell',
      disable = list(columns = c(0))  # Disable editing ID column (0-indexed)
    ),
    filter = 'top',  # Add column filters at the top
    extensions = 'Buttons',
    options = list(
      pageLength = 10,
      scrollX = TRUE,
      dom = 'Bfrtip',
      buttons = list(
        list(extend = 'copy', text = 'Copy to Clipboard'),
        'csv',
        'excel'
      ),
      order = list(list(3, 'desc')),  # Default sort by start_date column (0-indexed) descending
      columnDefs = list(
        list(
          targets = 2,  # project_type column (0-indexed)
          className = 'dt-center'
        ),
        list(
          targets = 6,  # status column (0-indexed)
          className = 'dt-center'
        )
      )
    )
  )

  # Handle table edits in Manage Projects tab
  observeEvent(input$all_projects_cell_edit, {
    info <- input$all_projects_cell_edit

    # Get the full unfiltered data
    data <- projects_data()

    # Get the sorted/filtered data shown in the table
    displayed_data <- data %>% arrange(desc(start_date))

    # Get column name (DT uses 1-indexed for info$col)
    col_name <- names(displayed_data)[info$col]
    new_value <- info$value

    # Validate project_type and status columns
    if (col_name == "project_type") {
      if (!new_value %in% PROJECT_TYPES) {
        showNotification(
          paste0("Invalid project type! Must be one of: ", paste(PROJECT_TYPES, collapse = ", ")),
          type = "error",
          duration = 5
        )
        return()
      }
    } else if (col_name == "status") {
      if (!new_value %in% PROJECT_STATUSES) {
        showNotification(
          paste0("Invalid status! Must be one of: ", paste(PROJECT_STATUSES, collapse = ", ")),
          type = "error",
          duration = 5
        )
        return()
      }
    }

    # Update data with proper type conversion
    # DT returns all edits as characters, so we need to convert based on column type
    if (col_name == "id") {
      new_value <- as.integer(new_value)
    } else if (col_name == "start_date" || col_name == "deadline") {
      new_value <- as.Date(new_value)
    } else if (col_name == "budget") {
      new_value <- as.numeric(new_value)
    }

    # Get the ID of the row being edited (from displayed table)
    row_id <- displayed_data$id[info$row]

    # Find this row in the original data by ID and update it
    row_index_in_original <- which(data$id == row_id)
    data[row_index_in_original, col_name] <- new_value

    # Update reactive data
    projects_data(data)

    # Save to database
    save_result <- save_projects_data(data)

    showNotification(
      "Project updated successfully!",
      type = "message",
      duration = 3
    )
  })
}
