# 🏨 PostgreSQL Hotel Booking System Nusantara

## 📊 Overview
**PostgreSQL-Hotel-Booking-System-Nusantara** adalah sistem database lengkap untuk manajemen hotel di Indonesia. Dibangun dengan PostgreSQL, sistem ini menangani seluruh operasional hotel mulai dari reservasi, check-in/out, billing, housekeeping, hingga reporting analytics.

## 🎯 Fitur Utama
| Fitur | Deskripsi | Status |
|-------|-----------|--------|
| 📅 **Smart Booking System** | Reservasi dengan validasi real-time & anti double booking | ✅ |
| 👥 **Guest Management** | Data tamu lengkap + preferensi + loyalty program | ✅ |
| 💰 **Dynamic Pricing Engine** | Tarif berdasarkan musim, weekend, hari libur nasional | ✅ |
| 💳 **Indonesian Payment Methods** | QRIS, Virtual Account, Transfer, EDC, Kartu Kredit | ✅ |
| 🧹 **Housekeeping Tracking** | Status kebersihan & maintenance kamar real-time | ✅ |
| 📊 **Real-time Dashboard** | Live occupancy rate, revenue, performance metrics | ✅ |
| 👨‍💼 **Staff Management** | Shift management, role-based access, performance tracking | ✅ |
| 🔐 **Enterprise Security** | Audit trail, data validation, constraint enforcement | ✅ |

## 🏗️ Architecture
```
Application Layer
    │
    ├── Backend API (Node.js/Go/Java)
    │
Database Layer (PostgreSQL)
    ├── Core Tables (12 tables)
    ├── Business Logic (Functions & Triggers)
    ├── Reporting Views (12 views)
    └── Security Policies
```

## 🚀 Quick Start

### Prerequisites
- PostgreSQL 13+
- Extensions: `btree_gist`, `uuid-ossp`, `pg_stat_statements`, `tablefunc`

### Installation
```bash
# 1. Clone repository
git clone https://github.com/epsantoso/postgresql-hotel-booking-system-nusantara.git
cd postgresql-hotel-booking-system-nusantara

# 2. Run setup script
psql -U postgres -f 00_database_setup.sql

# 3. Connect to database and run remaining scripts
psql -U postgres -d hotel_nusantara -f 01_types.sql
psql -U postgres -d hotel_nusantara -f 02_tables.sql
# ... run all files in numerical order
```

### One-Command Installation
```bash
chmod +x install.sh
./install.sh
```

## 📁 Project Structure
```
PostgreSQL-Hotel-Booking-System-Nusantara/
├── 00_database_setup.sql      # Database & extensions setup
├── 01_types.sql              # Custom ENUM types
├── 02_tables.sql             # Core tables (12 tables)
├── 03_constraints.sql        # Business rules enforcement
├── 04_indexes.sql            # Performance optimization (40+ indexes)
├── 05_functions.sql          # Business logic functions
├── 06_triggers.sql           # Automation triggers
├── 07_views.sql              # Reporting views (12 views)
├── 08_seed_data.sql          # Sample data for testing
├── 09_stored_procedures.sql  # Complex operations
├── 10_showcase_queries.sql   # Example analytics queries
├── install.sh                # Installation script
├── README.md                 # File readme
├── LICENSE                   # File license
├──.gitignore                 # File gitignore
├── technical_detail.md       # This file

```

## 🎨 Database Schema

### Core Entities
```sql
-- Main tables with relationships
kamar ───┐
tamu ─────┼── pemesanan ─── detail_pemesanan_kamar
staff ───┘          │
           pembayaran ─── registrasi_tamu
```

### Sample Queries

#### 1. Check Room Availability
```sql
-- Real-time room availability
SELECT * FROM view_kamar_tersedia_realtime;

-- Check specific dates
SELECT * FROM fn_cek_ketersediaan_cepat(
    '2024-12-24',  -- check_in
    '2024-12-26',  -- check_out
    'deluxe'       -- room_type (optional)
);
```

