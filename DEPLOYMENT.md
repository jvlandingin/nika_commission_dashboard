# Deployment Guide - shinyapps.io

This guide will help you deploy your Digital Artist Dashboard to shinyapps.io.

## Pre-Deployment Checklist

### ✅ Required Packages

Make sure all packages are installed and captured in `renv.lock`:

```r
# Install rsconnect for deployment
install.packages("rsconnect")

# Snapshot current environment
renv::snapshot()
```

**Packages used in this app:**
- shiny
- shinydashboard
- DT
- plotly
- dplyr
- lubridate
- purrr
- ggplot2
- RSQLite
- DBI
- googlesheets4
- gargle

### ✅ Google Sheets Authentication

**IMPORTANT:** For deployment, you need to handle authentication differently than local development.

**Option 1: Use a Service Account (Recommended for Production)**

1. Create a Google Cloud Project
2. Enable Google Sheets API
3. Create a Service Account
4. Download the JSON key file
5. Share your Google Sheet with the service account email
6. Update `R/data_model.R` to use service account:

```r
# In load_from_google_sheets() and save_to_google_sheets()
gs4_auth(path = "path/to/service-account-key.json")
```

**Option 2: Use Cached Token (Simpler but less secure)**

1. Authenticate locally first to create token:
   ```r
   googlesheets4::gs4_auth(email = "johnvincentland@gmail.com")
   ```

2. This creates a token in `.secrets/` folder

3. Deploy the `.secrets/` folder with your app (add to deployment)

**Option 3: Make Sheet Public (Easiest but Less Secure)**

1. Make your Google Sheet public (Anyone with link can edit)
2. Update `R/data_model.R` to use `gs4_deauth()` instead of `gs4_auth()`
3. **WARNING:** Anyone with the sheet ID can edit your data!

## Deployment Steps

### Step 1: Set up shinyapps.io Account

1. Go to https://www.shinyapps.io/
2. Sign up for a free account
3. Note your account name

### Step 2: Configure rsconnect

In R console:

```r
library(rsconnect)

# Replace with your account details
rsconnect::setAccountInfo(
  name = "your-account-name",
  token = "your-token",
  secret = "your-secret"
)
```

You can find your token and secret in shinyapps.io under:
**Account > Tokens > Show > Show Secret**

### Step 3: Update renv Snapshot

Make sure all packages are captured:

```r
# Update renv
renv::snapshot()
```

### Step 4: Test Locally One More Time

```r
# Run the app
shiny::runApp()

# Test all features:
# - Dashboard loads
# - Charts display
# - Add new project
# - Edit project in Manage Projects
# - Refresh from Google Sheets
```

### Step 5: Deploy!

```r
library(rsconnect)

# Deploy the app
rsconnect::deployApp(
  appName = "nika-commission-dashboard",  # Choose your app name
  account = "your-account-name"
)
```

### Step 6: First Run Setup

After deployment:

1. Open your app URL (provided after deployment)
2. If using cached token: First load might require re-authentication
3. Test all functionality
4. Check Google Sheets sync is working

## Post-Deployment

### Monitor Your App

Visit shinyapps.io dashboard to:
- View app logs
- Monitor usage
- Restart app if needed

### Update Your App

When you make changes:

```r
# Update renv if packages changed
renv::snapshot()

# Re-deploy
rsconnect::deployApp()
```

### Free Tier Limits

shinyapps.io free tier includes:
- 25 active hours per month
- 5 applications
- 1 GB RAM
- App goes to sleep after inactivity (wakes up when accessed)

## Troubleshooting

### "Package not found" Error

```r
# Make sure package is in renv
renv::snapshot()

# Re-deploy
rsconnect::deployApp()
```

### Authentication Error

- Check Google Sheets authentication method
- Verify service account has access to sheet
- Check token is included in deployment

### App Crashes on Startup

- Check logs in shinyapps.io dashboard
- Look for missing packages or authentication issues
- Test locally first with same authentication method

### Data Not Persisting

- Google Sheets is your persistent backend
- SQLite database is ephemeral on shinyapps.io (resets on app restart)
- Make sure Google Sheets sync is working

## Files to Deploy

These files will be automatically included:
- `ui.R`
- `server.R`
- `global.R`
- `R/` directory (all R files)
- `www/` directory (CSS, images)
- `renv.lock`
- `.Rprofile`

**Optional (if using cached auth):**
- `.secrets/` directory

**Do NOT deploy:**
- `data/` directory (SQLite is temporary)
- `.git/` directory
- `renv/library/` (will be rebuilt on server)

## Your App Configuration

- **App Name:** Choose a unique name (e.g., "nika-commissions")
- **Google Sheet ID:** 1zN9mS178n5LZMJ6bEPmEnsMh1bPoQ6YhAY_HDzvuPhQ
- **Authenticated Email:** johnvincentland@gmail.com

## Need Help?

- shinyapps.io Documentation: https://docs.rstudio.com/shinyapps.io/
- Google Sheets API: https://googlesheets4.tidyverse.org/
- R Shiny: https://shiny.rstudio.com/

Good luck with your deployment! 🚀
