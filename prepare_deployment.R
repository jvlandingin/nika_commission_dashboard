# Deployment Preparation Script
# Run this before deploying to shinyapps.io

cat("=== Digital Artist Dashboard - Deployment Preparation ===\n\n")

# 1. Check required packages
cat("1. Checking required packages...\n")
required_packages <- c(
  "shiny", "shinydashboard", "DT", "plotly",
  "dplyr", "lubridate", "purrr", "ggplot2",
  "RSQLite", "DBI", "googlesheets4", "gargle",
  "rsconnect"
)

missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]

if (length(missing_packages) > 0) {
  cat("   Missing packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("   Installing missing packages...\n")
  install.packages(missing_packages)
} else {
  cat("   ✓ All required packages installed\n")
}

# 2. Update renv snapshot
cat("\n2. Updating renv snapshot...\n")
if (require(renv, quietly = TRUE)) {
  renv::snapshot(prompt = FALSE)
  cat("   ✓ renv.lock updated\n")
} else {
  cat("   ⚠ renv not installed. Install with: install.packages('renv')\n")
}

# 3. Check Google Sheets authentication
cat("\n3. Checking Google Sheets authentication...\n")
cat("   Current method: Email authentication (johnvincentland@gmail.com)\n")
cat("   Authentication cache: .secrets/ folder\n")

if (dir.exists(".secrets")) {
  cat("   ✓ .secrets/ folder exists\n")

  # Check if token exists
  token_files <- list.files(".secrets", pattern = "*.rds", full.names = TRUE)
  if (length(token_files) > 0) {
    cat("   ✓ Authentication token found\n")
    cat("\n   DEPLOYMENT OPTION 1 (Current setup):\n")
    cat("   - Deploy with .secrets/ folder included\n")
    cat("   - Works for personal use\n")
    cat("   - Token may expire after 7 days\n")
  } else {
    cat("   ⚠ No token found. Run the app locally first to authenticate.\n")
  }
} else {
  cat("   ⚠ .secrets/ folder not found. Run the app locally first.\n")
}

cat("\n   DEPLOYMENT OPTION 2 (Recommended for production):\n")
cat("   - Use a Google Service Account\n")
cat("   - See DEPLOYMENT.md for instructions\n")

# 4. Check files for deployment
cat("\n4. Checking deployment files...\n")

essential_files <- c("ui.R", "server.R", "global.R", "renv.lock", ".Rprofile")
for (file in essential_files) {
  if (file.exists(file)) {
    cat("   ✓", file, "\n")
  } else {
    cat("   ✗", file, "MISSING!\n")
  }
}

# Check R/ directory
if (dir.exists("R")) {
  r_files <- list.files("R", pattern = "\\.R$")
  cat("   ✓ R/ directory (", length(r_files), "files)\n", sep = "")
} else {
  cat("   ✗ R/ directory MISSING!\n")
}

# Check www/ directory
if (dir.exists("www")) {
  www_files <- list.files("www")
  cat("   ✓ www/ directory (", length(www_files), "files)\n", sep = "")
} else {
  cat("   ⚠ www/ directory not found (optional)\n")
}

# 5. Test local deployment
cat("\n5. Testing local app...\n")
cat("   Run this command to test: shiny::runApp()\n")

# 6. Ready to deploy?
cat("\n=== DEPLOYMENT CHECKLIST ===\n")
cat("[ ] All required packages installed\n")
cat("[ ] renv.lock updated\n")
cat("[ ] Google Sheets authentication configured\n")
cat("[ ] App tested locally\n")
cat("[ ] shinyapps.io account created\n")
cat("[ ] rsconnect configured with account tokens\n")

cat("\n=== NEXT STEPS ===\n")
cat("1. Install rsconnect if needed:\n")
cat("   install.packages('rsconnect')\n\n")

cat("2. Configure your shinyapps.io account:\n")
cat("   library(rsconnect)\n")
cat("   rsconnect::setAccountInfo(name='ACCOUNT', token='TOKEN', secret='SECRET')\n\n")

cat("3. Deploy the app:\n")
cat("   rsconnect::deployApp(appName='nika-commissions')\n\n")

cat("📖 See DEPLOYMENT.md for detailed instructions!\n")
