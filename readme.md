# 👟 ShoeTrak — Multi-Warehouse Shoe Manufacturing Management System

> A cross-platform ERP system built with **Flutter + Supabase** to manage manufacturing, inventory, sales, logistics, and finance across multiple shoe factories — with strict role-based access control.

---

## 📖 Table of Contents

1. [Project Overview](#-project-overview)
2. [System Vision](#-system-vision)
3. [User Roles & Permissions](#-user-roles--permissions)
4. [Tech Stack](#-tech-stack)
5. [Project Structure](#-project-structure)
6. [Database Schema](#-database-schema)
7. [Core Modules](#-core-modules)
8. [Authentication & Security](#-authentication--security)
9. [Realtime Sync](#-realtime-sync)
10. [Financial Logic](#-financial-logic)
11. [Getting Started](#-getting-started)
12. [Environment Variables](#-environment-variables)
13. [Deployment](#-deployment)

---

## 🌍 Project Overview

**ShoeTrak** is a fully integrated business management system designed for a shoe manufacturing company with **4 warehouses/factories** (expandable). It serves two equal co-owners and all their staff, providing real-time visibility, inter-warehouse logistics, production tracking, sales management, employee payroll, and advanced financial reporting.

The system runs as:
- 📱 **Android app** — for managers on the go
- 💻 **Windows desktop app** — for warehouse staff on workstations

Both built from a **single Flutter codebase**.

---

## 🎯 System Vision

```
┌─────────────────────────────────────────────────────────┐
│                    MANAGERS (2 owners)                   │
│           📱 Android  +  💻 Windows Desktop              │
│   See EVERYTHING: finance, profits, interest, salaries   │
└────────────────────────┬────────────────────────────────┘
                         │ Supabase Realtime
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   💻 Warehouse 1   💻 Warehouse 2   💻 Warehouse 3-4
   (Desktop+Mobile) (Desktop+Mobile) (Desktop+Mobile)
   Staff see only   Staff see only   Staff see only
   their daily work their daily work their daily work
```

### The Golden Rule
> 💡 **Financial figures (profits, interest, salaries, costs) are ONLY visible to the two co-owner managers. All other staff see only what is necessary for their daily tasks.**

---

## 👥 User Roles & Permissions

| Role | Count | Devices | Financial Access | Scope |
|------|-------|---------|-----------------|-------|
| **General Manager** | 2 | Android + Desktop | ✅ Full | All 4 warehouses |
| **Warehouse Manager** | 1/warehouse | Desktop + Mobile | ❌ None | Own warehouse only |
| **Salesperson / Accountant** | As needed | Desktop + Mobile | ❌ None | Sales operations |
| **Stock Keeper** | As needed | Desktop + Mobile | ❌ None | Stock in/out |
| **Production Worker** | As needed | Desktop + Mobile | ❌ None | Own production log |

### Permission Matrix

```
Feature                    | Manager | Wh.Manager | Salesperson | StockKeeper | Worker |
---------------------------|---------|------------|-------------|-------------|--------|
View profits & interest    |   ✅    |     ❌     |      ❌     |      ❌     |   ❌   |
View all salaries          |   ✅    |     ❌     |      ❌     |      ❌     |   ❌   |
View financial reports     |   ✅    |     ❌     |      ❌     |      ❌     |   ❌   |
Manage all warehouses      |   ✅    |     ❌     |      ❌     |      ❌     |   ❌   |
Create production orders   |   ✅    |     ✅     |      ❌     |      ❌     |   ❌   |
Log daily production       |   ✅    |     ✅     |      ❌     |      ❌     |   ✅   |
Create sales invoices      |   ✅    |     ✅     |      ✅     |      ❌     |   ❌   |
Transfer stock             |   ✅    |     ✅     |      ❌     |      ✅     |   ❌   |
View own warehouse stock   |   ✅    |     ✅     |      ✅     |      ✅     |   ❌   |
Manage employees           |   ✅    |     ✅     |      ❌     |      ❌     |   ❌   |
View own attendance        |   ✅    |     ✅     |      ✅     |      ✅     |   ✅   |
```

---

## 🛠️ Tech Stack

| Layer | Technology | Reason |
|-------|-----------|--------|
| **Frontend** | Flutter 3.x | Single codebase → Android + Windows |
| **State Management** | Riverpod | Scalable, testable, reactive |
| **Backend** | Supabase | PostgreSQL + Auth + Realtime + Storage |
| **Database** | PostgreSQL (via Supabase) | Relational, powerful, supports RLS |
| **Auth** | Supabase Auth + JWT | Role-based, secure |
| **Realtime** | Supabase Realtime (WebSocket) | Instant sync across all devices |
| **Storage** | Supabase Storage | Product images, invoices, documents |
| **Local Cache** | Hive / Drift | Offline support |
| **PDF Generation** | pdf (dart package) | Invoices & reports |
| **Barcode** | mobile_scanner | QR/Barcode scanning on mobile |
| **Printing** | printing (dart package) | Direct invoice printing |
| **Charts** | fl_chart | Financial dashboards |
| **Excel Export** | excel (dart package) | Export reports |

---

## 📁 Project Structure

```
shoetrak/
│
├── 📁 lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # MaterialApp + routing
│   │
│   ├── 📁 core/
│   │   ├── 📁 constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── supabase_keys.dart
│   │   ├── 📁 theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── desktop_theme.dart
│   │   │   └── mobile_theme.dart
│   │   ├── 📁 utils/
│   │   │   ├── currency_formatter.dart
│   │   │   ├── date_utils.dart
│   │   │   ├── interest_calculator.dart   # Financial calculations
│   │   │   └── pdf_generator.dart
│   │   ├── 📁 routing/
│   │   │   ├── app_router.dart            # GoRouter setup
│   │   │   └── route_guards.dart          # Role-based guards
│   │   └── 📁 services/
│   │       ├── supabase_service.dart
│   │       ├── auth_service.dart
│   │       ├── realtime_service.dart
│   │       └── local_cache_service.dart
│   │
│   ├── 📁 features/
│   │   │
│   │   ├── 📁 auth/
│   │   │   ├── 📁 data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── user_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── login_screen.dart
│   │   │       └── splash_screen.dart
│   │   │
│   │   ├── 📁 dashboard/
│   │   │   ├── 📁 screens/
│   │   │   │   ├── manager_dashboard.dart    # Full financial view
│   │   │   │   └── staff_dashboard.dart      # Limited operational view
│   │   │   └── 📁 widgets/
│   │   │       ├── warehouse_summary_card.dart
│   │   │       ├── daily_stats_widget.dart
│   │   │       └── alert_banner.dart
│   │   │
│   │   ├── 📁 inventory/
│   │   │   ├── 📁 data/
│   │   │   │   ├── inventory_repository.dart
│   │   │   │   └── product_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── inventory_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── inventory_list_screen.dart
│   │   │       ├── product_detail_screen.dart
│   │   │       ├── add_product_screen.dart
│   │   │       └── barcode_scanner_screen.dart
│   │   │
│   │   ├── 📁 production/
│   │   │   ├── 📁 data/
│   │   │   │   ├── production_repository.dart
│   │   │   │   ├── production_order_model.dart
│   │   │   │   └── production_log_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── production_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── production_orders_screen.dart
│   │   │       ├── new_order_screen.dart
│   │   │       └── worker_log_screen.dart
│   │   │
│   │   ├── 📁 transfers/
│   │   │   ├── 📁 data/
│   │   │   │   ├── transfer_repository.dart
│   │   │   │   └── transfer_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── transfer_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── transfers_list_screen.dart
│   │   │       ├── new_transfer_screen.dart
│   │   │       └── transfer_confirmation_screen.dart
│   │   │
│   │   ├── 📁 sales/
│   │   │   ├── 📁 data/
│   │   │   │   ├── sales_repository.dart
│   │   │   │   ├── invoice_model.dart
│   │   │   │   └── client_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── sales_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── sales_list_screen.dart
│   │   │       ├── new_invoice_screen.dart
│   │   │       ├── client_list_screen.dart
│   │   │       └── debt_tracking_screen.dart
│   │   │
│   │   ├── 📁 employees/
│   │   │   ├── 📁 data/
│   │   │   │   ├── employee_repository.dart
│   │   │   │   ├── employee_model.dart
│   │   │   │   └── attendance_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── employee_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── employee_list_screen.dart
│   │   │       ├── attendance_screen.dart
│   │   │       └── payroll_screen.dart        # Manager only
│   │   │
│   │   └── 📁 finance/                        # ⚠️ MANAGERS ONLY
│   │       ├── 📁 data/
│   │       │   ├── finance_repository.dart
│   │       │   └── financial_report_model.dart
│   │       ├── 📁 providers/
│   │       │   └── finance_provider.dart
│   │       └── 📁 screens/
│   │           ├── financial_dashboard_screen.dart
│   │           ├── profit_loss_screen.dart
│   │           ├── interest_report_screen.dart
│   │           └── warehouse_comparison_screen.dart
│   │
│   └── 📁 shared/
│       ├── 📁 widgets/
│       │   ├── custom_app_bar.dart
│       │   ├── loading_widget.dart
│       │   ├── empty_state_widget.dart
│       │   ├── confirmation_dialog.dart
│       │   └── role_guard_widget.dart         # Hides UI by role
│       └── 📁 extensions/
│           ├── string_extensions.dart
│           └── datetime_extensions.dart
│
├── 📁 supabase/
│   ├── 📁 migrations/                         # SQL migration files
│   │   ├── 001_create_warehouses.sql
│   │   ├── 002_create_products.sql
│   │   ├── 003_create_inventory.sql
│   │   ├── 004_create_production.sql
│   │   ├── 005_create_transfers.sql
│   │   ├── 006_create_sales.sql
│   │   ├── 007_create_employees.sql
│   │   ├── 008_create_finance.sql
│   │   └── 009_create_rls_policies.sql        # Row Level Security
│   │
│   └── 📁 functions/                          # Edge Functions
│       ├── calculate-payroll/
│       │   └── index.ts
│       ├── generate-financial-report/
│       │   └── index.ts
│       └── calculate-interest/
│           └── index.ts
│
├── 📁 assets/
│   ├── 📁 images/
│   ├── 📁 icons/
│   └── 📁 fonts/
│
├── 📁 test/
│   ├── 📁 unit/
│   ├── 📁 widget/
│   └── 📁 integration/
│
├── pubspec.yaml
├── .env.example
└── README.md
```

---

## 🗄️ Database Schema

### Tables Overview

```
profiles              — User accounts & roles
warehouses            — The 4 factories/warehouses
raw_materials         — Input materials for production
products              — Finished shoe products (SKU, size, type)
inventory             — Stock levels per warehouse per product
production_orders     — Manufacturing job orders
production_logs       — Daily worker production entries
stock_transfers       — Inter-warehouse stock movements
clients               — Customers / buyers
invoices              — Sales invoices (header)
invoice_items         — Line items per invoice
payments              — Payments against invoices
employees             — Staff records
attendance            — Daily attendance records
salary_sheets         — Monthly payroll calculations
expenses              — Operational expenses per warehouse
financial_snapshots   — Monthly financial summaries (managers only)
```

---

### Full SQL Schema

```sql
-- =============================================
-- PROFILES (extends Supabase auth.users)
-- =============================================
CREATE TABLE profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name     TEXT NOT NULL,
  phone         TEXT,
  role          TEXT NOT NULL CHECK (role IN (
                  'general_manager',
                  'warehouse_manager',
                  'salesperson',
                  'accountant',
                  'stock_keeper',
                  'production_worker'
                )),
  warehouse_id  UUID REFERENCES warehouses(id),  -- NULL = access all
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- WAREHOUSES
-- =============================================
CREATE TABLE warehouses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  location    TEXT,
  manager_id  UUID REFERENCES profiles(id),
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RAW MATERIALS
-- =============================================
CREATE TABLE raw_materials (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  unit            TEXT NOT NULL,  -- meter, piece, kg, roll...
  warehouse_id    UUID REFERENCES warehouses(id),
  quantity        NUMERIC DEFAULT 0,
  min_quantity    NUMERIC DEFAULT 0,  -- alert threshold
  unit_cost       NUMERIC DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PRODUCTS (Shoe catalog)
-- =============================================
CREATE TABLE products (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  category      TEXT,           -- men, women, children, sport...
  size          TEXT,           -- 38, 39, 40, 41, 42...
  color         TEXT,
  material      TEXT,           -- leather, synthetic...
  sku           TEXT UNIQUE,
  barcode       TEXT UNIQUE,
  unit_cost     NUMERIC DEFAULT 0,   -- production cost
  selling_price NUMERIC DEFAULT 0,
  image_url     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- INVENTORY (Stock per warehouse)
-- =============================================
CREATE TABLE inventory (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id  UUID NOT NULL REFERENCES warehouses(id),
  product_id    UUID NOT NULL REFERENCES products(id),
  quantity      INTEGER DEFAULT 0,
  last_updated  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(warehouse_id, product_id)
);

-- =============================================
-- PRODUCTION ORDERS
-- =============================================
CREATE TABLE production_orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id    UUID REFERENCES warehouses(id),
  product_id      UUID REFERENCES products(id),
  ordered_qty     INTEGER NOT NULL,
  produced_qty    INTEGER DEFAULT 0,
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending','in_progress','completed','cancelled')),
  ordered_by      UUID REFERENCES profiles(id),
  target_date     DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PRODUCTION LOGS (Worker daily entries)
-- =============================================
CREATE TABLE production_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID REFERENCES production_orders(id),
  worker_id     UUID REFERENCES profiles(id),
  warehouse_id  UUID REFERENCES warehouses(id),
  quantity      INTEGER NOT NULL,
  log_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- STOCK TRANSFERS
-- =============================================
CREATE TABLE stock_transfers (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  to_warehouse_id   UUID NOT NULL REFERENCES warehouses(id),
  product_id        UUID NOT NULL REFERENCES products(id),
  quantity          INTEGER NOT NULL,
  status            TEXT DEFAULT 'pending'
                    CHECK (status IN ('pending','approved','in_transit','received','cancelled')),
  requested_by      UUID REFERENCES profiles(id),
  approved_by       UUID REFERENCES profiles(id),
  received_by       UUID REFERENCES profiles(id),
  reason            TEXT,
  requested_at      TIMESTAMPTZ DEFAULT NOW(),
  approved_at       TIMESTAMPTZ,
  received_at       TIMESTAMPTZ
);

-- =============================================
-- CLIENTS
-- =============================================
CREATE TABLE clients (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  phone         TEXT,
  address       TEXT,
  city          TEXT,
  client_type   TEXT DEFAULT 'wholesale'
                CHECK (client_type IN ('wholesale','retail')),
  total_debt    NUMERIC DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- INVOICES
-- =============================================
CREATE TABLE invoices (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number  TEXT UNIQUE NOT NULL,
  warehouse_id    UUID REFERENCES warehouses(id),
  client_id       UUID REFERENCES clients(id),
  created_by      UUID REFERENCES profiles(id),
  total_amount    NUMERIC NOT NULL DEFAULT 0,
  paid_amount     NUMERIC NOT NULL DEFAULT 0,
  debt_amount     NUMERIC GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
  payment_status  TEXT DEFAULT 'unpaid'
                  CHECK (payment_status IN ('paid','partial','unpaid')),
  sale_type       TEXT DEFAULT 'wholesale'
                  CHECK (sale_type IN ('wholesale','retail')),
  notes           TEXT,
  invoice_date    DATE DEFAULT CURRENT_DATE,
  due_date        DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- INVOICE ITEMS
-- =============================================
CREATE TABLE invoice_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id    UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id    UUID REFERENCES products(id),
  quantity      INTEGER NOT NULL,
  unit_price    NUMERIC NOT NULL,
  total_price   NUMERIC GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- =============================================
-- PAYMENTS
-- =============================================
CREATE TABLE payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id      UUID REFERENCES invoices(id),
  client_id       UUID REFERENCES clients(id),
  amount          NUMERIC NOT NULL,
  payment_method  TEXT DEFAULT 'cash'
                  CHECK (payment_method IN ('cash','bank_transfer','cheque')),
  received_by     UUID REFERENCES profiles(id),
  payment_date    DATE DEFAULT CURRENT_DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- EMPLOYEES
-- =============================================
CREATE TABLE employees (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id      UUID REFERENCES profiles(id),
  warehouse_id    UUID REFERENCES warehouses(id),
  base_salary     NUMERIC NOT NULL,
  hire_date       DATE,
  job_title       TEXT,
  national_id     TEXT,
  bank_account    TEXT,
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ATTENDANCE
-- =============================================
CREATE TABLE attendance (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id   UUID REFERENCES employees(id),
  warehouse_id  UUID REFERENCES warehouses(id),
  date          DATE NOT NULL DEFAULT CURRENT_DATE,
  status        TEXT NOT NULL
                CHECK (status IN ('present','absent','late','half_day','holiday')),
  check_in      TIME,
  check_out     TIME,
  notes         TEXT,
  UNIQUE(employee_id, date)
);

-- =============================================
-- SALARY SHEETS (Monthly payroll)
-- =============================================
CREATE TABLE salary_sheets (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id       UUID REFERENCES employees(id),
  warehouse_id      UUID REFERENCES warehouses(id),
  month             INTEGER NOT NULL,  -- 1-12
  year              INTEGER NOT NULL,
  base_salary       NUMERIC NOT NULL,
  days_present      INTEGER DEFAULT 0,
  days_absent       INTEGER DEFAULT 0,
  production_bonus  NUMERIC DEFAULT 0,
  deductions        NUMERIC DEFAULT 0,
  net_salary        NUMERIC NOT NULL,
  is_paid           BOOLEAN DEFAULT FALSE,
  paid_at           TIMESTAMPTZ,
  notes             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, month, year)
);

-- =============================================
-- EXPENSES
-- =============================================
CREATE TABLE expenses (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id  UUID REFERENCES warehouses(id),
  category      TEXT NOT NULL,  -- rent, utilities, transport, maintenance...
  amount        NUMERIC NOT NULL,
  description   TEXT,
  expense_date  DATE DEFAULT CURRENT_DATE,
  recorded_by   UUID REFERENCES profiles(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- FINANCIAL SNAPSHOTS (Managers only)
-- =============================================
CREATE TABLE financial_snapshots (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id        UUID REFERENCES warehouses(id),  -- NULL = global
  month               INTEGER NOT NULL,
  year                INTEGER NOT NULL,
  total_revenue       NUMERIC DEFAULT 0,
  total_cost          NUMERIC DEFAULT 0,
  gross_profit        NUMERIC DEFAULT 0,
  total_expenses      NUMERIC DEFAULT 0,
  net_profit          NUMERIC DEFAULT 0,
  total_salaries      NUMERIC DEFAULT 0,
  total_debt          NUMERIC DEFAULT 0,
  interest_accrued    NUMERIC DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(warehouse_id, month, year)
);
```

---

## 🔐 Row Level Security (RLS) Policies

```sql
-- Enable RLS on all sensitive tables
ALTER TABLE financial_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_sheets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses            ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- Helper function to get current user warehouse
CREATE OR REPLACE FUNCTION get_user_warehouse()
RETURNS UUID AS $$
  SELECT warehouse_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- FINANCIAL SNAPSHOTS: Managers only
CREATE POLICY "managers_only_financial"
ON financial_snapshots FOR ALL
USING (get_user_role() = 'general_manager');

-- SALARY SHEETS: Managers only
CREATE POLICY "managers_only_salaries"
ON salary_sheets FOR ALL
USING (get_user_role() = 'general_manager');

-- INVENTORY: Staff see only their warehouse
CREATE POLICY "inventory_by_warehouse"
ON inventory FOR SELECT
USING (
  get_user_role() = 'general_manager'
  OR warehouse_id = get_user_warehouse()
);

-- TRANSFERS: Involved warehouses only
CREATE POLICY "transfers_by_warehouse"
ON stock_transfers FOR SELECT
USING (
  get_user_role() = 'general_manager'
  OR from_warehouse_id = get_user_warehouse()
  OR to_warehouse_id   = get_user_warehouse()
);

-- PRODUCTION LOGS: Workers see only their own logs
CREATE POLICY "production_logs_own"
ON production_logs FOR SELECT
USING (
  get_user_role() IN ('general_manager', 'warehouse_manager')
  OR worker_id = auth.uid()
);
```

---

## 💰 Financial Logic

### Interest Calculation

```dart
// lib/core/utils/interest_calculator.dart

class InterestCalculator {
  /// Calculate simple interest on client debt
  /// rate: annual interest rate (e.g. 0.12 = 12%)
  static double simpleInterest({
    required double principal,
    required double annualRate,
    required int daysOverdue,
  }) {
    return principal * annualRate * (daysOverdue / 365);
  }

  /// Calculate compound interest
  static double compoundInterest({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final monthlyRate = annualRate / 12;
    return principal * (pow(1 + monthlyRate, months) - 1);
  }

  /// Net profit per warehouse
  static double netProfit({
    required double revenue,
    required double productionCost,
    required double salaries,
    required double expenses,
  }) {
    return revenue - productionCost - salaries - expenses;
  }

  /// Production cost per pair
  static double costPerUnit({
    required List<MaterialUsage> materials,
    required double laborCost,
    required int quantity,
  }) {
    final materialCost = materials.fold(0.0,
        (sum, m) => sum + (m.quantity * m.unitCost));
    return (materialCost + laborCost) / quantity;
  }
}
```

### Monthly Payroll Calculation

```dart
// Handled via Supabase Edge Function

// Input: employee_id, month, year
// Logic:
//   1. Count attendance days
//   2. Calculate daily rate = base_salary / working_days_in_month
//   3. Deductions = absent_days * daily_rate
//   4. Production bonus = units_produced * bonus_per_unit
//   5. Net = base_salary - deductions + bonus

// net_salary = base_salary
//            - (absent_days * (base_salary / working_days))
//            + production_bonus
//            - other_deductions
```

---

## ⚡ Realtime Sync

Supabase Realtime ensures all devices update instantly:

```dart
// lib/core/services/realtime_service.dart

class RealtimeService {
  final _supabase = Supabase.instance.client;

  // Listen to inventory changes across all warehouses
  Stream<List<Map<String, dynamic>>> inventoryStream(String warehouseId) {
    return _supabase
        .from('inventory')
        .stream(primaryKey: ['id'])
        .eq('warehouse_id', warehouseId);
  }

  // Listen to incoming transfer requests
  Stream<List<Map<String, dynamic>>> transferRequestsStream(String warehouseId) {
    return _supabase
        .from('stock_transfers')
        .stream(primaryKey: ['id'])
        .eq('to_warehouse_id', warehouseId)
        .eq('status', 'pending');
  }

  // Listen to low stock alerts
  Stream<List<Map<String, dynamic>>> lowStockStream() {
    return _supabase
        .from('inventory')
        .stream(primaryKey: ['id'])
        .lte('quantity', 50); // threshold
  }
}
```

---

## 🔑 Authentication & Security

```dart
// lib/core/services/auth_service.dart

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<UserModel?> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();
    return UserModel.fromMap(profile);
  }

  UserRole get currentRole {
    // Drives UI visibility and route guards
    final roleStr = currentUser?.role ?? '';
    return UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.productionWorker,
    );
  }

  bool get isManager => currentRole == UserRole.generalManager;
}
```

### Route Guard Example

```dart
// Protect financial routes
redirect: (context, state) {
  final auth = ref.read(authProvider);
  if (!auth.isManager && state.uri.path.startsWith('/finance')) {
    return '/dashboard'; // Redirect unauthorized users
  }
  return null;
},
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`
- A [Supabase](https://supabase.com) project
- Android Studio / VS Code
- Windows build tools (for desktop build)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-org/shoetrak.git
cd shoetrak

# 2. Install dependencies
flutter pub get

# 3. Copy environment file
cp .env.example .env
# Fill in your Supabase credentials

# 4. Run database migrations
# Go to Supabase Dashboard → SQL Editor
# Run each file in supabase/migrations/ in order

# 5. Run the app
# Android
flutter run -d android

# Windows Desktop
flutter run -d windows
```

---

## 🌍 Environment Variables

```env
# .env.example
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

```dart
// lib/core/constants/supabase_keys.dart
class SupabaseKeys {
  static const url    = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

---

## ☁️ Deployment

### Android APK

```bash
flutter build apk --release --split-per-abi
# Output: build/app/outputs/flutter-apk/
```

### Windows Desktop

```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```

### Supabase Edge Functions

```bash
supabase functions deploy calculate-payroll
supabase functions deploy generate-financial-report
supabase functions deploy calculate-interest
```

---

## 📅 Development Roadmap

```
Phase 1 — Core Foundation (4–6 weeks)
├── ✅ Auth + Role system
├── ✅ Warehouse & product management
├── ✅ Inventory (realtime)
└── ✅ Stock transfers

Phase 2 — Operations (4–6 weeks)
├── ✅ Production orders & worker logs
├── ✅ Sales & invoicing
├── ✅ Client management & debt tracking
└── ✅ Payment recording

Phase 3 — HR & Finance (3–4 weeks)
├── ✅ Employee management
├── ✅ Attendance tracking
├── ✅ Monthly payroll
└── ✅ Financial reports & interest calc (managers only)

Phase 4 — Polish & Scale (ongoing)
├── ✅ Barcode/QR scanning
├── ✅ Push notifications
├── ✅ PDF invoice printing
├── ✅ Excel report export
└── ✅ Offline mode support
```

---

## 📊 Estimated Costs

| Item | Cost |
|------|------|
| Supabase Pro plan | ~$25/month |
| Development (full system) | $4,000 – $8,000 |
| Annual maintenance | $500 – $1,500 |

---

## 📄 License

Private — All rights reserved © 2026 ShoeTrak

---

> Built with ❤️ using Flutter + Supabase