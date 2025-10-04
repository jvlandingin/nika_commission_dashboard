# Server Logic
# Defines the server-side logic for the Digital Artist Dashboard

server <- function(input, output, session) {
  # Reactive data - Load from database
  projects_data <- reactiveVal(load_projects_data())
  payments_data <- reactiveVal(load_payments_data())

  # Store selected rows for deletion
  rows_to_delete <- reactiveVal(NULL)

  # Refresh data from Google Sheets (Manage Projects tab)
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

  # Refresh data from Google Sheets (Dashboard tab)
  observeEvent(input$refresh_dashboard, {
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

  # Show confirmation modal when delete button is clicked
  observeEvent(input$delete_selected, {
    # Get selected rows from the table
    selected_rows <- input$all_projects_rows_selected

    if (is.null(selected_rows) || length(selected_rows) == 0) {
      showNotification(
        "Please select rows to delete",
        type = "warning",
        duration = 3
      )
      return()
    }

    # Store selected rows
    rows_to_delete(selected_rows)

    # Show modal
    showModal(modalDialog(
      title = "Confirm Delete",
      paste("Are you sure you want to delete", length(selected_rows), "project(s)?"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete", "Delete", class = "btn-danger")
      )
    ))
  })

  # Perform deletion when confirmed
  observeEvent(input$confirm_delete, {
    selected_rows <- rows_to_delete()

    if (!is.null(selected_rows)) {
      # Get the full data and displayed data
      data <- projects_data()
      displayed_data <- data %>% arrange(desc(start_date))

      # Get IDs of selected rows
      selected_ids <- displayed_data$id[selected_rows]

      # Remove selected rows
      updated_data <- data %>% filter(!id %in% selected_ids)

      # Update reactive data
      projects_data(updated_data)

      # Save to database
      save_projects_data(updated_data)

      showNotification(
        paste("Deleted", length(selected_ids), "project(s) successfully!"),
        type = "message",
        duration = 3
      )

      # Clear stored rows
      rows_to_delete(NULL)

      # Close modal
      removeModal()
    }
  })

  # Filtered data based on date range
  filtered_data <- reactive({
    req(input$date_range)
    projects_data() %>%
      filter(start_date >= input$date_range[1] & start_date <= input$date_range[2])
  })

  # Dashboard - Convert filtered data to display currency
  # Uses latest exchange rate from payments or fetches from API
  display_data <- reactive({
    req(input$display_currency)
    data <- filtered_data()

    # Get latest exchange rate
    exchange_rate <- get_latest_exchange_rate(payments_data())

    # Convert to display currency
    convert_projects_to_display_currency(data, input$display_currency, exchange_rate)
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
    # Calculate net revenue from payments (amount - fee) in display currency
    # Uses latest exchange rate for accurate conversion
    exchange_rate <- get_latest_exchange_rate(payments_data())
    total <- calc_net_revenue_from_payments(
      payments_data(),
      input$display_currency,
      exchange_rate
    )

    # Format with appropriate currency symbol based on display currency
    formatted_total <- format_currency_display(total, input$display_currency)

    valueBox(
      value = formatted_total,
      subtitle = tags$span(
        paste("Net Revenue Received (", input$display_currency, ")"),
        tags$i(
          class = "fa fa-info-circle",
          style = "cursor: pointer;",
          title = "Total net revenue received (payments minus fees), shown in selected display currency. This is what you actually received after payment processing fees."
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
      currency = input$currency,
      amount_paid = 0,  # Default to 0, will be updated when payments are added
      status = input$status,
      payment_status = "Unpaid",  # Default to Unpaid, will be auto-updated when payments are added
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
    options = list(
      dom = 't',
      pageLength = 5,
      scrollX = TRUE,
      autoWidth = FALSE
    )
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
    selection = 'multiple',  # Allow multiple row selection
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

    # Validate project_type, status, and payment_status columns
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
    } else if (col_name == "payment_status") {
      if (!new_value %in% PAYMENT_STATUSES) {
        showNotification(
          paste0("Invalid payment status! Must be one of: ", paste(PAYMENT_STATUSES, collapse = ", ")),
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
    } else if (col_name == "budget" || col_name == "amount_paid") {
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

  # Payment Records - Update project dropdown
  # Dynamically update the project selector in the payment form
  # Shows project name and currency (e.g., "Project A (USD)")
  observe({
    projects <- projects_data()
    project_choices <- setNames(
      projects$id,
      paste0(projects$project_name, " (", projects$currency, ")")
    )
    updateSelectInput(session, "payment_project", choices = project_choices)
  })

  # Payment Records - Refresh from Google Sheets
  # Syncs payment data from Google Sheets to local app
  # Handles empty sheets (when all payments are deleted)
  observeEvent(input$refresh_payments, {
    showNotification(
      "Refreshing payments from Google Sheets...",
      type = "message",
      duration = 2,
      id = "refresh_payments_notification"
    )

    fresh_payments <- load_payments_from_google_sheets()

    if (!is.null(fresh_payments)) {
      # Update even if empty (means user deleted all payments in Google Sheets)
      payments_data(fresh_payments)
      save_payments_to_sqlite(fresh_payments)

      showNotification(
        paste("Payments refreshed successfully!", nrow(fresh_payments), "payment(s) loaded"),
        type = "message",
        duration = 3
      )
    } else {
      showNotification(
        "Failed to refresh payments from Google Sheets",
        type = "error",
        duration = 5
      )
    }
  })

  # Payment Records - Add new payment
  # Records a payment for a project with automatic exchange rate fetching
  # Also auto-updates the project's amount_paid and payment_status fields
  observeEvent(input$add_payment, {
    # Validate inputs
    if (is.null(input$payment_project) || input$payment_amount <= 0) {
      showNotification(
        "Please select a project and enter a valid amount",
        type = "warning",
        duration = 3
      )
      return()
    }

    # Fetch current USD to PHP exchange rate from API
    exchange_rate <- fetch_exchange_rate()

    # Get current payments data
    payments <- payments_data()

    # Generate new payment ID (auto-increment)
    new_id <- ifelse(nrow(payments) == 0, 1, max(payments$id, na.rm = TRUE) + 1)

    # Create new payment record with all details
    new_payment <- data.frame(
      id = new_id,
      project_id = as.integer(input$payment_project),
      payment_date = input$payment_date,
      amount = input$payment_amount,
      currency = input$payment_currency,
      exchange_rate = exchange_rate,  # Store rate for historical accuracy
      fee = input$payment_fee,  # Fee deducted (e.g., PayPal fee)
      payment_method = input$payment_method,
      notes = input$payment_notes,
      stringsAsFactors = FALSE
    )

    # Add new payment to existing payments
    updated_payments <- rbind(payments, new_payment)
    payments_data(updated_payments)

    # Save to both Google Sheets and SQLite
    save_payments_data(updated_payments)

    # === Auto-update project's payment information ===
    projects <- projects_data()
    project_id <- as.integer(input$payment_project)

    # Get project details for currency conversion
    project_row <- projects[projects$id == project_id, ]
    project_currency <- project_row$currency
    project_budget <- project_row$budget

    # Calculate total amount paid for this project
    # Convert all payments to the project's currency for accurate totaling
    total_paid <- updated_payments %>%
      filter(project_id == !!project_id) %>%
      mutate(
        amount_in_project_currency = ifelse(
          currency == project_currency,
          amount,  # No conversion needed
          ifelse(
            project_currency == "USD",
            amount / exchange_rate,  # Convert PHP to USD
            amount * exchange_rate   # Convert USD to PHP
          )
        )
      ) %>%
      pull(amount_in_project_currency) %>%
      sum()

    # Update project's amount_paid field
    projects$amount_paid[projects$id == project_id] <- total_paid

    # Auto-update payment_status based on total paid vs budget
    if (total_paid >= project_budget) {
      projects$payment_status[projects$id == project_id] <- "Paid"
    } else if (total_paid > 0) {
      projects$payment_status[projects$id == project_id] <- "Partially Paid"
    } else {
      projects$payment_status[projects$id == project_id] <- "Unpaid"
    }

    # Save updated project data to both Google Sheets and SQLite
    projects_data(projects)
    save_projects_data(projects)

    # Clear form
    updateNumericInput(session, "payment_amount", value = 0)
    updateNumericInput(session, "payment_fee", value = 0)
    updateTextAreaInput(session, "payment_notes", value = "")

    showNotification(
      paste0(
        "Payment recorded successfully! Exchange rate: 1 USD = ",
        round(exchange_rate, 2), " PHP. Project updated: ",
        format_currency_display(total_paid, project_currency), " paid of ",
        format_currency_display(project_budget, project_currency)
      ),
      type = "message",
      duration = 5
    )
  })

  # Payment Records - Delete selected payments (show confirmation modal)
  # Shows a confirmation dialog before deleting selected payment records
  observeEvent(input$delete_selected_payments, {
    selected_rows <- input$payments_table_rows_selected

    if (is.null(selected_rows) || length(selected_rows) == 0) {
      showNotification(
        "Please select rows to delete",
        type = "warning",
        duration = 3
      )
      return()
    }

    # Store selected rows
    rows_to_delete(selected_rows)

    # Show modal
    showModal(modalDialog(
      title = "Confirm Delete",
      paste("Are you sure you want to delete", length(selected_rows), "payment(s)?"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete_payments", "Delete", class = "btn-danger")
      )
    ))
  })

  # Payment Records - Confirm and execute payment deletion
  # Deletes selected payment records from both Google Sheets and SQLite
  observeEvent(input$confirm_delete_payments, {
    selected_rows <- rows_to_delete()

    if (!is.null(selected_rows)) {
      payments <- payments_data()

      # Get displayed data (sorted by date descending)
      displayed_data <- payments %>%
        left_join(
          projects_data() %>% select(id, project_name),
          by = c("project_id" = "id")
        ) %>%
        arrange(desc(payment_date))

      # Get actual payment IDs to delete (accounting for table sorting)
      payment_ids_to_delete <- displayed_data$id[selected_rows]

      # Remove selected payments from dataset
      updated_payments <- payments %>% filter(!id %in% payment_ids_to_delete)

      # Update reactive value
      payments_data(updated_payments)

      # Save to both Google Sheets and SQLite
      save_payments_data(updated_payments)

      showNotification(
        paste("Deleted", length(payment_ids_to_delete), "payment(s) successfully!"),
        type = "message",
        duration = 3
      )

      # Clear stored rows
      rows_to_delete(NULL)

      # Close modal
      removeModal()
    }
  })

  # Payment Records - Payments table display
  # Shows all payment records with currency conversions
  # Displays both USD and PHP equivalents for each payment
  output$payments_table <- DT::renderDataTable(
    {
      payments <- payments_data()
      projects <- projects_data()

      if (nrow(payments) == 0) {
        return(data.frame(Message = "No payments recorded yet"))
      }

      # Join payments with projects to display project names
      payments %>%
        left_join(
          projects %>% select(id, project_name),
          by = c("project_id" = "id")
        ) %>%
        mutate(
          # Format gross amount with currency symbol ($100.00 or ₱5,800.00)
          amount_display = format_currency_display(amount, currency),
          # Format fee with currency symbol
          fee_display = format_currency_display(fee, currency),
          # Calculate net amount (what you actually received)
          net_amount = amount - fee,
          # Format net amount with currency symbol
          net_display = format_currency_display(net_amount, currency),
          # Calculate USD equivalent (no conversion if already USD)
          usd_equivalent = ifelse(
            currency == "USD",
            amount,
            amount / exchange_rate
          ),
          # Calculate PHP equivalent (no conversion if already PHP)
          php_equivalent = ifelse(
            currency == "PHP",
            amount,
            amount * exchange_rate
          )
        ) %>%
        select(
          ID = id,
          Project = project_name,
          Date = payment_date,
          Amount = amount_display,
          Fee = fee_display,
          `Net Received` = net_display,
          `USD Equiv.` = usd_equivalent,
          `PHP Equiv.` = php_equivalent,
          `Exch. Rate` = exchange_rate,
          Method = payment_method,
          Notes = notes
        ) %>%
        arrange(desc(Date))  # Sort by most recent first
    },
    filter = 'top',  # Column filters
    selection = 'multiple',  # Allow row selection for deletion
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
      order = list(list(2, 'desc')),  # Sort by date column (index 2, descending)
      columnDefs = list(
        list(
          # Apply JavaScript number formatter to USD and PHP equivalent columns
          targets = c(6, 7),  # Columns 6 and 7 (USD Equiv., PHP Equiv.) - 0-indexed
          render = JS(
            "function(data, type, row, meta) {",
            "  if (type === 'display') {",
            "    var num = parseFloat(data);",
            "    if (isNaN(num)) return data;",
            "    return '$' + num.toFixed(2).replace(/\\d(?=(\\d{3})+\\.)/g, '$&,');",
            "  }",
            "  return data;",
            "}"
          )
        )
      )
    )
  )
}
