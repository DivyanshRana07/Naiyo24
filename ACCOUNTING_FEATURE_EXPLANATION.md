# 📊 Accounting Feature Explanation - Frontend

## Overview

The accounting feature in the frontend is a **Chart of Accounts (COA)** system that follows standard accounting principles. It's designed for small businesses to manage their accounting ledgers and financial tracking.

---

## 🏗️ Architecture

### Two-Level Hierarchy

```
Account Groups (Categories)
    ↓
Individual Accounts (Ledgers)
```

**Example:**
```
Bank Accounts (Group)
  ├── State Bank Checking (Account)
  ├── HDFC Savings (Account)
  └── Cash in Hand (Account)
```

---

## 📁 1. Account Groups

**Purpose**: Organize accounts into logical categories

**Location**: `/accounting/groups`

### Pre-Seeded Groups (13 System Groups)

#### **Assets** (Things the business owns)
- `Bank Accounts` - Bank checking, savings accounts
- `Cash Accounts` - Physical cash
- `Accounts Receivable` - Money customers owe you

#### **Liabilities** (Things the business owes)
- `Duties and Taxes` - GST, sales tax, etc.

#### **Capital/Equity** (Owner's stake)
- `Capital Accounts` - Owner's initial investment
- `Equities` - Shareholders' equity

#### **Income** (Money coming in)
- `Sales / Revenue` - Sales from products/services
- `Interest Incomes` - Interest earned

#### **Expenses** (Money going out)
- `Cost Of Goods Sold` - Direct product costs
- `Purchase Accounts` - Inventory purchases
- `Financial Expenses` - Interest paid, bank charges
- `Indirect Expenses` - Utilities, rent, misc
- `Administrative Expenses` - Office, admin costs

### Data Model

```dart
AccountGroupModel {
  id: String              // Unique identifier
  name: String            // e.g., "Bank Accounts"
  type: String            // Asset/Liability/Income/Expense/Capital
  category: String        // Display category
  description: String?    // Optional notes
  isSystem: bool          // If true, cannot be deleted
  createdAt: DateTime
}
```

### Features

✅ **View All Groups**: See all 13 system groups + custom groups
✅ **Search**: Filter by name, type, or category
✅ **Create New**: Add custom account groups
✅ **Edit**: Modify group details
✅ **Delete**: Remove custom groups (system groups protected)
✅ **Export**: CSV, WhatsApp, PDF formats

### System Protection

- System groups have `isSystem: true`
- Cannot be deleted (UI prevents this)
- Can be edited but with caution warnings
- Ensures accounting integrity

---

## 💰 2. Chart of Accounts (Individual Accounts)

**Purpose**: Individual ledgers for tracking specific transactions

**Location**: `/accounting/chart-of-accounts`

### Pre-Seeded Accounts (7 System Accounts)

These are created automatically for invoice/GST features:

1. **Round Off** (Expense)
   - Group: Indirect Expenses
   - Purpose: Handle rounding differences in invoices
   - Code: 5001

2. **Legacy Debit Card Payment Mode** (Asset)
   - Group: Bank Accounts
   - Purpose: Track debit card payments
   - Code: 1001

3. **Interest Income** (Income)
   - Group: Interest Incomes
   - Purpose: Track interest earned
   - Code: 3001

4. **Cost Of Goods Sold** (Expense)
   - Group: Cost Of Goods Sold
   - Purpose: Track product costs
   - Code: 5002

5. **Legacy Other Payment Mode** (Asset)
   - Group: Bank Accounts
   - Purpose: Track other payment methods
   - Code: 1002

6. **Sales SGST** (Liability)
   - Group: Duties and Taxes
   - Purpose: Track State GST on sales
   - Code: 2001

7. **Sales UTGST** (Liability)
   - Group: Duties and Taxes
   - Purpose: Track Union Territory GST
   - Code: 2002

### Data Model

