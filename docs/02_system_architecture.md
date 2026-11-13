# Mandi — Clean System Architecture & Modular Design

## 1. Architectural Layers

The Mandi system adheres to Clean Architecture principles, ensuring that business logic is completely decoupled from presentation widgets and external network drivers.

```
+-------------------------------------------------------------------+
|                        Presentation Layer                         |
|   Flutter Material 3 Screens, Modals, Responsive GlassCards,      |
|   Universal TextScaler Lock (1.0 baseline), Pure English/Urdu     |
+-------------------------------------------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|                        State & ViewModel                          |
|   Provider (ChangeNotifier), ChangeNotifierProxyProvider          |
|   Reactive updates triggered by ShopContextProvider               |
+-------------------------------------------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|                    Domain Layer (Contracts)                       |
|   IInvoiceRepository, IAuctionRepository, IFarmerRepository,     |
|   ICustomerRepository, Pure Business Entities & Calculators       |
+-------------------------------------------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|                      Data & Service Layer                         |
|   SupabaseService (PostgreSQL + RLS), OfflineSyncService (SQLite),|
|   BluetoothEscPosService (RFCOMM), LocalAuth (Biometrics)         |
+-------------------------------------------------------------------+
```

## 2. Directory Layout
- `lib/core/services/`: Hardware, telco, biometrics, and cloud storage drivers.
- `lib/domain/repositories/`: Abstract repository contracts.
- `lib/data/repositories/`: Concrete Supabase and local cache implementations.
- `lib/modules/`: 29 domain-driven feature modules with dedicated views and view-models.
- `lib/providers/`: Global multi-tenant identity and session state.
- `supabase/`: Complete PostgreSQL schema with 2,590 lines of DDL, triggers, and Row Level Security.
