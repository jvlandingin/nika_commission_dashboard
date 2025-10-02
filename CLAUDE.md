# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R Shiny dashboard application for digital artists to track projects, commissions, and performance metrics. It uses `shinydashboard` for UI and follows a modular architecture pattern.

## Running the Application

```r
# Install dependencies (first time only)
renv::restore()

# Run the app (from project root)
shiny::runApp()

# Or in RStudio: open ui.R or server.R and click "Run App"
```

## Architecture

### Modular Structure

The codebase follows a **layered modular architecture** using the standard Shiny `ui.R`/`server.R` pattern:

**Loading Order (automatic by Shiny):**
1. `global.R` - Automatically sourced first by Shiny
2. `R/data_model.R`, `R/utils_statistics.R`, `R/utils_charts.R` - Sourced by global.R
3. `ui.R` - UI definition (in root directory)
4. `server.R` - Server logic (in root directory)

**Key Principle:** Shiny automatically finds and loads `global.R`, `ui.R`, and `server.R` from the root. All business logic is modularized in the `R/` directory.

### Layer Responsibilities

- **UI Layer** (`ui.R`): Pure UI definition, no logic. Uses global constants like `PROJECT_TYPES` and `PROJECT_STATUSES`.
- **Server Layer** (`server.R`): Reactive programming only. Delegates business logic to utility functions.
- **Business Logic** (`R/utils_*.R`): Pure functions with no reactivity. These are testable and reusable.
- **Data Layer** (`R/data_model.R`): Data loading/saving functions.

### Data Flow

```
User Input → Server (reactive) → Utils (pure functions) → Server (reactive) → UI Output
```

Example: Statistics calculation
1. Server: `projects_data()` (reactive)
2. Utils: `calc_active_projects(data)` (pure function)
3. Server: `renderValueBox()` (reactive)
4. UI: `valueBoxOutput()` (display)

## Project Data Model

Projects are stored as dataframes with these fields:
- `id`, `project_name`, `project_type`, `start_date`, `deadline`, `budget`, `status`, `description`

**Project Types:** Commission, Personal, Client Work, Portfolio (defined in `global.R`)
**Project Statuses:** Active, Completed, On Hold, Cancelled (defined in `global.R`)

Currently uses sample data. Persistence functions exist in `R/data_model.R` but are not yet wired up to save automatically.

## Adding Features

### New Statistics Card

1. Add calculation function to `R/utils_statistics.R` (pure function with roxygen docs)
2. Add `valueBoxOutput()` to `ui.R`
3. Add `renderValueBox()` to `server.R` that calls your calculation function
4. Follow naming convention: `calc_*` for calculation functions

### New Chart

1. Add chart function to `R/utils_charts.R` (accepts data and returns plotly object)
2. Add `plotlyOutput()` to `ui.R`
3. Add `renderPlotly()` to `server.R` that calls your chart function
4. Follow naming convention: `create_*_chart` for chart functions

### New Tab

1. Add `menuItem()` to sidebar in `ui.R`
2. Add `tabItem()` to dashboardBody in `ui.R`
3. Add server logic to `server.R`
4. Consider converting to Shiny module if tab becomes complex (see STRUCTURE.md Phase 2)

### Modifying Project Types/Statuses

Edit the constants in `global.R`:
```r
PROJECT_TYPES <- c("Commission", "Personal", "Client Work", "Portfolio", "YourNewType")
PROJECT_STATUSES <- c("Active", "Completed", "On Hold", "Cancelled", "YourNewStatus")
```

These are automatically used by UI dropdowns and business logic.

## Code Conventions

- **Naming:** `calc_*` for calculations, `create_*` for charts, `format_*` for formatters
- **Documentation:** Use roxygen-style comments for all functions in utils files
- **Reactivity:** Keep reactive code in `R/server.R` only, never in utils files
- **Constants:** Define in `global.R`, use throughout codebase
- **Pure functions:** All utils functions should be deterministic with no side effects

## Data Persistence (Not Yet Implemented)

The app currently uses sample data loaded on startup. To add persistence:

1. In `server.R`, replace `load_sample_data()` with `load_projects_data()` (from data_model.R)
2. Add `save_projects_data(projects_data())` after modifications (add project, edit table)
3. Data will be saved to `data/projects_data.rds`

## Package Management

This project uses `renv` for reproducible environments. The lockfile is tracked in version control.

- Install packages: `renv::install("package_name")`
- Update lockfile: `renv::snapshot()`
- Restore packages: `renv::restore()`