```dart
AccountModel {
  id: String                // Unique identifier
  name: String              // e.g., "HDFC Bank Checking"
  code: String              // Unique code (e.g., "1001")
  accountGroupId: String    // Links to Account Group
  type: String              // Asset/Liability/Income/Expense
  openingBalance: double    // Starting balance
  currentBalance: double    // Current balance
  isActive: bool            // Active or archived
  currency: String          // Default: INR
  createdAt: DateTime
}
```

### Features

✅ **Tabbed View**:
- **Active Accounts**: Currently in use
- **Inactive Accounts**: Archived accounts

✅ **Search**: Filter by name, code, group, category, type

✅ **Account Operations**:
- Create new accounts
- Edit existing accounts
- Toggle active/inactive status
- Delete accounts (with warnings)

✅ **Data Display**:
- Code, Name, Account Group, Category
- Type (Asset/Liability/Income/Expense)
- Opening Balance, Current Balance
- Status (Active/Inactive badge)

✅ **Export**: CSV, WhatsApp, PDF with full details

---

## 🔄 How It Works

### Relationship Diagram

```
┌─────────────────────────────────────┐
│     Account Groups Screen           │
│  (13 system + custom groups)        │
│                                     │
│  ✓ Bank Accounts                    │
│  ✓ Cash Accounts                    │
│  ✓ Duties and Taxes                 │
│  ✓ Sales / Revenue                  │
│  └─ + Create New Group              │
└──────────────┬──────────────────────┘
               │
               ▼ (Groups organize Accounts)
┌─────────────────────────────────────┐
│   Chart of Accounts Screen          │
│  (7 system + custom accounts)       │
│                                     │
│  Code | Account Name | Group        │
│  1001 | HDFC Bank    | Bank Accts  │
│  2001 | Sales SGST   | Taxes       │
│  3001 | Interest Inc.| Income      │
│  └─ + Create New Account            │
└─────────────────────────────────────┘
```

### Account Creation Flow

```
1. User clicks "Create New Account"
   ↓
2. Dialog opens with form:
   - Name (required)
   - Code (required, unique)
   - Account Group (dropdown, required)
   - Type (auto-filled from group)
   - Opening Balance
   ↓
3. User fills and submits
   ↓
4. AccountNotifier.addAccount()
   ↓
5. Saved to SharedPreferences (local cache)
   ↓
6. Account appears in table
```

### Future Backend Integration

Currently accounts are **local-only** (SharedPreferences). When backend is integrated:

```dart
// Future implementation
class AccountNotifier {
  Future<void> addAccount(AccountModel account) async {
    // POST to /api/v1/accounts
    final saved = await accountService.createAccount(account);
    state = [...state, saved];
    _persist(); // Cache locally
  }

  Future<void> _fetchAccounts() async {
    // GET from /api/v1/accounts
    final accounts = await accountService.listAccounts();
    state = accounts;
    _persist();
  }
}
```

---

## 🎯 Use Cases

### 1. Track Bank Accounts

```
Create Account Group: "My Banks"
Create Accounts:
  - "HDFC Savings" (Code: 1010, Type: Asset)
  - "SBI Current" (Code: 1011, Type: Asset)
  
Opening Balance: ₹50,000
```

### 2. Track Sales by Channel

```
Use Group: "Sales / Revenue"
Create Accounts:
  - "Online Sales" (Code: 4001)
  - "Retail Sales" (Code: 4002)
  - "Wholesale Sales" (Code: 4003)
```

### 3. Track Expenses

```
Use Group: "Indirect Expenses"
Create Accounts:
  - "Electricity Bill" (Code: 5010)
  - "Office Rent" (Code: 5011)
  - "Internet" (Code: 5012)
```

### 4. GST Tracking (Auto-created)

```
Pre-seeded accounts handle GST:
  - "Sales SGST" (Code: 2001) - State GST
  - "Sales UTGST" (Code: 2002) - Union Territory GST
  
When invoice is created:
  → GST amounts posted to these accounts
  → Balance automatically updated
```

---

## 📊 Features Breakdown

### Account Groups Screen

**UI Components**:
- Search bar (filters by name/type/category)
- "Export" button (download options)
- "Create New Account Group" button
- Data table with columns:
  - Account Group
  - Type
  - Category
  - Description
  - Actions (Edit/Delete)

