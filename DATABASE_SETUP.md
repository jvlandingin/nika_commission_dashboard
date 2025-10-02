# Database Setup Guide

This dashboard uses a dual-storage strategy for persistence:
- **SQLite** - Fast local database for development
- **Google Sheets** - Cloud persistence for deployment on shinyapps.io

## Storage Strategy

### Data Flow
1. **On app startup**: Loads from Google Sheets (if available) → Falls back to SQLite → Falls back to sample data
2. **On data changes**: Saves to both SQLite (fast) and Google Sheets (persistent)

### Why This Approach?
- **Local Development**: SQLite is fast and doesn't require internet
- **Production (shinyapps.io)**: Google Sheets survives app restarts (shinyapps.io has ephemeral filesystem)

## Setup Instructions

### 1. Install Required Packages

```r
# Install database packages
install.packages("RSQLite")
install.packages("DBI")
install.packages("googlesheets4")

# Or using renv
renv::install(c("RSQLite", "DBI", "googlesheets4"))
```

### 2. Google Sheets Setup

#### Option A: Public Sheet (Easiest for Testing)
1. Open your Google Sheet: https://docs.google.com/spreadsheets/d/1zN9mS178n5LZMJ6bEPmEnsMh1bPoQ6YhAY_HDzvuPhQ
2. Go to Share → Change to "Anyone with the link can view"
3. The app will use `gs4_deauth()` - no authentication needed

#### Option B: Private Sheet (Recommended for Production)
1. Keep your sheet private
2. Update `R/data_model.R`:
   ```r
   # Change gs4_deauth() to gs4_auth()
   gs4_auth()  # This will prompt for Google authentication
   ```
3. First time running the app:
   - You'll be prompted to authenticate with Google
   - Choose your Google account
   - Allow access to Google Sheets
   - Token will be cached for future use

#### Option C: Service Account (Best for shinyapps.io)
1. Create a Google Cloud project
2. Enable Google Sheets API
3. Create a service account and download JSON key
4. Share your Google Sheet with the service account email
5. Update `R/data_model.R`:
   ```r
   gs4_auth(path = "path/to/service-account-key.json")
   ```

### 3. Google Sheet Structure

Your sheet should have these columns (header row):
- `id` (integer)
- `project_name` (text)
- `project_type` (text)
- `start_date` (date: YYYY-MM-DD)
- `deadline` (date: YYYY-MM-DD)
- `budget` (number)
- `status` (text)
- `description` (text)

**Important**: Make sure the first sheet (Sheet1) is the one with your data.

### 4. Local SQLite Setup

The SQLite database is created automatically:
- Location: `data/projects.db`
- Created on first run
- Schema matches Google Sheets structure

No manual setup required!

## Testing the Database

### Test 1: Add a Project
1. Go to "New Project" tab
2. Add a test project
3. Check console for: "Successfully saved to Google Sheets"
4. Verify in your Google Sheet

### Test 2: Edit a Project
1. Go to "Manage Projects" tab
2. Click on any cell and edit
3. Check console for: "Successfully saved to Google Sheets"
4. Verify in your Google Sheet

### Test 3: Restart App
1. Stop the app
2. Restart it
3. Check console for: "Loaded data from Google Sheets"
4. Verify your changes persisted

## Troubleshooting

### Error: "Error loading from Google Sheets"
- Check internet connection
- Verify sheet ID is correct
- Check sheet permissions (public or authenticated)
- Look at R console for detailed error message

### Error: "Error saving to Google Sheets"
- Check internet connection
- Verify you have edit permissions
- If using service account, check it has edit access

### Data not persisting after app restart
- Check that Google Sheets integration is working
- Look for "Successfully saved to Google Sheets" in console
- Verify sheet ID matches your actual sheet

### Local development without internet
- The app will use SQLite only
- Data persists between sessions locally
- Google Sheets sync will fail silently
- When you get internet back, manually trigger a save

## Deploying to shinyapps.io

1. **Update renv snapshot**:
   ```r
   renv::snapshot()
   ```

2. **Choose authentication method**:
   - **Option A (Public)**: Use `gs4_deauth()` - no setup needed
   - **Option B (Service Account)**: Include service account JSON in deployment

3. **Deploy**:
   ```r
   rsconnect::deployApp()
   ```

4. **First run on shinyapps.io**:
   - Will load from Google Sheets
   - Creates local SQLite (temporary)
   - All changes save to Google Sheets

## Current Configuration

- **Google Sheet ID**: `1zN9mS178n5LZMJ6bEPmEnsMh1bPoQ6YhAY_HDzvuPhQ`
- **SQLite Path**: `data/projects.db`
- **Authentication**: `gs4_deauth()` (no auth, for public sheets)

## Switching Authentication Methods

To switch from public sheet to authenticated:

1. Open `R/data_model.R`
2. Find both `load_from_google_sheets()` and `save_to_google_sheets()`
3. Replace `gs4_deauth()` with `gs4_auth()`
4. Restart the app
5. Follow authentication prompts

## Data Backup

Since Google Sheets is your persistent backend:
1. Your data is automatically backed up by Google
2. You can manually download the sheet as Excel/CSV
3. SQLite database is a local cache (not the source of truth)
