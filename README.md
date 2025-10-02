# Digital Artist Dashboard

A comprehensive Shiny dashboard for digital artists to track projects, commissions, and performance metrics.

## Features

### 📊 Dashboard Tab
- **Statistics Cards**: Count of active projects, average age of current projects, oldest current project
- **Monthly Charts**:
  - Monthly new commissions (bar chart)
  - Monthly active commissions (bar chart)

### ➕ New Project Tab
- Easy-to-use form for inputting new projects
- Fields include: Project name, type, start date, deadline, budget, status, description
- Recent projects preview table

### 📋 Manage Projects Tab
- Interactive data table showing all projects
- In-line editing capabilities
- Full project management interface

## Installation & Setup

1. **Install R and RStudio** (if not already installed)

2. **Clone/Download** this project to your local machine

3. **Install Required Packages**:
   ```r
   # Option 1: Using renv (recommended)
   renv::restore()

   # Option 2: Manual installation
   install.packages(c(
     "shiny", "shinydashboard", "DT", "plotly",
     "dplyr", "lubridate", "purrr", "ggplot2"
   ))
   ```

4. **Run the Application**:
   ```r
   # In RStudio, open app.R and click "Run App"
   # Or from R console:
   shiny::runApp()
   ```

## Usage

### Adding New Projects
1. Navigate to the "New Project" tab
2. Fill in the project details
3. Click "Add Project"
4. View the project in the recent projects table

### Managing Existing Projects
1. Go to the "Manage Projects" tab
2. Click on any cell to edit project details
3. Changes are saved automatically

### Viewing Statistics
1. The "Dashboard" tab automatically updates with current statistics
2. Charts show trends over time for project activity

## Data Structure

Projects contain the following fields:
- **ID**: Unique identifier
- **Project Name**: Title of the project
- **Project Type**: Commission, Personal, Client Work, Portfolio
- **Start Date**: When the project began
- **Deadline**: Project completion deadline
- **Budget**: Project value in dollars
- **Status**: Active, Completed, On Hold, Cancelled
- **Description**: Detailed project description

## Customization

### Adding New Project Types
Edit the `project_types` vector in `data_model.R`:
```r
project_types <- c("Commission", "Personal", "Client Work", "Portfolio", "Your New Type")
```

### Modifying Charts
Charts are built using `plotly` and `ggplot2`. Customize them in the server section of `app.R`.

### Data Persistence
Currently uses sample data. To add persistence:
1. Uncomment the save/load functions in `data_model.R`
2. Add save operations after data modifications

## File Structure

```
digital_artist_dashboard/
├── app.R              # Main Shiny application
├── data_model.R       # Data functions and sample data
├── README.md          # This file
├── renv.lock          # Package dependencies
└── .Rprofile          # R environment setup
```

## Future Enhancements

- Data persistence to file/database
- Export functionality (CSV, PDF reports)
- Client management features
- Invoice generation
- Time tracking integration
- Advanced analytics and reporting
- Dark mode theme option

## Support

For issues or feature requests, please create an issue in the project repository.