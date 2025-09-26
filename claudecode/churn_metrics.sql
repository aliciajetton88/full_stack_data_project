-- Churn Metrics Analysis
-- Data source: dim_subscription_states

-- Monthly churn rate calculation
WITH monthly_subscription_summary AS (
  SELECT
    DATE_TRUNC('month', state_date) AS month,
    COUNT(DISTINCT subscription_id) AS total_subscriptions,
    COUNT(DISTINCT CASE WHEN state = 'active' THEN subscription_id END) AS active_subscriptions,
    COUNT(DISTINCT CASE WHEN state = 'churned' THEN subscription_id END) AS churned_subscriptions,
    COUNT(DISTINCT CASE WHEN state = 'new' THEN subscription_id END) AS new_subscriptions
  FROM dim_subscription_states
  WHERE state_date >= CURRENT_DATE - INTERVAL '12 months'
  GROUP BY DATE_TRUNC('month', state_date)
),

churn_rates AS (
  SELECT
    month,
    total_subscriptions,
    active_subscriptions,
    churned_subscriptions,
    new_subscriptions,
    CASE
      WHEN LAG(active_subscriptions) OVER (ORDER BY month) > 0
      THEN ROUND(churned_subscriptions::NUMERIC / LAG(active_subscriptions) OVER (ORDER BY month) * 100, 2)
      ELSE 0
    END AS monthly_churn_rate_pct,
    ROUND(churned_subscriptions::NUMERIC / NULLIF(total_subscriptions, 0) * 100, 2) AS gross_churn_rate_pct
  FROM monthly_subscription_summary
)

SELECT
  month,
  total_subscriptions,
  active_subscriptions,
  churned_subscriptions,
  new_subscriptions,
  monthly_churn_rate_pct,
  gross_churn_rate_pct,
  AVG(monthly_churn_rate_pct) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3m_churn_rate
FROM churn_rates
ORDER BY month DESC;

-- Cohort-based churn analysis
WITH subscription_cohorts AS (
  SELECT
    subscription_id,
    MIN(DATE_TRUNC('month', state_date)) AS cohort_month,
    MAX(CASE WHEN state = 'churned' THEN DATE_TRUNC('month', state_date) END) AS churn_month
  FROM dim_subscription_states
  WHERE state IN ('new', 'active', 'churned')
  GROUP BY subscription_id
),

cohort_sizes AS (
  SELECT
    cohort_month,
    COUNT(DISTINCT subscription_id) AS cohort_size
  FROM subscription_cohorts
  GROUP BY cohort_month
),

cohort_churn AS (
  SELECT
    c.cohort_month,
    s.cohort_size,
    COUNT(DISTINCT c.subscription_id) AS churned_customers,
    EXTRACT(MONTH FROM AGE(c.churn_month, c.cohort_month)) AS months_to_churn
  FROM subscription_cohorts c
  JOIN cohort_sizes s ON c.cohort_month = s.cohort_month
  WHERE c.churn_month IS NOT NULL
  GROUP BY c.cohort_month, s.cohort_size, months_to_churn
)

SELECT
  cohort_month,
  cohort_size,
  months_to_churn,
  churned_customers,
  ROUND(churned_customers::NUMERIC / cohort_size * 100, 2) AS churn_rate_pct
FROM cohort_churn
WHERE months_to_churn <= 12
ORDER BY cohort_month DESC, months_to_churn;