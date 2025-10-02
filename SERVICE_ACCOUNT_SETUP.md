# Google Service Account Setup Guide

This guide will help you set up a Google Service Account for secure authentication with Google Sheets on shinyapps.io.

## Why Use a Service Account?

✅ **Secure** - No need to make sheet public
✅ **No token expiration** - Works permanently
✅ **Best for deployment** - Recommended for shinyapps.io
✅ **No manual re-authentication** - Set it and forget it

## Step-by-Step Instructions

### Step 1: Create a Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Click **"Select a project"** → **"New Project"**
3. Name it something like "Nika Commission Dashboard"
4. Click **"Create"**
5. Wait for the project to be created (should take a few seconds)

### Step 2: Enable Google Sheets API

1. In your new project, go to **"APIs & Services"** → **"Library"**
2. Search for **"Google Sheets API"**
3. Click on it
4. Click **"Enable"**

### Step 3: Create Service Account

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"Service Account"**
3. Enter details:
   - **Service account name:** `nika-dashboard` (or any name you like)
   - **Service account ID:** Will auto-fill
   - **Description:** "Service account for Nika Commission Dashboard"
4. Click **"Create and Continue"**
5. **Grant this service account access to project:** Skip this (click "Continue")
6. **Grant users access to this service account:** Skip this (click "Done")

### Step 4: Create and Download JSON Key

1. In the **Credentials** page, find your service account in the list
2. Click on the service account email (looks like: `nika-dashboard@project-name.iam.gserviceaccount.com`)
3. Go to the **"Keys"** tab
4. Click **"Add Key"** → **"Create new key"**
5. Choose **"JSON"**
6. Click **"Create"**
7. A JSON file will download automatically
8. **IMPORTANT:** Save this file securely - you'll need it for deployment

### Step 5: Share Your Google Sheet with Service Account

1. Open your Google Sheet: https://docs.google.com/spreadsheets/d/1zN9mS178n5LZMJ6bEPmEnsMh1bPoQ6YhAY_HDzvuPhQ
2. Click **"Share"** button
3. Copy the **service account email** from the JSON file (it's in the `client_email` field)
   - Should look like: `nika-dashboard@project-name.iam.gserviceaccount.com`
4. Paste it into the "Add people and groups" field
5. Set permission to **"Editor"**
6. **Uncheck** "Notify people" (it's a robot, not a person!)
7. Click **"Share"**

✅ Your service account now has access to edit the sheet!

### Step 6: Prepare the JSON Key File for Deployment

1. Rename the downloaded JSON file to something simple like: `service-account.json`
2. Move it to your project directory:
   ```
   digital_artist_dashboard/
   ├── service-account.json  # <-- Put it here
   ├── ui.R
   ├── server.R
   └── ...
   ```
3. **IMPORTANT:** Never commit this file to git (it's already in .gitignore)

### Step 7: Update Your Code

The code has already been updated to detect and use the service account if available.

### Step 8: Test Locally

Test that it works on your local machine:

```r
# Run the app
shiny::runApp()

# If it works locally, you should see in the console:
# "Using service account authentication"
# "Loaded data from Google Sheets"
```

### Step 9: Deploy to shinyapps.io

Deploy with the service account file:

```r
rsconnect::deployApp(
  appName = "nika-commissions",
  appFiles = c(
    "ui.R",
    "server.R",
    "global.R",
    "R/",
    "www/",
    "service-account.json",  # Include the service account
    ".Rprofile",
    "renv.lock"
  )
)
```

## Security Notes

⚠️ **Keep the JSON file secure:**
- Never commit to git (already in .gitignore)
- Never share publicly
- This file gives full access to your Google account resources

✅ **The service account only has access to:**
- The specific Google Sheet you shared with it
- Nothing else in your Google account

## Troubleshooting

### Error: "service-account.json not found"

Make sure the file is in your project root directory and named exactly `service-account.json`.

### Error: "The caller does not have permission"

Make sure you've shared the Google Sheet with the service account email address (from the JSON file's `client_email` field).

### Error: "Invalid credentials"

The JSON file might be corrupted. Download a fresh key from Google Cloud Console.

## Alternative: Environment Variable (More Secure for shinyapps.io)

Instead of including the JSON file, you can use an environment variable:

1. In shinyapps.io dashboard, go to your app settings
2. Add environment variable: `GOOGLE_APPLICATION_CREDENTIALS_JSON`
3. Paste the entire contents of the JSON file as the value
4. Update code to read from environment variable

This is more secure as the credentials aren't in your deployed files.

## Summary

Once set up, you get:
- ✅ Secure authentication (sheet stays private)
- ✅ No token expiration issues
- ✅ Works indefinitely on shinyapps.io
- ✅ No need to re-deploy for auth issues

The one-time setup is worth it for a production deployment!