**Actions**:
- ✏️ Edit: Modify group details
- 🗑️ Delete: Remove custom groups (system groups protected)
- 📥 Export: Download as CSV/WhatsApp/PDF

**Empty State**:
- Shows when no groups match search
- "Create New Account Group" button

### Chart of Accounts Screen

**UI Components**:
- Search bar (filters by name/code/group/category)
- Tabs: "Active Accounts" | "Inactive Accounts"
- "Export" button
- "Create New Account" button
- Data table with columns:
  - Code
  - Account Name
  - Account Group
  - Category
  - Type
  - Opening Balance
  - Current Balance
  - Status (Active/Inactive badge)
  - Actions

**Actions**:
- ✏️ Edit: Modify account details
- 📦 Archive/Unarchive: Toggle active status
- 🗑️ Delete: Remove account (with warning)
- 📥 Export: Download as CSV/WhatsApp/PDF

**Status Badges**:
- 🟢 Active: Green badge
- ⚫ Inactive: Gray badge

---

## 🔐 Data Storage

### Current Implementation (Local Only)

```
SharedPreferences Keys:
├── "accountGroupsList" → List<AccountGroupModel>
└── "chartOfAccountsList" → List<AccountModel>
```

**Persistence Flow**:
```dart
1. User creates/updates account
   ↓
2. State updated in memory
   ↓
3. _persist() called
   ↓
4. JSON.encode(accounts)
   ↓
5. Saved to SharedPreferences
   ↓
6. On app restart:
   - Load from SharedPreferences
   - Parse JSON → List<AccountModel>
   - Render UI
```

### Future (Backend Integration)

```
PostgreSQL Tables:
├── account_groups (backend/models/db_models.py)
└── accounts (backend/models/db_models.py)

API Endpoints:
├── GET    /api/v1/account-groups
├── POST   /api/v1/account-groups
├── PUT    /api/v1/account-groups/{id}
├── DELETE /api/v1/account-groups/{id}
├── GET    /api/v1/accounts
├── POST   /api/v1/accounts
├── PUT    /api/v1/accounts/{id}
└── DELETE /api/v1/accounts/{id}
```

---

## 🎨 UI/UX Highlights

### Navigation

Located in sidebar under **"Accounting"** dropdown:
```
Accounting ▼
  ├── Account Groups
  └── Chart of Accounts
```

### Responsive Design

- Desktop: Full data table with all columns
- Tablet: Horizontal scroll for table
- Mobile: Horizontal scroll with touch gestures

### Search Experience

- Real-time filtering (as you type)
- Multi-field search (name, code, category, type)
- Highlights: Shows "X of Y" results

### Empty States

- Friendly messages
- Clear call-to-action buttons
- Helpful context

Example:
```
┌─────────────────────────────────┐
│  📁 No active accounts          │
│                                 │
│  Tap "Create New Account"       │
│  to add your first account      │
│  ledger.                        │
│                                 │
│     [Create New Account]        │
└─────────────────────────────────┘
```

---

## 🔮 Future Enhancements (Not Yet Implemented)

### 1. Journal Entries
- Debit/Credit transactions
- Double-entry bookkeeping
- Transaction history per account

### 2. Financial Reports
- Balance Sheet
- Profit & Loss Statement
- Trial Balance
- Ledger Reports

### 3. Account Reconciliation
- Bank reconciliation
- Match transactions
- Identify discrepancies

### 4. Budget Tracking
- Set budgets per account
- Track actual vs budget
- Variance analysis

### 5. Multi-Currency
- Currently only INR
- Add USD, EUR, etc.
- Exchange rate handling

### 6. Account Closing
- Period-end closing
- Opening balance carry-forward
- Year-end finalization

---

## 🔧 Technical Implementation

### State Management (Riverpod)

```dart
// Provider for Account Groups
final accountGroupNotifierProvider =
  AutoDisposeNotifierProvider<AccountGroupNotifier, List<AccountGroupModel>>(
    () => AccountGroupNotifier(),
  );

// Provider for Accounts (COA)
final accountNotifierProvider =
  AutoDisposeNotifierProvider<AccountNotifier, List<AccountModel>>(
    () => AccountNotifier(),
  );

// Async provider for loading
final asyncAccountsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(accountNotifierProvider);
});
```

