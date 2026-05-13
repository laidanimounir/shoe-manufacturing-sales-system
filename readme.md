# 👟 ShoeTrak — Système de Gestion de Fabrication et Vente de Chaussures

> Système ERP multi-entrepôts, multilingue (Français / Arabe), développé avec **Flutter + Supabase**.  
> Gestion complète de la fabrication, des stocks, des ventes, de la logistique et des finances — avec contrôle d'accès strict basé sur les rôles.

---

## 📖 Table des Matières

1. [Vue d'ensemble](#-vue-densemble)
2. [Vision du Système](#-vision-du-système)
3. [Rôles et Permissions](#-rôles-et-permissions)
4. [Stack Technique](#-stack-technique)
5. [Structure du Projet](#-structure-du-projet)
6. [Schéma de Base de Données](#-schéma-de-base-de-données)
7. [Modules Principaux](#-modules-principaux)
8. [Authentification et Sécurité](#-authentification-et-sécurité)
9. [Synchronisation Temps Réel](#-synchronisation-temps-réel)
10. [Logique Financière](#-logique-financière)
11. [Démarrage Rapide](#-démarrage-rapide)
12. [Variables d'Environnement](#-variables-denvironnement)
13. [Déploiement](#-déploiement)

---

## 🌍 Vue d'ensemble

**ShoeTrak** est un système de gestion intégré conçu pour une entreprise de fabrication de chaussures avec **plusieurs entrepôts/usines** (démarrage avec 1, extensible à volonté).

Il sert deux co-propriétaires et tout leur personnel, en offrant :
- Visibilité en temps réel sur la production et les stocks
- Logistique inter-entrepôts
- Suivi de fabrication basé sur des recettes de production
- Gestion des ventes, des clients et de leurs dettes
- Gestion des fournisseurs et de leurs dettes
- Gestion de la paie et des présences
- Rapports financiers avancés (propriétaires uniquement)

Le système fonctionne comme :
- 📱 **Application Android** — pour les gérants en déplacement
- 💻 **Application Windows Desktop** — pour le personnel en poste fixe

Les deux construites depuis un **unique codebase Flutter**.

---

## 🌐 Langue et Interface

| Langue | Statut | Direction |
|--------|--------|-----------|
| **Français** | Langue principale de l'interface | LTR |
| **Arabe** | Langue secondaire complète | RTL |

- Toute l'interface supporte le basculement LTR ↔ RTL
- Les formats de dates, nombres et monnaies suivent les conventions locales (DZ)
- Les fichiers de traduction séparés par langue : `assets/i18n/fr.json` et `assets/i18n/ar.json`

---

## 🎯 Vision du Système

```
┌──────────────────────────────────────────────────────────────┐
│                  PROPRIÉTAIRES (2 gérants)                    │
│            📱 Android  +  💻 Windows Desktop                  │
│  Voient TOUT : finances, bénéfices, intérêts, salaires, coûts│
└─────────────────────────┬────────────────────────────────────┘
                          │ Supabase Realtime
          ┌───────────────┼────────────────┐
          ▼               ▼                ▼
    💻 Entrepôt 1   💻 Entrepôt 2    💻 Entrepôt N
    (Desktop+Mobile)(Desktop+Mobile) (Desktop+Mobile)
    Personnel voit  Personnel voit   Personnel voit
    son travail     son travail      son travail
    quotidien       quotidien        quotidien
```

### Règle d'Or
> 💡 **Les données financières (bénéfices, intérêts, salaires, coûts) ne sont visibles QUE par les deux co-propriétaires. Tout autre personnel ne voit que ce qui est nécessaire à ses tâches quotidiennes.**

### Gestion des Entrepôts
> ⚠️ **Les entrepôts sont entièrement dynamiques.** Le système démarre avec 1 entrepôt. Les propriétaires peuvent ajouter, modifier ou désactiver des entrepôts à tout moment depuis l'interface. Aucune valeur n'est codée en dur.

### Gestion des Utilisateurs
> ⚠️ **Les utilisateurs sont créés directement depuis le Dashboard Supabase** par les propriétaires. L'application ne propose pas d'écran de création d'utilisateur — elle lit les profils existants et adapte l'interface selon le rôle assigné.

---

## 👥 Rôles et Permissions

| Rôle | Appareils | Accès Financier | Périmètre |
|------|-----------|-----------------|-----------|
| **Propriétaire (Gérant Général)** | Android + Desktop | ✅ Complet | Tous les entrepôts |
| **Responsable d'Entrepôt** | Desktop + Mobile | ❌ Aucun | Son entrepôt uniquement |
| **Commercial / Comptable** | Desktop + Mobile | ❌ Aucun | Opérations de vente |
| **Magasinier** | Desktop + Mobile | ❌ Aucun | Entrées/sorties de stock |
| **Ouvrier de Production** | Desktop + Mobile | ❌ Aucun | Son propre journal de production |

### Matrice des Permissions

```
Fonctionnalité                     | Propr. | Resp.  | Commercial | Magasin. | Ouvrier |
-----------------------------------|--------|--------|------------|----------|---------|
Voir bénéfices et intérêts         |   ✅   |   ❌   |     ❌     |    ❌    |   ❌   |
Voir tous les salaires             |   ✅   |   ❌   |     ❌     |    ❌    |   ❌   |
Voir rapports financiers           |   ✅   |   ❌   |     ❌     |    ❌    |   ❌   |
Gérer les entrepôts                |   ✅   |   ❌   |     ❌     |    ❌    |   ❌   |
Ajouter/modifier des entrepôts     |   ✅   |   ❌   |     ❌     |    ❌    |   ❌   |
Valider l'entrée en stock          |   ✅   |   ❌   |     ❌     |    ❌    |   ❌   |
Gérer les recettes de production   |   ✅   |   ✅   |     ❌     |    ❌    |   ❌   |
Créer des ordres de production     |   ✅   |   ✅   |     ❌     |    ❌    |   ❌   |
Enregistrer la production journalière|  ✅   |   ✅   |     ❌     |    ❌    |   ✅   |
Créer des factures de vente        |   ✅   |   ✅   |     ✅     |    ❌    |   ❌   |
Gérer les fournisseurs             |   ✅   |   ✅   |     ❌     |    ✅    |   ❌   |
Réceptionner des commandes fournisseur| ✅  |   ✅   |     ❌     |    ✅    |   ❌   |
Transférer du stock                |   ✅   |   ✅   |     ❌     |    ✅    |   ❌   |
Voir le stock de son entrepôt      |   ✅   |   ✅   |     ✅     |    ✅    |   ❌   |
Gérer les employés                 |   ✅   |   ✅   |     ❌     |    ❌    |   ❌   |
Voir ses propres présences         |   ✅   |   ✅   |     ✅     |    ✅    |   ✅   |
```

---

## 🛠️ Stack Technique

| Couche | Technologie | Raison |
|--------|-------------|--------|
| **Frontend** | Flutter 3.x | Codebase unique → Android + Windows |
| **State Management** | Riverpod | Scalable, testable, réactif |
| **Backend** | Supabase | PostgreSQL + Auth + Realtime + Storage |
| **Base de Données** | PostgreSQL (via Supabase) | Relationnel, RLS puissant |
| **Auth** | Supabase Auth + JWT | Basé sur les rôles, sécurisé |
| **Realtime** | Supabase Realtime (WebSocket) | Sync instantanée multi-appareils |
| **Storage** | Supabase Storage | Images produits, factures, documents |
| **Cache Local** | Hive / Drift | Support hors-ligne |
| **PDF** | pdf (dart package) | Factures & rapports |
| **Code-barres** | mobile_scanner | Scan QR/Barcode sur mobile |
| **Impression** | printing (dart package) | Impression directe des factures |
| **Graphiques** | fl_chart | Tableaux de bord financiers |
| **Export Excel** | excel (dart package) | Export des rapports |
| **i18n** | flutter_localizations + intl | Français + Arabe (LTR/RTL) |
| **Dev AI** | OpenCode + MCP Supabase | Développement assisté avec accès DB direct |

---

## 📁 Structure du Projet

```
shoetrak/
│
├── 📁 lib/
│   ├── main.dart
│   ├── app.dart
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
│   │   │   ├── interest_calculator.dart
│   │   │   └── pdf_generator.dart
│   │   ├── 📁 routing/
│   │   │   ├── app_router.dart
│   │   │   └── route_guards.dart
│   │   ├── 📁 l10n/                          # Localisation FR + AR
│   │   │   ├── app_fr.arb
│   │   │   └── app_ar.arb
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
│   │   ├── 📁 warehouses/                    # Gestion dynamique des entrepôts
│   │   │   ├── 📁 data/
│   │   │   │   ├── warehouse_repository.dart
│   │   │   │   └── warehouse_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── warehouse_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── warehouse_list_screen.dart
│   │   │       ├── warehouse_form_screen.dart    # Ajouter / Modifier
│   │   │       └── warehouse_detail_screen.dart
│   │   │
│   │   ├── 📁 dashboard/
│   │   │   ├── 📁 screens/
│   │   │   │   ├── owner_dashboard.dart          # Vue financière complète
│   │   │   │   └── staff_dashboard.dart          # Vue opérationnelle limitée
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
│   │   ├── 📁 production/                    # ⭐ Module le plus complexe
│   │   │   ├── 📁 data/
│   │   │   │   ├── production_repository.dart
│   │   │   │   ├── production_order_model.dart
│   │   │   │   ├── production_log_model.dart
│   │   │   │   ├── recipe_model.dart             # Recette par produit
│   │   │   │   └── recipe_item_model.dart        # Ligne matière première
│   │   │   ├── 📁 providers/
│   │   │   │   └── production_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── production_orders_screen.dart
│   │   │       ├── new_order_screen.dart
│   │   │       ├── worker_daily_log_screen.dart   # Saisie journalière ouvrier
│   │   │       ├── daily_production_summary.dart  # Résumé fin de journée
│   │   │       ├── recipe_manager_screen.dart     # Gestion des recettes
│   │   │       └── stock_entry_approval_screen.dart # Validation entrée stock
│   │   │
│   │   ├── 📁 suppliers/                     # Fournisseurs (MP + Produits finis)
│   │   │   ├── 📁 data/
│   │   │   │   ├── supplier_repository.dart
│   │   │   │   ├── supplier_model.dart
│   │   │   │   ├── purchase_order_model.dart
│   │   │   │   └── supplier_payment_model.dart
│   │   │   ├── 📁 providers/
│   │   │   │   └── supplier_provider.dart
│   │   │   └── 📁 screens/
│   │   │       ├── supplier_list_screen.dart
│   │   │       ├── supplier_detail_screen.dart    # Historique + dettes
│   │   │       ├── purchase_order_screen.dart     # Commande MP ou produit fini
│   │   │       ├── receive_purchase_screen.dart   # Réception marchandise
│   │   │       └── supplier_payment_screen.dart   # Paiement fournisseur
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
│   │   │       ├── client_detail_screen.dart      # Historique + dettes
│   │   │       ├── debt_tracking_screen.dart
│   │   │       └── payment_screen.dart
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
│   │   │       └── payroll_screen.dart            # Propriétaires uniquement
│   │   │
│   │   └── 📁 finance/                       # ⚠️ PROPRIÉTAIRES UNIQUEMENT
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
│       │   └── role_guard_widget.dart
│       └── 📁 extensions/
│           ├── string_extensions.dart
│           └── datetime_extensions.dart
│
├── 📁 supabase/
│   ├── 📁 migrations/
│   │   ├── 001_create_warehouses.sql
│   │   ├── 002_create_products.sql
│   │   ├── 003_create_raw_materials.sql
│   │   ├── 004_create_recipes.sql             # Recettes de production
│   │   ├── 005_create_inventory.sql
│   │   ├── 006_create_production.sql
│   │   ├── 007_create_suppliers.sql           # Fournisseurs + achats
│   │   ├── 008_create_transfers.sql
│   │   ├── 009_create_sales.sql
│   │   ├── 010_create_employees.sql
│   │   ├── 011_create_finance.sql
│   │   └── 012_create_rls_policies.sql
│   │
│   └── 📁 functions/
│       ├── calculate-daily-production-cost/   # Calcul coût fin de journée
│       │   └── index.ts
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
│   ├── 📁 fonts/
│   └── 📁 i18n/
│       ├── fr.json                            # Traductions françaises
│       └── ar.json                            # الترجمات العربية
│
├── pubspec.yaml
├── .env.example
└── README.md
```

---

## 🗄️ Schéma de Base de Données

### Vue d'ensemble des Tables

```
profiles                — Comptes utilisateurs et rôles
warehouses              — Entrepôts/usines (dynamiques, illimités)
raw_materials           — Matières premières par entrepôt
products                — Catalogue produits finis (chaussures)
recipes                 — Recettes de fabrication par produit
recipe_items            — Lignes de recette (matière + quantité)
inventory               — Niveaux de stock par entrepôt/produit
production_orders       — Ordres de fabrication
production_logs         — Saisies journalières des ouvriers
production_stock_entries— Validations d'entrée en stock (propriétaire)
stock_transfers         — Transferts inter-entrepôts
suppliers               — Fournisseurs (MP et produits finis)
purchase_orders         — Commandes fournisseurs
purchase_order_items    — Lignes de commande fournisseur
supplier_payments       — Paiements aux fournisseurs
clients                 — Clients/acheteurs
invoices                — Factures de vente (en-tête)
invoice_items           — Lignes de facture
payments                — Paiements sur factures clients
employees               — Fiches du personnel
attendance              — Pointage journalier
salary_sheets           — Fiches de paie mensuelles
expenses                — Charges opérationnelles par entrepôt
financial_snapshots     — Synthèses financières mensuelles (propriétaires)
```

---

### Schéma SQL Complet

```sql
-- =============================================
-- WAREHOUSES — Dynamiques, gérés par les propriétaires
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
-- PROFILES (étend Supabase auth.users)
-- Création uniquement via Supabase Dashboard
-- =============================================
CREATE TABLE profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name     TEXT NOT NULL,
  phone         TEXT,
  role          TEXT NOT NULL CHECK (role IN (
                  'owner',
                  'warehouse_manager',
                  'salesperson',
                  'accountant',
                  'stock_keeper',
                  'production_worker'
                )),
  warehouse_id  UUID REFERENCES warehouses(id),  -- NULL = accès tous entrepôts
  is_active     BOOLEAN DEFAULT TRUE,
  preferred_lang TEXT DEFAULT 'fr' CHECK (preferred_lang IN ('fr', 'ar')),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RAW MATERIALS — Matières premières
-- =============================================
CREATE TABLE raw_materials (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  unit          TEXT NOT NULL,       -- mètre, pièce, kg, rouleau...
  warehouse_id  UUID REFERENCES warehouses(id),
  quantity      NUMERIC DEFAULT 0,
  min_quantity  NUMERIC DEFAULT 0,   -- seuil d'alerte
  unit_cost     NUMERIC DEFAULT 0,   -- prix saisi par le propriétaire (facture fournisseur)
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PRODUCTS — Catalogue chaussures
-- =============================================
CREATE TABLE products (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  category      TEXT,               -- homme, femme, enfant, sport...
  size          TEXT,               -- 38, 39, 40, 41, 42...
  color         TEXT,
  material      TEXT,               -- cuir, synthétique...
  sku           TEXT UNIQUE,
  barcode       TEXT UNIQUE,
  selling_price NUMERIC DEFAULT 0,
  image_url     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RECIPES — Recettes de fabrication par produit
-- =============================================
CREATE TABLE recipes (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID NOT NULL REFERENCES products(id),
  name          TEXT NOT NULL,       -- ex: "Recette standard modèle Sport 42"
  is_active     BOOLEAN DEFAULT TRUE,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RECIPE ITEMS — Détail matières d'une recette
-- =============================================
CREATE TABLE recipe_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id       UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  raw_material_id UUID NOT NULL REFERENCES raw_materials(id),
  quantity        NUMERIC NOT NULL,  -- quantité nécessaire par paire
  unit            TEXT NOT NULL
);

-- =============================================
-- INVENTORY — Stock produits finis par entrepôt
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
-- PRODUCTION ORDERS — Ordres de fabrication
-- =============================================
CREATE TABLE production_orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id    UUID REFERENCES warehouses(id),
  product_id      UUID REFERENCES products(id),
  recipe_id       UUID REFERENCES recipes(id),   -- recette utilisée
  ordered_qty     INTEGER NOT NULL,
  produced_qty    INTEGER DEFAULT 0,             -- cumulé des logs
  entered_stock_qty INTEGER DEFAULT 0,           -- validé en stock par le propriétaire
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending','in_progress','completed','cancelled')),
  ordered_by      UUID REFERENCES profiles(id),
  target_date     DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PRODUCTION LOGS — Saisies journalières des ouvriers
-- =============================================
CREATE TABLE production_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID REFERENCES production_orders(id),
  worker_id     UUID REFERENCES profiles(id),
  warehouse_id  UUID REFERENCES warehouses(id),
  quantity      INTEGER NOT NULL,               -- paires produites ce jour
  log_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PRODUCTION COST SUMMARIES — Coût calculé en fin de journée
-- Calculé automatiquement par Edge Function
-- Formule : coût_unitaire = (salaires_journaliers + coût_matières) / paires_produites
-- =============================================
CREATE TABLE production_cost_summaries (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id              UUID REFERENCES production_orders(id),
  warehouse_id          UUID REFERENCES warehouses(id),
  summary_date          DATE NOT NULL DEFAULT CURRENT_DATE,
  total_pairs_produced  INTEGER NOT NULL,
  total_labor_cost      NUMERIC NOT NULL,   -- somme salaires journaliers ouvriers actifs
  total_material_cost   NUMERIC NOT NULL,   -- matières consommées selon recette × qté
  total_cost            NUMERIC GENERATED ALWAYS AS (total_labor_cost + total_material_cost) STORED,
  unit_cost             NUMERIC NOT NULL,   -- total_cost / total_pairs_produced
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(order_id, summary_date)
);

-- =============================================
-- PRODUCTION STOCK ENTRIES — Validation entrée stock (propriétaire)
-- Le propriétaire choisit combien de paires entrent en stock
-- et depuis quel ordre de production
-- =============================================
CREATE TABLE production_stock_entries (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID REFERENCES production_orders(id),
  warehouse_id  UUID REFERENCES warehouses(id),
  product_id    UUID REFERENCES products(id),
  quantity      INTEGER NOT NULL,             -- peut être < produced_qty
  unit_cost     NUMERIC NOT NULL,             -- coût unitaire au moment de l'entrée
  total_cost    NUMERIC GENERATED ALWAYS AS (quantity * unit_cost) STORED,
  approved_by   UUID REFERENCES profiles(id),
  entry_date    DATE DEFAULT CURRENT_DATE,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- SUPPLIERS — Fournisseurs (MP et produits finis)
-- =============================================
CREATE TABLE suppliers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  phone           TEXT,
  address         TEXT,
  city            TEXT,
  supply_type     TEXT DEFAULT 'raw_material'
                  CHECK (supply_type IN ('raw_material','finished_product','both')),
  total_debt      NUMERIC DEFAULT 0,           -- dette envers ce fournisseur
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PURCHASE ORDERS — Commandes fournisseurs
-- =============================================
CREATE TABLE purchase_orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id     UUID NOT NULL REFERENCES suppliers(id),
  warehouse_id    UUID REFERENCES warehouses(id),
  order_type      TEXT NOT NULL
                  CHECK (order_type IN ('raw_material','finished_product')),
  total_amount    NUMERIC NOT NULL DEFAULT 0,
  paid_amount     NUMERIC NOT NULL DEFAULT 0,
  debt_amount     NUMERIC GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending','received','partial','cancelled')),
  ordered_by      UUID REFERENCES profiles(id),
  order_date      DATE DEFAULT CURRENT_DATE,
  received_date   DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PURCHASE ORDER ITEMS — Lignes de commande fournisseur
-- =============================================
CREATE TABLE purchase_order_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  item_type         TEXT NOT NULL CHECK (item_type IN ('raw_material','product')),
  raw_material_id   UUID REFERENCES raw_materials(id),  -- si MP
  product_id        UUID REFERENCES products(id),        -- si produit fini
  quantity          NUMERIC NOT NULL,
  unit_cost         NUMERIC NOT NULL,                    -- prix facture fournisseur
  total_cost        NUMERIC GENERATED ALWAYS AS (quantity * unit_cost) STORED
);

-- =============================================
-- SUPPLIER PAYMENTS — Paiements aux fournisseurs
-- =============================================
CREATE TABLE supplier_payments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id       UUID REFERENCES suppliers(id),
  purchase_order_id UUID REFERENCES purchase_orders(id),
  amount            NUMERIC NOT NULL,
  payment_method    TEXT DEFAULT 'cash'
                    CHECK (payment_method IN ('cash','bank_transfer','cheque')),
  paid_by           UUID REFERENCES profiles(id),
  payment_date      DATE DEFAULT CURRENT_DATE,
  notes             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- STOCK TRANSFERS — Transferts inter-entrepôts
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
-- CLIENTS — Clients / Acheteurs
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
-- INVOICES — Factures de vente
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
-- INVOICE ITEMS — Lignes de facture
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
-- PAYMENTS — Paiements clients
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
-- EMPLOYEES — Personnel
-- =============================================
CREATE TABLE employees (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id      UUID REFERENCES profiles(id),
  warehouse_id    UUID REFERENCES warehouses(id),
  base_salary     NUMERIC NOT NULL,
  daily_rate      NUMERIC GENERATED ALWAYS AS (base_salary / 26) STORED, -- 26 jours/mois
  hire_date       DATE,
  job_title       TEXT,
  national_id     TEXT,
  bank_account    TEXT,
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ATTENDANCE — Pointage
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
-- SALARY SHEETS — Fiches de paie mensuelles
-- =============================================
CREATE TABLE salary_sheets (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id       UUID REFERENCES employees(id),
  warehouse_id      UUID REFERENCES warehouses(id),
  month             INTEGER NOT NULL,
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
-- EXPENSES — Charges opérationnelles
-- =============================================
CREATE TABLE expenses (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id  UUID REFERENCES warehouses(id),
  category      TEXT NOT NULL,  -- loyer, énergie, transport, maintenance...
  amount        NUMERIC NOT NULL,
  description   TEXT,
  expense_date  DATE DEFAULT CURRENT_DATE,
  recorded_by   UUID REFERENCES profiles(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- FINANCIAL SNAPSHOTS — Propriétaires uniquement
-- =============================================
CREATE TABLE financial_snapshots (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id        UUID REFERENCES warehouses(id),  -- NULL = global
  month               INTEGER NOT NULL,
  year                INTEGER NOT NULL,
  total_revenue       NUMERIC DEFAULT 0,
  total_production_cost NUMERIC DEFAULT 0,
  total_purchase_cost NUMERIC DEFAULT 0,
  gross_profit        NUMERIC DEFAULT 0,
  total_expenses      NUMERIC DEFAULT 0,
  net_profit          NUMERIC DEFAULT 0,
  total_salaries      NUMERIC DEFAULT 0,
  total_client_debt   NUMERIC DEFAULT 0,
  total_supplier_debt NUMERIC DEFAULT 0,
  interest_accrued    NUMERIC DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(warehouse_id, month, year)
);
```

---

## 🔐 Politiques RLS (Row Level Security)

```sql
-- Activer RLS sur toutes les tables sensibles
ALTER TABLE financial_snapshots     ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_sheets           ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses                ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_cost_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_stock_entries  ENABLE ROW LEVEL SECURITY;

-- Fonction helper : rôle de l'utilisateur courant
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- Fonction helper : entrepôt de l'utilisateur courant
CREATE OR REPLACE FUNCTION get_user_warehouse()
RETURNS UUID AS $$
  SELECT warehouse_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- SNAPSHOTS FINANCIERS : propriétaires uniquement
CREATE POLICY "owners_only_financial"
ON financial_snapshots FOR ALL
USING (get_user_role() = 'owner');

-- FICHES DE PAIE : propriétaires uniquement
CREATE POLICY "owners_only_salaries"
ON salary_sheets FOR ALL
USING (get_user_role() = 'owner');

-- COÛTS DE PRODUCTION : propriétaires uniquement
CREATE POLICY "owners_only_production_costs"
ON production_cost_summaries FOR ALL
USING (get_user_role() = 'owner');

-- ENTRÉES EN STOCK : propriétaires uniquement (validation)
CREATE POLICY "owners_only_stock_entries"
ON production_stock_entries FOR ALL
USING (get_user_role() = 'owner');

-- INVENTAIRE : personnel voit uniquement son entrepôt
CREATE POLICY "inventory_by_warehouse"
ON inventory FOR SELECT
USING (
  get_user_role() = 'owner'
  OR warehouse_id = get_user_warehouse()
);

-- TRANSFERTS : entrepôts concernés uniquement
CREATE POLICY "transfers_by_warehouse"
ON stock_transfers FOR SELECT
USING (
  get_user_role() = 'owner'
  OR from_warehouse_id = get_user_warehouse()
  OR to_warehouse_id   = get_user_warehouse()
);

-- LOGS DE PRODUCTION : ouvriers voient uniquement leurs propres logs
CREATE POLICY "production_logs_own"
ON production_logs FOR SELECT
USING (
  get_user_role() IN ('owner', 'warehouse_manager')
  OR worker_id = auth.uid()
);
```

---

## 🏭 Logique de Production (Module Central)

### Flux Complet de Fabrication

```
[Propriétaire/Responsable]
        │
        ▼
1. CRÉER ORDRE DE PRODUCTION
   → Choisir produit + recette + quantité cible
   → La recette définit les matières premières nécessaires par paire
        │
        ▼
2. SAISIE JOURNALIÈRE (Ouvriers)
   → Chaque ouvrier saisit ses paires produites ce jour
   → produced_qty s'incrémente dans production_orders
        │
        ▼
3. CALCUL AUTOMATIQUE FIN DE JOURNÉE (Edge Function)
   → Collecte tous les logs du jour pour cet ordre
   → Calcule le coût main d'œuvre :
      total_labor_cost = Σ (daily_rate des ouvriers présents)
   → Calcule le coût matières :
      total_material_cost = Σ (quantité_recette × unit_cost) × paires_produites
   → Calcule le coût unitaire :
      unit_cost = (total_labor_cost + total_material_cost) / paires_produites
   → Sauvegarde dans production_cost_summaries
        │
        ▼
4. VALIDATION ENTRÉE EN STOCK (Propriétaire uniquement)
   → Voir les lots disponibles (produits, pas encore stockés)
   → Choisir la quantité à entrer (peut être partielle)
      Exemple : 200 paires produites → saisir 150 maintenant
   → Confirmer → inventory.quantity mis à jour
   → production_orders.entered_stock_qty mis à jour
```

### Formules de Calcul

```dart
// lib/core/utils/production_cost_calculator.dart

class ProductionCostCalculator {

  /// Coût main d'œuvre journalier pour un ordre donné
  static double dailyLaborCost({
    required List<Employee> activeWorkers,
  }) {
    return activeWorkers.fold(0.0, (sum, w) => sum + w.dailyRate);
  }

  /// Coût matières premières pour N paires selon recette
  static double materialCost({
    required List<RecipeItem> recipeItems,
    required int pairsProduced,
  }) {
    return recipeItems.fold(0.0, (sum, item) =>
      sum + (item.quantity * item.rawMaterial.unitCost * pairsProduced));
  }

  /// Coût unitaire (par paire) = total / quantité produite
  static double unitCost({
    required double totalLaborCost,
    required double totalMaterialCost,
    required int pairsProduced,
  }) {
    if (pairsProduced == 0) return 0;
    return (totalLaborCost + totalMaterialCost) / pairsProduced;
  }
}
```

---

## 📦 Approvisionnement Fournisseurs

Le fournisseur intervient dans **deux contextes distincts** :

| Contexte | Action | Impact Stock |
|----------|--------|--------------|
| Achat **matières premières** | Commande MP → réception → `raw_materials.quantity` ↑ | Stock MP augmente |
| Achat **produit fini** | Commande produit → réception → `inventory.quantity` ↑ | Stock produits finis augmente directement |

Dans les deux cas :
- Le prix unitaire saisi par le propriétaire (depuis la facture réelle) devient le `unit_cost`
- Le solde fournisseur (`suppliers.total_debt`) est mis à jour
- Les paiements partiels sont tracés dans `supplier_payments`

---

## 💰 Logique Financière

### Calcul des Intérêts sur Dettes Clients

```dart
class InterestCalculator {
  static double simpleInterest({
    required double principal,
    required double annualRate,
    required int daysOverdue,
  }) {
    return principal * annualRate * (daysOverdue / 365);
  }

  static double compoundInterest({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final monthlyRate = annualRate / 12;
    return principal * (pow(1 + monthlyRate, months) - 1);
  }

  static double netProfit({
    required double revenue,
    required double productionCost,
    required double purchaseCost,
    required double salaries,
    required double expenses,
  }) {
    return revenue - productionCost - purchaseCost - salaries - expenses;
  }
}
```

### Calcul de la Paie Mensuelle

```
net_salary = base_salary
           - (jours_absents × daily_rate)
           + prime_production
           - autres_déductions
```

---

## ⚡ Synchronisation Temps Réel

```dart
class RealtimeService {
  Stream<List<Map<String, dynamic>>> inventoryStream(String warehouseId) {
    return _supabase
        .from('inventory')
        .stream(primaryKey: ['id'])
        .eq('warehouse_id', warehouseId);
  }

  Stream<List<Map<String, dynamic>>> pendingStockEntriesStream() {
    // Pour le propriétaire : lots en attente de validation
    return _supabase
        .from('production_orders')
        .stream(primaryKey: ['id'])
        .filter('produced_qty', 'gt', 'entered_stock_qty');
  }

  Stream<List<Map<String, dynamic>>> transferRequestsStream(String warehouseId) {
    return _supabase
        .from('stock_transfers')
        .stream(primaryKey: ['id'])
        .eq('to_warehouse_id', warehouseId)
        .eq('status', 'pending');
  }
}
```

---

## 🎨 Philosophie des Interfaces

> L'interface ShoeTrak reflète la logique métier réelle — pas un template générique.

- **Densité d'information** : les écrans métier affichent les données pertinentes sans surcharge
- **Navigation contextuelle** : chaque rôle voit uniquement les modules qui lui sont destinés
- **Feedback immédiat** : toute action critique (validation stock, paiement) demande confirmation
- **Responsive intelligent** : les layouts Desktop et Mobile sont pensés séparément pour chaque contexte d'usage
- **RTL natif** : l'arabe n'est pas une traduction superficielle — l'ensemble du layout bascule

---

## 🔑 Authentification

```dart
class AuthService {
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

  bool get isOwner => currentRole == UserRole.owner;
  bool get isWarehouseManager => currentRole == UserRole.warehouseManager;
}
```

---

## 🚀 Démarrage Rapide

### Prérequis

- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`
- Un projet [Supabase](https://supabase.com)
- Android Studio / VS Code + OpenCode avec MCP Supabase configuré
- Outils de build Windows (pour l'application Desktop)

### Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/your-org/shoetrak.git
cd shoetrak

# 2. Installer les dépendances
flutter pub get

# 3. Copier le fichier d'environnement
cp .env.example .env
# Remplir les credentials Supabase

# 4. Exécuter les migrations SQL
# → Supabase Dashboard → SQL Editor
# → Exécuter chaque fichier de supabase/migrations/ dans l'ordre

# 5. Créer les utilisateurs initiaux
# → Supabase Dashboard → Authentication → Users
# → Créer les comptes et assigner les rôles dans la table profiles

# 6. Lancer l'application
flutter run -d android     # Android
flutter run -d windows     # Windows Desktop
```

---

## 🌍 Variables d'Environnement

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

---

## ☁️ Déploiement

```bash
# APK Android
flutter build apk --release --split-per-abi

# Windows Desktop
flutter build windows --release

# Edge Functions Supabase
supabase functions deploy calculate-daily-production-cost
supabase functions deploy calculate-payroll
supabase functions deploy generate-financial-report
supabase functions deploy calculate-interest
```

---

## 📅 Feuille de Route

```
Phase 1 — Fondations (4–6 semaines)
├── Auth + système de rôles
├── Gestion dynamique des entrepôts
├── Catalogue produits et matières premières
├── Recettes de fabrication
└── Inventaire (temps réel)

Phase 2 — Production & Approvisionnement (4–6 semaines)
├── Ordres de production + saisies ouvriers
├── Calcul automatique des coûts de production
├── Validation entrée en stock (propriétaire)
├── Gestion des fournisseurs (MP + produits finis)
└── Transferts inter-entrepôts

Phase 3 — Ventes & RH (4–6 semaines)
├── Facturation + gestion clients
├── Suivi dettes clients et fournisseurs
├── Gestion des employés
├── Pointage et fiches de paie
└── Enregistrement des charges

Phase 4 — Finance & Finitions (3–4 semaines)
├── Tableau de bord financier (propriétaires)
├── Rapports bénéfices/pertes
├── Calcul des intérêts
├── Export PDF et Excel
├── Scan code-barres
└── Mode hors-ligne
```

---

## 📄 Licence

Privé — Tous droits réservés © 2026 ShoeTrak

---

> Construit avec ❤️ en Flutter + Supabase  
> بُني بـ Flutter + Supabase
