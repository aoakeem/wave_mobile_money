# Senior analytics engineer debrief prep

---

## 1. Senior-level review

### What works well

- **Reversal handling is genuinely thought through.** The `created_at` vs `updated_at` distinction is correctly applied: `fct_payments` merges on `payment_id` watermarked by `updated_at`, and `agg_payments_daily` re-aggregates the original `payment_date` when a reversal arrives. Most candidates miss this asymmetry.
- **SCD2 for dimensions but not payments.** Recognising that snapshots don't scale to 1B rows is senior-level judgment. `fct_payments_history` is a credible incremental substitute.
- **Pre-aggregation as the performance answer.** Clean fact/aggregate separation; reversals reconcile on the original payment date; the BI query pattern is documented.
- **Compliance correctness via full-replace tables.** You correctly identified that breach lists must contract, not just grow. `table` over `incremental` is the right call and you can defend it.
- **Layered structure with intent.** Staging (views) → core (SCD2 + facts) → KPI mart → compliance mart. The intermediate layer deduplicates the FX join, not just exists by habit.
- **Configurable lookback macro.** Centralising the watermark filter and parameterising it via `dbt_project.yml` shows you think about operability.

---

### Modeling risks and gaps

Each gap is followed immediately by how to respond if it is raised.

---

**Gap 1: `mart_compliance_current` excludes null-tier wallets via inner join.**
A wallet with `kyc_tier = null` silently drops out of the breach list. For a compliance system that is a real correctness gap.

> **If raised - response (acceptable known limitation + next iteration):**
> "In practice every wallet should have a tier of at least 0, so the failure mode is upstream data quality rather than the model logic itself. The right defence is a test in staging asserting `kyc_tier is not null` on `stg_wallets` - that fails the build before the compliance model runs against bad data. I'd add that as a priority-one follow-up. Changing the inner join to a left join with a coalesce would mask the data quality issue silently, which I'd argue is worse for a compliance system."

---

**Gap 2: `mart_compliance_history` stores only breaching wallets, not "checked and clean" evidence.**
An auditor asking for positive evidence that a wallet was checked and compliant has no record to point to.

> **If raised - response (deliberate trade-off):**
> "That was a deliberate choice. Writing every wallet's monthly volume on every 15-minute run is roughly 4 runs/hour x 24 hours x millions of wallets - billions of rows a month, almost all showing no breach. Signal-to-noise is terrible and it scales badly. `mart_compliance_rate_history` separately captures the denominator so we can prove the system was running and most wallets were compliant. If the regulator specifically required positive evidence of compliance for every wallet, the structure changes - probably a daily snapshot rather than a 15-min one - but that is a different requirement than what was scoped."

---

**Gap 3: `agg_payments_daily.kyc_tier` is varchar with `'unknown'` fallback; `fct_payments.kyc_tier` is int.**
Type and value-set divergence between fact and aggregate creates a join hazard for downstream consumers.

> **If raised - response (deliberate trade-off with acknowledgment):**
> "I cast to varchar specifically because I needed an `'unknown'` bucket for the snapshot bootstrap case - payments that predate the first snapshot run have no resolvable tier. Keeping it as int would force null, and every dashboard query would need null handling. The cost is the type divergence. If I were doing this again I'd introduce a sentinel value like `-1` for unknown to keep the type consistent, or solve it properly with a historical backfill at snapshot inception so `'unknown'` never exists."

---

**Gap 4: SCD2 snapshot bootstrap - dimension values before inception are unrecoverable.**
Wallets and merchants that mutated before the first snapshot run will show null or `'unknown'` tier/category on historical KPI breakdowns forever.

> **If raised - response (acceptable known limitation):**
> "It is the standard SCD2 bootstrap problem. The mitigation in production is a one-time historical backfill from any available source - audit logs, the operational database's own change log, or reconstructing best-effort from related tables. For the take-home I documented it as a known limitation rather than building the backfill, since it is a one-time concern that diminishes as snapshot history accumulates."

---

**Gap 5: `updated_at` is the only change signal - fragile if the source does non-functional updates.**
If the source system updates `updated_at` for maintenance reasons, we reprocess rows unnecessarily. At billion-row scale that is an incident.