### Notifier Pattern

```dart
class AccountNotifier extends AutoDisposeNotifier<List<AccountModel>> {
  @override
  List<AccountModel> build() {
    // Load from cache
    // Return initial state
  }

  void addAccount(AccountModel account) {
    // Add to state
    // Persist to cache
  }

  void updateAccount(AccountModel updated) {
    // Update in state
    // Persist to cache
  }

  void deleteAccount(String id) {
    // Remove from state
    // Persist to cache
  }
}
```

### Data Flow

```
UI Widget
  ↓ (reads)
Riverpod Provider
  ↓ (manages)
Notifier State
  ↓ (persists)
SharedPreferences
```

---

## 📝 Summary

**What the Accounting Feature Does:**

1. **Organizes Financial Data**
   - Groups accounts into categories
   - Follows standard accounting structure

2. **Tracks Money Movement**
   - Assets (what you own)
   - Liabilities (what you owe)
   - Income (money coming in)
   - Expenses (money going out)
   - Capital (owner's stake)

3. **Enables Financial Reporting** (future)
   - Balance sheets
   - Profit/Loss statements
   - Tax reports

4. **Integrates with Invoicing**
   - Auto-creates GST accounts
   - Tracks sales revenue
   - Handles rounding

**Current Limitations:**

- ❌ No journal entries (manual posting)
- ❌ No transaction history
- ❌ No financial reports
- ❌ No backend integration (local only)
- ❌ No multi-currency support

**Strengths:**

- ✅ Clean UI/UX
- ✅ Standard accounting structure
- ✅ System groups protected
- ✅ Search and filter
- ✅ Export functionality
- ✅ Offline-first (local cache)
- ✅ Ready for backend integration

---

## 🎓 Accounting Concepts

### Chart of Accounts (COA)

A **Chart of Accounts** is a list of all accounts used by a business to record transactions. Think of it as a **filing system** for money:

```
Bank Account (Asset)
  ↓
When money comes in: Balance goes UP ⬆️
When money goes out: Balance goes DOWN ⬇️
```

### Account Types

**Assets** = Things that bring value
- Cash, Bank Accounts, Inventory, Buildings

**Liabilities** = Amounts owed to others
- Loans, Credit Cards, Taxes Payable

**Income** = Money earned
- Sales, Service Fees, Interest Income

**Expenses** = Money spent
- Rent, Salaries, Utilities, Purchases

**Equity/Capital** = Owner's stake
- Capital Investment, Retained Earnings

### Double-Entry Bookkeeping (Future)

Every transaction affects **two accounts**:

```
Example: Received ₹10,000 cash from customer

Debit:  Cash Account        +₹10,000 (Asset ↑)
Credit: Sales Revenue       +₹10,000 (Income ↑)

Total: Debit = Credit (balanced)
```

---

## 🚀 Getting Started

### For Business Users

1. **Go to Accounting → Account Groups**
   - Review the 13 system groups
   - Create custom groups if needed

2. **Go to Accounting → Chart of Accounts**
   - Review the 7 pre-seeded accounts
   - Create your business accounts:
     - Bank accounts
     - Expense categories
     - Revenue streams

3. **Start Using**
   - Accounts get used when you:
     - Create invoices (GST accounts)
     - Track payments (bank accounts)
     - Record expenses (expense accounts)

### For Developers

1. **Backend Integration** (when ready):
   - Add API services for accounts
   - Update notifiers to call backend
   - Handle sync errors gracefully

2. **Journal Entries** (Phase 2):
   - Create transaction recording UI
   - Implement double-entry logic
   - Link to accounts

3. **Reports** (Phase 3):
   - Balance Sheet generation
   - P&L Statement
   - Export to Excel/PDF

---

**That's the complete accounting feature explanation!** 📊✨

It's a solid foundation for small business accounting, ready to be enhanced with backend integration and advanced features.
