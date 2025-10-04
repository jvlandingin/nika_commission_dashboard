# UI Definition
# Defines the user interface for the Digital Artist Dashboard

ui <- dashboardPage(
  dashboardHeader(title = "✨ Mga Komisyon ni Nika"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("New Project", tabName = "new_project", icon = icon("plus")),
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
    )
  ),

  dashboardBody(
    # Include custom CSS and meta tags for mobile
    tags$head(
      tags$title("Mga Komisyon ni Nika - Artist Dashboard"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"),
      tags$link(rel = "icon", type = "image/png", href = "favicon.png"),
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      # Auto-close sidebar after clicking menu item
      tags$script(HTML("
        $(document).ready(function() {
          // When a menu item is clicked, close the sidebar
          $('.sidebar-menu .treeview-menu li a, .sidebar-menu > li > a').on('click', function(e) {
            // Small delay to allow the tab to switch first
            setTimeout(function() {
              // Simulate clicking the toggle button to close sidebar
              if ($('.main-sidebar').is(':visible') &&
                  ($('body').hasClass('sidebar-open') || !$('body').hasClass('sidebar-collapse'))) {
                $('.sidebar-toggle').trigger('click');
              }
            }, 100);
          });
        });
      "))
    ),
    tabItems(
      # Dashboard tab
      tabItem(
        tabName = "dashboard",
        fluidRow(
          box(
            title = "Dashboard Filters",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(
                width = 6,
                dateRangeInput(
                  "date_range",
                  "Date Range:",
                  start = Sys.Date() - 365,
                  end = Sys.Date(),
                  max = Sys.Date()
                )
              ),
              column(
                width = 3,
                tags$label("Display Currency:"),
                tags$div(
                  style = "margin-top: 5px;",
                  radioButtons(
                    "display_currency",
                    label = NULL,
                    choices = c("USD" = "USD", "PHP" = "PHP"),
                    selected = "USD",
                    inline = TRUE
                  )
                )
              ),
              column(
                width = 3,
                tags$label(HTML("&nbsp;")),  # Spacer for alignment
                tags$div(
                  style = "margin-top: 5px;",
                  actionButton(
                    "refresh_dashboard",
                    label = "Refresh from Google Sheets",
                    icon = icon("sync"),
                    class = "btn btn-success btn-sm"
                  )
                )
              )
            )
          )
        ),
        fluidRow(
          valueBoxOutput("active_projects"),
          valueBoxOutput("avg_age"),
          valueBoxOutput("oldest_project")
        ),
        fluidRow(
          valueBoxOutput("total_revenue"),
          valueBoxOutput("completion_rate"),
          valueBoxOutput("avg_duration")
        ),
        fluidRow(
          box(
            title = "Monthly New Commissions",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            plotlyOutput("new_commissions_chart", height = "350px")
          ),
          box(
            title = "Monthly Active Commissions",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            plotlyOutput("active_commissions_chart", height = "350px")
          )
        ),
        fluidRow(
          box(
            title = "Monthly Revenue",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            plotlyOutput("monthly_revenue_chart", height = "350px")
          ),
          box(
            title = "Project Status Distribution",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            plotlyOutput("status_pie_chart", height = "350px")
          )
        )
      ),

      # New Project tab
      tabItem(
        tabName = "new_project",
        fluidRow(
          box(
            title = "Add New Project",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            textInput("project_name", "Project Name:", value = ""),
            selectInput(
              "project_type",
              "Project Type:",
              choices = PROJECT_TYPES
            ),
            dateInput("start_date", "Start Date:", value = Sys.Date()),
            dateInput("deadline", "Deadline:", value = Sys.Date() + 30),
            numericInput("budget", "Budget:", value = 0, min = 0),
            selectInput(
              "currency",
              "Currency:",
              choices = CURRENCIES,
              selected = "USD"
            ),
            selectInput(
              "status",
              "Status:",
              choices = PROJECT_STATUSES
            ),
            textAreaInput("description", "Description:", value = "", rows = 3),
            br(),
            actionButton("add_project", "Add Project", class = "btn-primary")
          )
        ),
        fluidRow(
          box(
            title = "Recent Projects",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("recent_projects")
          )
        )
      ),

      # Manage Projects tab
      tabItem(
        tabName = "manage_projects",
        fluidRow(
          box(
            title = "All Projects",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            tags$div(
              style = "margin-bottom: 10px;",
              tags$a(
                href = "https://docs.google.com/spreadsheets/d/1zN9mS178n5LZMJ6bEPmEnsMh1bPoQ6YhAY_HDzvuPhQ",
                target = "_blank",
                icon("external-link-alt"),
                "Open in Google Sheets",
                class = "btn btn-info btn-sm"
              ),
              actionButton(
                "refresh_data",
                label = "Refresh",
                icon = icon("sync"),
                class = "btn btn-success btn-sm",
                style = "margin-left: 10px;"
              ),
              actionButton(
                "delete_selected",
                label = "Delete Selected",
                icon = icon("trash"),
                class = "btn btn-danger btn-sm",
                style = "margin-left: 10px;"
              ),
              tags$span(
                style = "margin-left: 15px; color: #666; font-size: 12px;",
                tags$i(class = "fa fa-info-circle"),
                " Select rows and click Delete, or click any cell to edit. ",
                tags$strong("Project Type:"),
                " Commission, Personal, Client Work, Portfolio | ",
                tags$strong("Status:"),
                " Active, Completed, On Hold, Cancelled | ",
                tags$strong("Payment:"),
                " Paid, Partially Paid, Unpaid"
              )
            ),
            DT::dataTableOutput("all_projects")
          )
        )
      ),

      # Payment Records tab
      tabItem(
        tabName = "payment_records",
        fluidRow(
          box(
            title = "Record New Payment",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(
                width = 4,
                selectInput(
                  "payment_project",
                  "Project:",
                  choices = NULL
                )
              ),
              column(
                width = 2,
                numericInput(
                  "payment_amount",
                  "Amount:",
                  value = 0,
                  min = 0
                )
              ),
              column(
                width = 1,
                selectInput(
                  "payment_currency",
                  "Currency:",
                  choices = CURRENCIES,
                  selected = "USD"
                )
              ),
              column(
                width = 1,
                numericInput(
                  "payment_fee",
                  "Fee:",
                  value = 0,
                  min = 0,
                  step = 0.01
                )
              ),
              column(
                width = 2,
                dateInput(
                  "payment_date",
                  "Date:",
                  value = Sys.Date()
                )
              ),
              column(
                width = 2,
                selectInput(
                  "payment_method",
                  "Method:",
                  choices = PAYMENT_METHODS,
                  selected = "PayPal"
                )
              )
            ),
            fluidRow(
              column(
                width = 10,
                textAreaInput(
                  "payment_notes",
                  "Notes (optional):",
                  value = "",
                  rows = 2
                )
              ),
              column(
                width = 2,
                br(),
                actionButton(
                  "add_payment",
                  "Add Payment",
                  class = "btn-success btn-block",
                  style = "margin-top: 5px;"
                )
              )
            )
          )
        ),
        fluidRow(
          box(
            title = "Payment History",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            tags$div(
              style = "margin-bottom: 10px;",
              actionButton(
                "refresh_payments",
                label = "Refresh",
                icon = icon("sync"),
                class = "btn btn-success btn-sm"
              ),
              actionButton(
                "delete_selected_payments",
                label = "Delete Selected",
                icon = icon("trash"),
                class = "btn btn-danger btn-sm",
                style = "margin-left: 10px;"
              ),
              tags$span(
                style = "margin-left: 15px; color: #666; font-size: 12px;",
                tags$i(class = "fa fa-info-circle"),
                " Select rows and click Delete, or use Refresh to sync with Google Sheets"
              )
            ),
            DT::dataTableOutput("payments_table")
          )
        )
      )
    )
  )
)
