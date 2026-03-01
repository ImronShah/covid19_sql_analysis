/* ============================================
   PROJECT: COVID-19: Beyond the Headlines
   FILE: 01_initial_exploration.sql
   DATE: [2026-02-26]
   DESCRIPTION: 
   - First look at combined testing and cases data
   - LIMIT 100 used to preview data structure
   - Verifies JOIN works correctly
   - Checks for NULL values and data quality
============================================ */

-- Testing rate vs death rate by country
-- Preview first 100 rows to understand data structure
SELECT 
    t.country,
    t.date,
    t.new_tests,
    t.new_tests_per_thousand,
    t.new_tests_7day_smoothed,
    t.new_tests_per_thousand_7day_smoothed,
    cd.new_cases,
    cd.new_deaths,
    cd.new_cases_7_day_avg_right,
    cd.new_deaths_7_day_avg_right,
    cd.cfr
FROM testing t
JOIN cases_deaths cd ON t.country = cd.country AND t.date = cd.date
WHERE cd.country IS NOT NULL
    AND t.new_tests IS NOT NULL
    AND cd.new_cases > 0
LIMIT 100;  -- Preview only; remove LIMIT for full analysis