> **If raised - response (acceptable known limitation + next iteration):**
> "It works because the source contract is 'updated_at changes if and only if status changes'. The defensive long-term answer is to ask the source team for an explicit change-type field, or to move to CDC via Snowflake streams which keys off the actual change event rather than a column value. That is specifically the next architectural step I called out."

---

**Gap 6: No `dbt source freshness` test.**
Ingestion lag - the most common production incident - would go undetected until downstream consumers notice stale data.

> **If raised - response (next iteration - own it flat):**
> "Yes, that is a gap. `dbt source freshness` should be configured on all three sources with a 30-minute warn / 1-hour error threshold given the 15-minute ingestion cycle. It would be the single highest-value test I'd add. I scoped it out because the brief was about modeling design, not the operational monitoring surface, but in a production handover this is non-negotiable."

---

**Gap 7: `current_timestamp()` in `mart_compliance_current` is non-deterministic across runs.**
Two incremental rebuilds of the same data state produce different `checked_at` values. `mart_compliance_rate_history` correctly sources its `checked_at` from `mart_compliance_current`, so they stay aligned within a single run - but a strict audit trail requires a stable run identifier.

> **If raised - response (acceptable known limitation with calibration):**
> "For analytics-grade auditability the wall-clock timestamp is fine - analysts can reconstruct which run produced which rows from the approximate timestamp. For SOX-grade or regulatory-grade auditability you'd want `dbt_invocation_id()` or an externally injected run timestamp passed as a variable so every row in every table produced by the same run carries the same identifier. Calibrated for the brief, wall-clock is sufficient."

---

**Gap 8: `unique_key = 'payment_date'` in `agg_payments_daily` is a delete key, not a grain uniqueness key.**
The config name is potentially confusing on a code review - the actual grain is the full dimension combination in the group-by clause.

> **If raised - response (deliberate trade-off with precision):**
> "dbt's `unique_key` in `delete+insert` mode is a partition key for deletion, not a uniqueness assertion on resulting rows. I am using `payment_date` as the delete target because that is the granularity at which reversals require re-aggregation. I documented this explicitly in the model YAML description - 'delete key, not the true grain' - because I knew the naming would raise questions on a code review."

---

## 2. Explaining technical choices

### Materialization choices

> "Every materialization decision was a function of three variables - data volume, freshness requirement, and how mutation works in the source. Views for staging because they cost nothing and stay current. Snapshots for wallets and merchants because the entities mutate in place and the tables are small enough to full-scan every 15 minutes. Incremental merge for `fct_payments` because the entity mutates in place and the table is too large to full-scan. Incremental delete+insert for `agg_payments_daily` because aggregation has no natural row-level merge key. Full-replace tables for compliance because the breach list has to contract as well as grow on each run."

### How you handled late-arriving data and updates

> "All incremental models use the `incremental_lookback` macro which filters on `updated_at >= max(watermark) - N hours`. N is a project variable, currently 3. For `agg_payments_daily` the macro takes an explicit watermark column because the filter column on the source (`updated_at`) differs from the stored watermark (`max_source_updated_at`). The lookback gives a buffer for ingestion drift without re-processing the world. Beyond the window, recovery is `--full-refresh`."

### How you would scale this

> "Three levers. First, replace watermark-based incremental with native CDC - Snowflake streams on source tables process only rows that actually changed, with no scan at all. Second, partition `fct_payments` more aggressively by month and let Snowflake prune; right now clustering on `(updated_at::date, payment_date)` handles this at a coarser granularity. Third, separate the read path from the write path - today the dashboard reads `agg_payments_daily` directly; at higher query load you'd add a materialized view or move the aggregate to a serving layer optimised for low-latency reads."

---

## 3. Likely questions and senior-grade answers

**"What were the main trade-offs you made?"**

> "Three explicit ones. Latest-available-rate FX fallback instead of failing on missing rates - prioritises pipeline availability over strict freshness, which is right for analytics but might not be right for regulated reporting. Storing only breaching wallets in compliance history instead of every wallet's monthly volume - scales well but loses positive compliance evidence. Current tier for compliance evaluation instead of tier at month-start - the most lenient regulator-defensible interpretation, but not the only valid one."

---

**"What would you improve with more time?"**