#### 2. Create New Booking
```sql
-- Complete booking process
SELECT * FROM fn_proses_pemesanan_lengkap(
    1,                    -- guest_id
    '2024-12-24',        -- check_in
    '2024-12-26',        -- check_out
    2,                    -- total_guests
    2,                    -- adults
    1,                    -- staff_id
    ARRAY[101, 102],     -- room_ids
    'qris',              -- payment_method
    500000,              -- deposit
    'No smoking room'    -- special_request
);
```

#### 3. Daily Operations Dashboard
```sql
-- Front desk dashboard
SELECT * FROM view_dashboard_harian;

-- Today's check-ins
SELECT * FROM view_checkin_hari_ini;

-- Today's check-outs
SELECT * FROM view_checkout_hari_ini;

-- Quick check-in
SELECT * FROM fn_quick_checkin('BOOKING-12345', 1);
```

#### 4. Business Analytics
```sql
-- Monthly reports
SELECT * FROM view_laporan_bulanan;

-- Revenue analysis
SELECT * FROM view_revenue_per_tipe_kamar;

-- Guest analytics
SELECT * FROM view_top_tamu;

-- Staff performance
SELECT * FROM view_staff_performance;
```

## 🇮🇩 Indonesian Features

### Local Payment Methods
```sql
-- Supported payment methods
'tunai'          -- Cash
'transfer'       -- Bank transfer
'kartu_kredit'   -- Credit card
'qris'           -- QRIS (Indonesian QR standard)
'edc'            -- EDC machine
'virtual_account'-- Virtual account
```

### Room Types for Indonesian Market
```sql
'standard'    -- Standard room (AC, TV, WiFi)
'deluxe'      -- Deluxe room (AC, TV, WiFi, Bathub)
'suite'       -- Suite room (Living area)
'keluarga'    -- Family room (2 double beds)
'presiden'    -- President suite (Luxury)
'villa'       -- Separate villa
'bungalow'    -- Traditional bungalow
```

### Guest Preferences
```json
{
  "merokok": false,
  "lantai_tinggi": true,
  "dekat_lift": false,
  "kamar_pedas": false,    -- Indonesian spice preference
  "tipe_bed": "double",
  "sarapan": true,
  "koran_pagi": true,
  "wifi_priority": false
}
```

## ⚡ Performance Features

### Advanced Indexing Strategy
- **B-Tree** - Primary & foreign keys
- **BRIN** - Time-series data (bookings, payments)
- **GIN** - JSONB fields & full-text search
- **Partial Indexes** - Conditional queries

### Generated Columns
```sql
-- Automatically calculated fields
harga_weekend NUMERIC GENERATED ALWAYS AS (harga_standar * 1.2) STORED
jumlah_malam INTEGER GENERATED ALWAYS AS (check_out - check_in) STORED
occupancy_rate NUMERIC GENERATED ALWAYS AS (kamar_terisi / total_kamar * 100) STORED
```

### JSONB for Flexible Schema
```sql
-- Room facilities as JSONB
fasilitas JSONB DEFAULT '{
  "ac": true,
  "tv": true,
  "kulkas": false,
  "bathub": false,
  "wifi": true,
  "breakfast": true
}'
```

## 📊 Sample Data Included

| Data Type | Count | Description |
|-----------|-------|-------------|
| Rooms | 15 | Various types & prices |
| Guests | 8 | Different preferences & tiers |
| Staff | 8 | Multiple departments |
| Bookings | 8 | Various statuses |
| Payments | 11 | Sample transactions |
| Facilities | 17 | Food, laundry, transport, etc. |
| Daily Reports | 3 | Sample analytics |

## 🔧 Maintenance & Operations

### Daily Tasks
```sql
-- Check today's occupancy
SELECT occupancy_rate_hari_ini FROM view_dashboard_harian;

-- Rooms needing cleaning
SELECT * FROM view_maintenance_schedule WHERE status_tindakan != 'Ready';

-- Pending payments
SELECT COUNT(*) FROM pembayaran WHERE status_bayar = 'pending';
```

