# Project Structure

## Directory Layout

```
digital_artist_dashboard/
├── ui.R                       # UI definition (automatically loaded by Shiny)
├── server.R                   # Server logic (automatically loaded by Shiny)
├── global.R                   # Global configuration and package loading
├── R/                         # Business logic modules
│   ├── data_model.R          # Data loading and persistence functions
│   ├── utils_statistics.R    # Statistics calculation functions
│   └── utils_charts.R        # Chart generation functions
├── www/                       # Static assets (CSS, JS, images)
├── data/                      # Data storage directory
├── renv/                      # R package environment (renv)
├── README.md                  # Project documentation
└── STRUCTURE.md               # This file
```

## File Descriptions

### Core Application Files

-   **ui.R**: Complete UI definition using `shinydashboard` (automatically loaded by Shiny)
-   **server.R**: Server-side reactive logic (automatically loaded by Shiny)
-   **global.R**: Automatically loaded first; contains package loading, configuration, and sources utility files

### R/ Directory (Business Logic Modules)

#### UI Layer

-   **ui.R** (root): UI definition
    -   Dashboard tab (statistics cards and charts)
    -   New Project tab (input form)
    -   Manage Projects tab (data table)

#### Server Layer

-   **server.R** (root): Reactive logic
    -   Reactive data management
    -   ValueBox outputs (calls statistics functions)
    -   Chart outputs (calls chart functions)
    -   Event handlers (add project, table edits)

#### Business Logic

-   **R/utils_statistics.R**: Pure functions for calculations
    -   `calc_active_projects()` - Count active projects
    -   `calc_avg_age()` - Average age of active projects
    -   `calc_oldest_project()` - Age of oldest active project
    -   `calc_total_revenue()` - Sum of all budgets
    -   `calc_completion_rate()` - Percentage of completed projects
    -   `calc_avg_duration()` - Average project duration
    -   `format_currency()` - Currency formatting helper
-   **R/utils_charts.R**: Chart generation functions
    -   `create_new_commissions_chart()` - Monthly new projects chart
    -   `create_active_commissions_chart()` - Monthly active projects chart

#### Data Layer

-   **R/data_model.R**: Data management functions
    -   `load_sample_data()` - Generate sample project data
    -   `save_projects_data()` - Save to RDS file
    -   `load_projects_data()` - Load from RDS file

## Benefits of This Structure

### 1. **Separation of Concerns**

-   UI code is isolated from business logic
-   Server code focuses on reactive programming
-   Business logic can be tested independently

### 2. **Maintainability**

-   Easy to locate specific functionality
-   Clear file responsibilities
-   Reduced merge conflicts in team settings

### 3. **Reusability**

-   Statistics functions can be used elsewhere
-   Chart functions can be extended easily
-   UI components clearly defined

### 4. **Scalability**

-   Easy to add new tabs or features
-   Simple to add new statistics or charts
-   Room for future modules

### 5. **Testing**

-   Pure functions in `utils_*.R` are easily testable
-   Can mock data for testing business logic
-   Clear boundaries for unit tests

## Loading Order

When the app starts, Shiny automatically loads files in this order:

1.  **.Rprofile** (if exists) - activates renv
2.  **global.R** - loads packages and sources utilities
3.  **R/data_model.R** - sourced by global.R
4.  **R/utils_statistics.R** - sourced by global.R
5.  **R/utils_charts.R** - sourced by global.R
6.  **ui.R** - UI definition (automatically loaded by Shiny)
7.  **server.R** - Server logic (automatically loaded by Shiny)

## Future Enhancements

### Phase 2: Shiny Modules

Consider converting tabs into Shiny modules: - `R/mod_dashboard.R` - Dashboard module - `R/mod_new_project.R` - New project module - `R/mod_manage_projects.R` - Manage projects module

Benefits: - Complete encapsulation with namespacing - Reusable components - Even cleaner separation

### Phase 3: Additional Organization

-   `R/utils_validation.R` - Input validation functions
-   `R/utils_database.R` - Database connection functions
-   `www/custom.css` - Custom styling
-   `tests/` - Unit tests for utility functions

## Best Practices

1.  **Use standard Shiny structure** - `ui.R`, `server.R`, `global.R` in root for automatic loading
2.  **Use global.R for setup** - Package loading, configuration, sourcing utilities
3.  **Pure functions in utils** - No reactive code, easy to test
4.  **Document functions** - Use roxygen-style comments
5.  **Consistent naming** - Prefixes like `calc_`, `create_`, `format_`