> "Four things in priority order. First, source freshness tests - `dbt source freshness` before anything else. Second, an integration test harness on DuckDB with synthetic data that proves reversal correctness, tier upgrade behaviour, and breach contraction. Third, treat the snapshot bootstrap properly with a historical backfill of wallet and merchant change history. Fourth, replace the correlated FX subquery with an `asof` join or window function - it works at one month of compliance payments but will not scale to backfills."

---

**"How would you test this model?"**

> "Three layers. dbt tests at every model - structural (unique, not_null), domain (accepted_values), and business rules (`expression_is_true` for things like `amount >= 0`, `breach_amount_usd > 0`). Heavy uniqueness tests on `stg_payments` and `fct_payments` are scoped to the last 24 hours to avoid billion-row scans on every run - they catch the real failure mode (ingestion duplicates) without scanning unchanged history. Then `dbt source freshness` for ingestion lag. Finally, integration tests with synthetic data that exercise specific scenarios: a reversal of an old payment, a mid-month tier upgrade, a wallet that breaches then drops below its limit after a reversal."

---

**"How would you monitor data quality in production?"**

> "Four signals. dbt test results in CI and on every scheduled run, failing the build on critical-tier tests. `dbt source freshness` monitored continuously. Anomaly detection on row counts and key metrics in `mart_compliance_rate_history` - a sudden 10x spike in breach rate is either a data quality issue or a real compliance event, both worth alerting on immediately. And a watermark-lag metric: `current_timestamp - max(max_source_updated_at)` in `agg_payments_daily`; if that exceeds the expected interval the pipeline is silently behind."

---

**"How would you handle changing business requirements - per-country KYC limits, for example?"**

> "The `kyc_limits` seed gains a `country` column. The join in `mart_compliance_current` becomes `on w.kyc_tier = l.kyc_tier and w.country = l.country` with a fallback row for a default country for markets not explicitly listed. No other model changes. That is specifically why I kept limits as a seed instead of hardcoding - regulatory thresholds change and should not require a code release."

---

**"How would you explain this to a non-technical stakeholder?"**

> "I would skip materializations entirely. Payments can be reversed up to a year after they happen, so the system has to correct old numbers when reversals arrive without rebuilding everything from scratch. For the daily dashboard, we pre-calculate the numbers you care about so they load instantly, and we re-calculate any day where a reversal landed. For compliance, we check every customer's monthly total against their limit every 15 minutes. The breach list is always current - it adds new breaches and removes customers whose totals dropped after a reversal. There is a separate historical log so we can show regulators the full trail."

---

## 4. Framing - junior vs senior

| Junior framing | Senior framing |
|---|---|
| "I used delete+insert because reversals can be old" | "Aggregate models have no row-level merge key. The choice is between full-rebuild and partition-rebuild. I chose partition-rebuild on `payment_date` because rebuilding the world is uneconomical but rebuilding the affected dates is bounded by reversal volume." |
| "I added `fct_payments_history` for auditability" | "I separated current-state from change-history because the consumer questions are different. 'What is the current status of payment X?' and 'Show me the reversal rate by month' are not the same query. Co-locating them forces every query to filter and degrades both." |
| "I used a macro to avoid duplication" | "I centralised the watermark logic because the lookback window is an operational parameter, not a model parameter. If we need to widen it for an incident response, that change is one var, not five PRs." |
| "Tests on uniqueness ensure data quality" | "Test cost has to be proportional to value. Running `count(distinct payment_id)` over a billion rows on every CI run is expensive and catches nothing that the 24-hour scoped version misses. I scoped it to recent data - it catches the actual failure mode, ingestion duplicates, without scanning unchanged history." |
| "I assumed exchange rates exist" | "The brief does not provide a USD conversion source, but compliance limits are USD-denominated, so I introduced `exchange_rates` as an explicit assumption. In production I would confirm whether that table already exists and what its freshness SLA is - my compliance SLA cannot be tighter than the rate feed." |

### Phrases to retire

- "I think" / "I believe" - replace with "I chose, because..."
- "It should work" - replace with "It handles X correctly because..."
- "I just" - drop it
- "Simple" / "easy" - these undersell deliberate decisions

### Phrases that signal seniority

