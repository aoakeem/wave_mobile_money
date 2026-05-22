# Debrief summary — talking points card

> Quick-reference for the walkthrough. Deep responses to every question live in `debrief_prep.md`.

---

## Opening statement (30 s)

> "The brief gives three mutable source tables and two very different consumers: KPI dashboards that need fast, historically accurate aggregates, and a compliance check that needs current correctness on a 15-minute cycle. The common difficulty is mutation — payments get reversed months after the fact, wallet tiers upgrade in place — and most standard patterns don't handle that gracefully at billion-row scale. The solution is a layered model where each materialization decision is driven by data volume, freshness requirement, and how mutation works in that specific source."

---

## Requirements met

| Requirement | How it is met |
|---|---|
| Hourly KPI freshness | `agg_payments_daily` tagged `hourly`; runs on the 60-min schedule |
| 15-min compliance freshness | All compliance models tagged `every_15m`; full replace on every run |
| Current KPI values | `agg_payments_daily` always reflects the latest merged state of `fct_payments` |
| Historical KPI values | `delete+insert` on `payment_date` re-aggregates the original date when a reversal arrives — reversals land on the date they happened, not the date they were reversed |
| Breakdown by 5 dimensions | Grain: `(payment_date, country, currency, status, channel, merchant_category, kyc_tier)` — all five requested dimensions are first-class columns |
| Dimension values at payment time | `fct_payments` date-range joins against `snap_wallets` and `snap_merchants` (SCD2) so `kyc_tier` and `merchant_category` reflect what was true when the payment was made |
| Breach list contracts on reversal | Compliance tables are materialised as `table` — full replace every 15 min — so a wallet that falls below its limit exits immediately with no extra logic |
| Audit trail for reversals | `fct_payments_history` — incremental `delete+insert` keyed on `(payment_id, version_valid_from)` — records every status transition without the full-scan cost of `dbt snapshot` |
| Performance | Pre-aggregation: dashboard reads `agg_payments_daily`, never the raw billion-row fact. Clustering on `(updated_at::date, payment_date)` covers both the incremental filter scan and the reversal re-aggregation scan |

---

## Trade-offs

**1. Latest-available FX rate vs strict freshness**
> "I chose pipeline availability over strict rate freshness. The fallback uses the most recent rate on or before the payment date, so a missing today's rate never blocks a compliance run. For regulated reporting you'd want a hard failure on stale rates. For analytics, silently using yesterday's rate is the lesser evil. The `amount_usd IS NOT NULL` test on `mart_compliance_current_transactions` surfaces any completely uncovered currency rather than under-counting silently."

**2. Breaching-only compliance history vs full coverage**
> "Storing every wallet's monthly volume on every 15-minute run is roughly 4 runs/hour × 24 hours × millions of wallets — billions of rows a month with almost no signal. I store only breaching wallets in `mart_compliance_history`. The denominator — total transacting wallets, breach rate — goes into `mart_compliance_rate_history` separately, so we can prove the system was running and most wallets were compliant. If a regulator required positive evidence of compliance for every wallet, the structure changes to a daily snapshot, but that is a different requirement than what was scoped."

**3. Current `kyc_tier` vs period-min tier**
> "Since tiers only increase, the current tier is also the highest limit the wallet has ever held — the most lenient interpretation that is still regulator-defensible. If a tier were ever revoked, the whole model would need to evaluate against `min(tier over the evaluation period)` from `snap_wallets`. The SCD2 history is already available to support that change; it is a one-model update."

**4. Inner join on `kyc_limits` — silent null-tier drop**
> "A wallet with `kyc_tier = null` falls out of `mart_compliance_current` silently. In practice every wallet should carry at least tier 0, so the failure mode is upstream data quality, not model logic. The right defence is a `not_null` test on `kyc_tier` in `stg_wallets` that fails the build before the compliance model runs against bad data. A left join with coalesce would mask the issue — worse for a compliance system."

---

## Testing patterns

**Layer 1 — Structural**
- `unique + not_null` on all primary keys: `payment_id`, `merchant_id`, `wallet_id`
- `relationships`: `stg_payments.merchant_id → stg_merchants`; `mart_compliance_current_transactions.wallet_id → mart_compliance_current`

