# Wave mobile money — analytics engineering

## What this answers

- What is the daily payment volume broken down by country, status, channel,
  merchant category, and KYC tier, and does that hold when reversals arrive late?
- Which wallets have exceeded their monthly KYC transaction limit right now,
  and what is the full transaction detail behind each breach?
- What was the status of any payment at any point in time, and what is the
  reversal rate trend over time?

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
- `stg_payments`: cleaned payments source
- `stg_merchants`: cleaned merchants reference data
- `stg_wallets`: cleaned wallets reference data

### Snapshots (SCD2)
- `snap_wallets`: wallet KYC tier and status history
- `snap_merchants`: merchant category and status history

### Core
- `fct_payments`: one row per payment, current state, dimension attributes resolved at payment time via SCD2
- `fct_payments_history`: one row per payment state change, full reversal audit trail
- `dim_wallets`: current wallet state
- `dim_merchants`: current merchant state

### Intermediate
- `int_compliance_monthly_payments`: current-month success payments with USD conversion, shared by all compliance models

### KPI
- `agg_payments_daily`: pre-aggregated daily KPIs across 7 dimensions, partition-rebuilt on reversal

### Compliance
- `mart_compliance_current`: wallets breaching their KYC monthly limit right now
- `mart_compliance_current_transactions`: transaction detail for each breaching wallet
- `mart_compliance_history`: append log of every breach check
- `mart_compliance_rate_history`: aggregate breach rate per run

---

## Key metric definitions

**Gross volume**: sum of `total_amount` for all non-failed payments
(`status != 'failed'`) for a given date and dimension combination.
Reversed payments are included at their original amount; the reversal shows
up as a separate `status = 'reversed'` row on the same date.

**Net volume**: sum of `total_amount` for `status = 'success'` payments only.
Excludes both failed and reversed payments.

**Monthly KYC volume**: sum of `amount_usd` for `status = 'success'`
transactions in the current calendar month for a given wallet. Reversed
transactions are excluded because a reversal unwinds the original payment.
Converted to USD using the latest available exchange rate on or before the
payment date.

**Breach amount**: `monthly_volume_usd - monthly_limit_usd` for wallets where
that value is positive. KYC limits by tier: tier 0 = $100, tier 1 = $1,000,
tier 2 = $10,000.

**Breach rate**: `breaching_wallets / transacting_wallets` per 15-minute run,
where transacting wallets is the count of distinct wallets with at least one
success payment in the current month.

---


## Run by tag

```bash
# Every 15 minutes
dbt snapshot && dbt build --select tag:every_15m

# Every 60 minutes
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

```bash
dbt build --full-refresh
```