- "The trade-off was..."
- "I deliberately rejected... because..."
- "In production I'd also want..."
- "That assumption needs to be validated with the source team."
- "The failure mode I'm protecting against is..."
- "Calibrated for analytics-grade rather than audit-grade..."

---

## 5. Tough follow-up questions

**"What happens if `dbt snapshot` fails but the 15-min build runs anyway?"**
`fct_payments` joins against stale SCD2 history. The `&&` in the orchestration command fails the whole job if snapshot fails. In production I'd also want the orchestrator to page on partial job failure.

---

**"Your `agg_payments_daily` is partitioned by `payment_date`. What if the source has been double-publishing reversals as separate events?"**
`fct_payments` would have duplicate `payment_id` rows. The uniqueness test (scoped to 24h) catches it. The fix is deduplication in staging by latest `updated_at` per `payment_id` until the source is corrected.

---

**"Walk me through what happens to compliance on the 1st of the month at 00:01."**
`int_compliance_monthly_payments` filters on `date_trunc('month', created_at) = date_trunc('month', current_date)`. At 00:01 on the 1st there are no current-month payments. `mart_compliance_current` is empty. `mart_compliance_history` appends nothing. `mart_compliance_rate_history` gets a row with `transacting_wallets = 0` and `breach_rate = null`. The previous month's final state is preserved as the last append before midnight.

---

**"How do you know the model produces correct numbers? What is your reconciliation strategy?"**
Three reconciliation points: sum of `payment_count` in `agg_payments_daily` for a date must equal `count(*)` from `fct_payments` for that date. Sum of `total_amount` per `(date, currency, status)` must match source. On compliance, sum of `monthly_volume_usd` across `mart_compliance_current_transactions` for a wallet must equal `monthly_volume_usd` on `mart_compliance_current` for that wallet. I'd codify these as nightly audit queries.

---

**"What if a payment has a future `created_at`?"**
It enters `fct_payments` on the next 15-min run and lands on a future `payment_date` in `agg_payments_daily`. That is likely a data quality issue worth alerting on. Easy add: a test that `created_at <= current_timestamp` on `stg_payments`.

---

**"You said tiers only increase. What if that assumption breaks - a tier is revoked?"**
The whole compliance model breaks silently - current tier is always treated as the highest limit ever held. The defensive fix is to evaluate compliance against `min(tier over the evaluation period)` from `snap_wallets`. That is a one-model change and the SCD2 history is already available to support it.

---

**"How would this change on BigQuery or Databricks?"**
On BigQuery: replace `cluster_by` with `partition_by payment_date` plus `cluster by updated_at`; watch streaming write cost on 15-min compliance jobs. On Databricks/Delta: replace incremental merge with `MERGE INTO` and use Z-ordering instead of clustering. The dbt code stays largely portable via adapter dispatch; materialization configs and merge keys are the main adjustment points.

---

**"You expose `is_agent` as a column but do no separate analysis on it. Why?"**
Filterable optionality without committing to a model split. The brief is silent on whether agents should be excluded from KPI rollups or subject to different limits. I expose the column on all marts so the BI layer can answer those questions without a model change. If agents need separate treatment beyond filtering, that becomes a scoped model change at that point.

---

## 6. Interview narrative arc (opening walkthrough ~8-10 min)

### Problem (30s)

> "Two distinct consumers of three mutable source tables at very different scales. KPI dashboards need fast, historically accurate aggregates. Compliance needs current correctness on a 15-minute cycle. The common difficulty is mutation - reversals on payments, tier changes on wallets - which most standard patterns don't handle gracefully."

### Requirements (30s)

> "Hourly KPI freshness, 15-min compliance freshness, current and historical KPI values, breakdown by five dimensions, two compliance outputs. Performance valued highly on KPIs."

### Assumptions I had to make (1m)

> "Snowflake as the warehouse from the DDL syntax. An `exchange_rates` table - the brief is silent on USD conversion but compliance limits are USD-denominated. Reversed transactions excluded from monthly volume because a reversal unwinds the original payment. Current tier governs compliance limits because tiers only increase. Null `merchant_id` means P2P transfer. I documented each assumption explicitly because they are genuine business decisions a reviewer could disagree with."

### Data modeling approach (2m)

