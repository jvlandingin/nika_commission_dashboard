# Multi-Currency & Payment Records Implementation Plan

## Phase 1: Foundation (Current - In Progress)

### Completed:
- ✅ Added `httr` and `jsonlite` packages for API calls
- ✅ Created `R/utils_currency.R` with exchange rate fetching
- ✅ Added `CURRENCIES` and `PAYMENT_METHODS` to global config
- ✅ Updated database schema with `currency` field in projects table
- ✅ Created `payments` table in SQLite
- ✅ Added backward compatibility for `currency` field (defaults to USD)

### Remaining Phase 1 Tasks:
1. Add `currency` field to sample data generation
2. Update New Project form UI to include currency dropdown
3. Update server to handle currency field when adding projects
4. Create payment data model functions (load/save payments)
5. Add "Payment Records" tab to UI
6. Create payment input form (project selector, amount, date, currency, method, notes)
7. Create payments display table
8. Wire up payment recording in server with automatic exchange rate fetching
9. Test basic functionality

## Phase 2: Advanced Features (Next Session)

### To Implement Later:
1. Add currency toggle (USD/PHP) to dashboard
2. Update all statistics calculations to support currency conversion
3. Update all charts to support selected currency
4. Auto-calculate `payment_status` based on total payments vs budget
5. Remove `amount_paid` field (calculate from payments table instead)
6. Add edit/delete functionality for payments
7. Show payment history per project
8. Add filters to payment records table

## Key Design Decisions:

- **Default Currency**: USD for dashboard display
- **Exchange Rates**: Fetched from API when recording payment, stored with each payment
- **Multi-Currency**: Projects can have budgets in USD or PHP; payments can be in either currency
- **Payment Status**: Will be auto-calculated (Paid if total >= budget, Partially Paid if 0 < total < budget, Unpaid if total = 0)
- **Google Sheets**: "Payments" sheet already created by user

## Files Modified So Far:
- `global.R` - Added packages and constants
- `R/utils_currency.R` - New file with currency utilities
- `R/data_model.R` - Updated schemas, added backward compatibility

## Files To Modify Next:
- `R/data_model.R` - Add payment CRUD functions, update sample data
- `ui.R` - Add currency dropdown, new Payment Records tab
- `server.R` - Handle currency field, add payment recording logic
