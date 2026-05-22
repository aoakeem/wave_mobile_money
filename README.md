# Wave mobile money — analytics engineering

dbt project delivering two use cases on Wave mobile money data:

1. **KPI dashboards** — hourly pre-aggregated metrics, historically accurate across reversals
2. **Compliance checks** — 15-minute KYC limit monitoring with a full audit trail

Full architecture and design decisions: [`wave_analytics_design.md`](wave_analytics_design.md)

---

## Setup

```bash
dbt deps     # installs dbt_utils
dbt seed     # loads kyc_limits reference data
dbt snapshot # builds SCD2 dimension history
dbt build    # runs all models and tests
```

---

## Layer structure

Data flows up through four layers:

```
        ┌──────────────────────────────────────────────┐
        │  MARTS                                       │
        │  kpi/        agg_payments_daily              │
        │  compliance/ mart_compliance_*               │
        │  core/       fct_payments, dim_*             │
        ├──────────────────────────────────────────────┤
        │  INTERMEDIATE                                │
        │  int_compliance_monthly_payments             │
        ├──────────────────────────────────────────────┤
        │  SNAPSHOTS                                   │
        │  snap_wallets, snap_merchants  (SCD2)        │
        ├──────────────────────────────────────────────┤
        │  STAGING  (views)                            │
        │  stg_payments, stg_merchants, stg_wallets    │
        ├──────────────────────────────────────────────┤
        │  SOURCES  (raw.*)                            │
        │  payments, merchants, wallets, exchange_rates│
        └──────────────────────────────────────────────┘
```

---

## Models

### Staging
- `stg_payments` — cleaned payments source, view over raw table
- `stg_merchants` — cleaned merchants reference data
- `stg_wallets` — cleaned wallets reference data

### Snapshots (SCD2)
- `snap_wallets` — wallet KYC tier and status history
- `snap_merchants` — merchant category and status history

### Core
- `fct_payments` — one row per payment, current state, dimension attributes resolved at payment time via SCD2
- `fct_payments_history` — one row per payment state change, full reversal audit trail
- `dim_wallets` — current wallet state
- `dim_merchants` — current merchant state

### Intermediate
- `int_compliance_monthly_payments` — current-month success payments with USD conversion, shared by all compliance models

### KPI
- `agg_payments_daily` — pre-aggregated daily KPIs across 7 dimensions, partition-rebuilt on reversal

### Compliance
- `mart_compliance_current` — wallets breaching their KYC monthly limit right now
- `mart_compliance_current_transactions` — transaction detail for each breaching wallet
- `mart_compliance_history` — append log of every breach check
- `mart_compliance_rate_history` — aggregate breach rate per run

---

## Run by tag

```bash
# Every 15 minutes — snapshots + staging + core + compliance
dbt snapshot && dbt build --select tag:every_15m

# Every 60 minutes — KPI aggregation mart
dbt build --select tag:hourly
```

---

## Tests

```bash
dbt test                           # all layers
dbt test --select staging          # staging only
dbt test --select marts.core       # core mart only
dbt test --select marts.compliance # compliance only
dbt test --select marts.kpi        # KPI only
```

---

## Documentation

```bash
dbt docs generate
dbt docs serve      # opens at http://localhost:8080
```

---

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `incremental_lookback_hours` | `3` | Lookback buffer added to the `updated_at` watermark on incremental runs to guard against late-arriving ingestion |

Override at runtime:

```bash
dbt build --vars '{"incremental_lookback_hours": 6}'
```

---

## Full rebuild

To rebuild all incremental models from scratch (e.g. after a schema change):

```bash
dbt build --full-refresh
```