> "Standard layering with intent at each layer. Staging is pure views - cheapness and currency. Snapshots for the two small mutable dimensions to give SCD2 history. A core fact table resolving dimension attributes at payment time via SCD2 date-range joins, with a separate history table because audit history is a different consumer question from current state. Two divergent mart paths: pre-aggregated daily KPIs and full-replace compliance."

### dbt implementation (2m)

Walk the directory structure. Highlight the three incremental strategies and why each. Highlight the macro and what problem it solves. Mention schema YAML documentation as part of the deliverable, not an afterthought.

### Testing (1m)

> "Structural, domain, and business rule tests at every layer. Heavy uniqueness tests scoped to recent data for cost. `amount_usd not_null` on `mart_compliance_current_transactions` as the canary for FX coverage. `dbt source freshness` is what I would add first with more time."

### Performance (1m)

> "Three decisions: pre-aggregation for billion-row dashboard queries, clustering on `(updated_at::date, payment_date)` for the dual-scan reversal pattern, and the intermediate layer to run the FX join once. Next step is CDC via Snowflake streams."

### Trade-offs (1m)

> "Latest-available FX rate over strict freshness. Breaching-only compliance history over full coverage. Current tier over period-min tier. Each was a deliberate decision, not a default."

### What I'd improve next (30s)

> "Source freshness tests, integration test harness on DuckDB, snapshot bootstrap backfill, replace correlated FX subquery with an asof join."

### Close

> "That is the overview. Happy to go deep on any of the decisions - the incremental strategies, compliance correctness guarantees, the SCD2 approach, or orchestration. Where would you like to start?"

---

## 7. Meta-strategy: lead with self-critique

If asked "What are the weaknesses or gaps in your design?", go first and be the harshest critic in the room:

> "Honestly, three things. First, no `dbt source freshness` - that is the single test I would add before anything else. Second, the snapshot bootstrap leaves a window of unrecoverable history that I handled with `'unknown'` rather than a proper backfill. Third, the inner join on `kyc_limits` silently drops null-tier wallets - it should be backed by a staging test that fails the build before bad data reaches the compliance models. None of these are subtle. They are the first three tickets I'd raise on day one."

That answer:
- Demonstrates self-awareness
- Shows priority judgment
- Pre-empts those gaps being surfaced as gotchas

---

## 8. What NOT to do

- Don't list gaps unprompted in the opening walkthrough. Save self-critique for when asked.
- Don't volunteer every gap. Lead with the three most defensible ones.
- Don't say "I should have..." - always "I'd add..." or "the next iteration would..." or "I deliberately deferred..."
- Don't argue when they push back. "That's a stronger framing, I hadn't thought of it that way" once or twice is fine. Never reads as defensive; overdoing it reads as uncertain.
- Don't apologise for trade-offs. Name them, own the reasoning, move on.

---

## 9. Phrase bank

- "That was a deliberate trade-off between X and Y."
- "I optimised for the most likely question, which was..."
- "The failure mode I'm protecting against is..."
- "In production I'd also want..."
- "I scoped that out because of the time box, but the obvious next step is..."
- "The defensive change is..."
- "Calibrated for analytics-grade rather than audit-grade..."
- "The right defence here is upstream, in a test on staging."
- "I chose, because..."

---

## 10. Pre-interview self-check

Read these three sections of your design doc out loud and rehearse a spoken defence for each:

1. **Compliance section, "current tier is the correct interpretation for enforcement purposes"** - have the one-sentence counter-argument ready and know why you still chose this way.

2. **`fct_payments_history` section** - they will ask you to write the reversal rate query from this table. Have the SQL roughly in your head:
   ```sql
   select
       date_trunc('month', version_valid_from) as month,
       countif(status = 'reversed') / count(*) as reversal_rate
   from fct_payments_history
   group by 1
   order by 1
   ```

3. **`agg_payments_daily` delete+insert section** - walk through a specific reversal scenario end to end:
   > "Reversal arrives at 14:03 for a payment created on March 5th. At 14:15 `fct_payments` merges the updated row. At 15:00 `agg_payments_daily` runs. `affected_dates` includes March 5. All rows where `payment_date = '2024-03-05'` are deleted. `fct_payments` for March 5 is re-aggregated including the reversed row. Rows are inserted. The KPI for March 5 now reflects the reversal."
