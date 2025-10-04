# Documentation

This folder contains detailed documentation for the Digital Artist Dashboard application.

## Documentation Files

### User Guides

- **[MULTI_CURRENCY_PAYMENTS.md](MULTI_CURRENCY_PAYMENTS.md)** - Comprehensive guide to the multi-currency payment tracking system
  - Features overview
  - Usage instructions
  - Architecture details
  - Troubleshooting

### Implementation Guides

- **[PHASE1_IMPLEMENTATION_GUIDE.md](PHASE1_IMPLEMENTATION_GUIDE.md)** - Step-by-step implementation guide for Phase 1 (multi-currency payments)
  - Detailed implementation steps
  - Code snippets
  - Testing checklist

- **[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)** - Overall implementation plan for multi-currency features
  - Phase 1 and Phase 2 breakdown
  - Design decisions
  - Files to modify

### Setup Guides (Root Directory)

These setup guides remain in the root directory for easy access:

- **[DATABASE_SETUP.md](../DATABASE_SETUP.md)** - SQLite database setup
- **[SERVICE_ACCOUNT_SETUP.md](../SERVICE_ACCOUNT_SETUP.md)** - Google Sheets authentication
- **[DEPLOYMENT.md](../DEPLOYMENT.md)** - Deployment to shinyapps.io
- **[STRUCTURE.md](../STRUCTURE.md)** - Application architecture

### Developer Guides (Root Directory)

- **[CLAUDE.md](../CLAUDE.md)** - Project guidance for Claude Code
- **[README.md](../README.md)** - Project overview and quick start

## Quick Links

### For Users

If you want to:
- **Learn about payments** → [MULTI_CURRENCY_PAYMENTS.md](MULTI_CURRENCY_PAYMENTS.md)
- **Set up the app** → [README.md](../README.md)
- **Deploy the app** → [DEPLOYMENT.md](../DEPLOYMENT.md)
- **Configure Google Sheets** → [SERVICE_ACCOUNT_SETUP.md](../SERVICE_ACCOUNT_SETUP.md)

### For Developers

If you want to:
- **Understand the architecture** → [STRUCTURE.md](../STRUCTURE.md)
- **Add new features** → [CLAUDE.md](../CLAUDE.md)
- **Implement currency features** → [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- **Understand database schema** → [DATABASE_SETUP.md](../DATABASE_SETUP.md)

## Feature Status

### ✅ Completed (Phase 1)
- Multi-currency support (USD/PHP)
- Payment records tracking
- Automatic exchange rate fetching
- Payment history table
- Auto-update project payment status
- Payment deletion with confirmation
- Google Sheets sync for payments

### ⏳ Planned (Phase 2)
- Currency toggle on Dashboard
- Update all statistics for currency conversion
- Update all charts for selected currency
- Edit payment functionality
- Payment history per project
- Advanced payment analytics

## Getting Help

1. Check the relevant documentation file above
2. Look for code comments in source files
3. Check the troubleshooting section in [MULTI_CURRENCY_PAYMENTS.md](MULTI_CURRENCY_PAYMENTS.md)
4. Review error logs in the R console

## Contributing

When adding new features:
1. Update relevant documentation
2. Add code comments
3. Follow existing naming conventions
4. Test thoroughly
5. Update this README if adding new docs