**Layer 2 — Domain**
- `accepted_values` on `status` (success/failed/reversed), `channel` (ussd/app/agent), `kyc_tier` (0/1/2), `merchant_category` (supermarket/ecommerce/taxi/utility/other), wallet `status` (active/inactive/blocked)

**Layer 3 — Business rules** (via `dbt_utils.expression_is_true`)
- `amount >= 0` on `stg_payments`
- `payment_count > 0` on `agg_payments_daily`
- `monthly_volume_usd > 0` and `breach_amount_usd > 0` on compliance models
- `amount_usd IS NOT NULL` on `mart_compliance_current_transactions` — canary for FX coverage gaps

**Cost-proportional scoping**
> "Heavy uniqueness tests on `stg_payments` and `fct_payments` are `WHERE`-scoped to the last 24 hours. Running `count(distinct payment_id)` over a billion rows on every CI run is expensive and catches nothing that the 24-hour version misses — ingestion duplicates show up in the recent window."

**What is missing and why**
> "`dbt source freshness` — 30-min warn / 1-hr error on all three sources given the 15-minute ingestion cycle. It is the single highest-value test I'd add. I scoped it out because the brief was about modeling design, not operational monitoring, but in a production handover it is non-negotiable and would be ticket one on day one."

---

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| `dbt snapshot` on payments | Full-scans source and target on every run; cost tracks table size not change volume. At 1B+ rows / 15 min a single run exceeds its own interval. `fct_payments_history` achieves the same audit trail incrementally, paying only for what changed. |
| Microbatch incremental | Partitions on `created_at`. Reversals mutate `updated_at` on records whose `created_at` may be months old — any fixed lookback window misses them. |
| Hourly aggregation grain | One reversal could touch hundreds of historical hourly buckets. Daily grain confines re-aggregation to one affected date per reversal, bounding the cost. |
| All wallets in compliance history | 4 runs/hour × 24 hours × millions of wallets ≈ billions of rows per month with almost no breach signal. `mart_compliance_rate_history` captures the denominator; breach history stores only the events that matter. |

---

## Industry best-practice signals

- **Layering with intent** — staging (views, always current, zero cost) → snapshots (SCD2 for small mutable dimensions) → core (incremental fact + change history) → marts (divergent paths per consumer). Each layer exists because of a specific need, not convention.
- **Operability** — `incremental_lookback` macro centralises the watermark window. Widening it for an incident response is one variable in `dbt_project.yml`, not five PRs.
- **Separation of concerns** — `fct_payments` (current state: "what is the status of payment X now?") vs `fct_payments_history` (change log: "what was the reversal rate last quarter?"). Different consumer questions deserve different models.
- **Seeds for thresholds** — `kyc_limits.csv` so regulatory limit changes don't require a code release or a data engineer.
- **Documentation as a deliverable** — every model and column has a description in its schema YAML. `dbt docs generate` produces a browsable catalogue; descriptions include grain, materialization strategy, and known limitations.
- **Orchestration ordering** — snapshots run before the fact table build so `fct_payments` always joins against current SCD2 history. The `&&` in the orchestration command fails the whole job if the snapshot step fails, preventing stale dimension joins.

---

## Reversal scenario end-to-end (for the walkthrough)

> "Reversal arrives at 14:03 for a payment originally created on March 5th. At 14:15 the `fct_payments` merge picks it up via `updated_at` watermark and overwrites the row — status now `reversed`. At 15:00 `agg_payments_daily` runs. The `incremental_lookback` macro finds March 5th in the set of dates where any payment has `updated_at >= watermark`. It deletes all `agg_payments_daily` rows where `payment_date = '2024-03-05'`, then re-aggregates all `fct_payments` rows for that date and inserts fresh. The KPI for March 5th now correctly reflects the reversed status."

---

## Closing invitation

> "That is the overview. Happy to go deep on any of the decisions — the incremental strategies, the compliance correctness guarantees, the SCD2 approach, or the orchestration ordering. Where would you like to start?"

---

## Self-critique opener (if asked about weaknesses)

> "Honestly, three things. First, no `dbt source freshness` — that is the single test I'd add before anything else. Second, the snapshot bootstrap leaves a window of unrecoverable history that I handled with `'unknown'` rather than a proper backfill. Third, the inner join on `kyc_limits` silently drops null-tier wallets — the right defence is a staging test that fails the build before bad data reaches the compliance models. None of these are subtle. They are the first three tickets I'd raise on day one."