### Monthly Reports
```sql
-- Generate monthly report
SELECT * FROM fn_generate_laporan_bulanan(CURRENT_DATE, 1);

-- Update pricing for next month
SELECT * FROM fn_update_harga_massal(
    'deluxe',
    DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month'),
    DATE_TRUNC('month', CURRENT_DATE + INTERVAL '2 month') - INTERVAL '1 day',
    5,    -- Increase by 5%
    1     -- Staff ID
);
```

## 🛡️ Security & Compliance

### Audit Trail
Every table includes:
```sql
created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
created_by INTEGER,  -- Staff who created
updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
updated_by INTEGER   -- Staff who last updated
```

### Data Validation
```sql
-- Business rule enforcement
CHECK (check_in < check_out)
CHECK (deposit >= 0 AND deposit <= total_harga)
CHECK (kapasitas BETWEEN 1 AND 6)
CHECK (status_pemesanan IN ('menunggu', 'terkonfirmasi', 'check_in', 'check_out', 'dibatalkan'))
```

## 📈 Key Performance Indicators (KPIs)

| KPI | Formula | Target |
|-----|---------|--------|
| Occupancy Rate | `(rooms occupied / total rooms) × 100` | > 70% |
| ADR | `total revenue / rooms sold` | Maximize |
| RevPAR | `total revenue / total rooms` | Optimize |
| Cancellation Rate | `(cancellations / total bookings) × 100` | < 5% |
| Guest Satisfaction | `(positive reviews / total reviews) × 100` | > 90% |

### KPI Calculation Queries
```sql
-- Monthly KPI dashboard
SELECT 
    ROUND(AVG(occupancy_rate), 2) as avg_occupancy,
    ROUND(AVG(adr), 2) as avg_adr,
    ROUND(AVG(revpar), 2) as avg_revpar,
    ROUND(MAX(cancellation_rate), 2) as max_cancellation
FROM view_laporan_bulanan
WHERE bulan >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '6 months';
```

## 🚀 Scaling Considerations

### For Small Hotels (< 50 rooms)
- Use as-is
- Single PostgreSQL instance
- Basic backup strategy


## 🔍 Troubleshooting

### Common Issues & Solutions

1. **"Room already booked" error**
   ```sql
   -- Check room availability
   SELECT * FROM view_kamar_tersedia_realtime WHERE nomor_kamar = '101';
   
   -- Check existing bookings
   SELECT * FROM pemesanan WHERE id_kamar = 1 
   AND CURRENT_DATE BETWEEN check_in AND check_out;
   ```

2. **Slow query performance**
   ```sql
   -- Check index usage
   SELECT schemaname, tablename, indexname, idx_scan
   FROM pg_stat_user_indexes
   WHERE idx_scan = 0;
   
   -- Analyze slow queries
   SELECT query, calls, total_time, mean_time
   FROM pg_stat_statements
   ORDER BY mean_time DESC
   LIMIT 10;
   ```

3. **Data inconsistency**
   ```sql
   -- Run data validation
   SELECT * FROM fn_validate_data_consistency();
   
   -- Check foreign key violations
   SELECT * FROM pemesanan 
   WHERE id_tamu NOT IN (SELECT id_tamu FROM tamu);
   ```


## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👥 Authors

- **Eko Puji Santoso** - *Initial work* - [GitHub Profile](https://github.com/epsantoso)


## 🏆 Why This Project Stands Out

### Technical Excellence
- ✅ **Production-ready** database design
- ✅ **Indonesian market** specific features
- ✅ **Performance optimized** from the start
- ✅ **Comprehensive** with 12 tables + 12 views
- ✅ **Real-world** sample data included

### Business Value
- 🏨 **Direct application** to hotel industry
- 💰 **Revenue optimization** features
- 📊 **Business intelligence** built-in
- 🔐 **Compliance ready** with audit trails
- 🌏 **Localized** for Indonesian market

---


**Version:** 1.0.0  
**Last Updated:** November 2025  
**Compatibility:** PostgreSQL 13+  
**Status:** ✅ Production Ready