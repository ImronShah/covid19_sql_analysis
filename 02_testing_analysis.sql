/* ============================================
   QUESTION 1: Top countries by testing per capita
   - Uses 7-day smoothed data to avoid daily fluctuations
   - Averages over entire pandemic period
   - Shows testing intensity, not just total tests
============================================ */

SELECT 
    t.country,
    ROUND(AVG(t.new_tests_per_thousand_7day_smoothed), 2) AS avg_tests_per_thousand,
    ROUND(MAX(t.new_tests_per_thousand_7day_smoothed), 2) AS peak_tests_per_thousand,
    COUNT(*) AS days_with_data
FROM testing t
WHERE t.new_tests_per_thousand_7day_smoothed IS NOT NULL
GROUP BY t.country
HAVING days_with_data > 30  -- Only countries with enough data
ORDER BY avg_tests_per_thousand DESC
LIMIT 20;

/*  Top 20 - Faroe Islands Cyprus Austria United Arab Emirates Singapore Palau Denmark Slovakia Anguilla China United Kingdom Greece Bahrain Luxembourg Hong Kong Georgia Czechia Mauritius Israel Qatar 

/* ============================================
   QUESTION 2: Global testing trend over time
   - Monthly average of tests per thousand
   - Shows how testing capacity grew worldwide
============================================ */

SELECT 
    strftime('%Y-%m', t.date) AS year_month,
    ROUND(AVG(t.new_tests_per_thousand_7day_smoothed), 3) AS global_avg_tests,
    ROUND(MAX(t.new_tests_per_thousand_7day_smoothed), 3) AS global_max_tests,
    COUNT(DISTINCT t.country) AS countries_reporting
FROM testing t
WHERE t.new_tests_per_thousand_7day_smoothed IS NOT NULL
GROUP BY year_month
ORDER BY year_month;

/* Global COVID-19 testing peaked in January 2022 at 6.59 tests per thousand people daily, coinciding with the Omicron variant surge. After this point, testing gradually declined as countries shifted pandemic strategies

/* ============================================
   QUESTION 3 (Simplified): Testing vs Cases Relationship
   - Group countries by testing intensity
   - Compare average cases found in each group
============================================ */

-- First, we need to find each country's average testing level
WITH country_testing AS (
    SELECT 
        t.country,
        AVG(t.new_tests_per_thousand_7day_smoothed) AS avg_testing,
        AVG(cd.new_cases_7_day_avg_right) AS avg_cases
    FROM testing t
    JOIN cases_deaths cd ON t.country = cd.country AND t.date = cd.date
    WHERE t.new_tests_per_thousand_7day_smoothed IS NOT NULL
        AND cd.new_cases_7_day_avg_right IS NOT NULL
        AND cd.new_cases_7_day_avg_right > 0
    GROUP BY t.country
    HAVING COUNT(*) > 30
)

-- Now grouping them into testing quartiles
SELECT 
    CASE 
        WHEN avg_testing < 0.1 THEN 'Very Low Testing (<0.1 per 1000)'
        WHEN avg_testing < 0.5 THEN 'Low Testing (0.1-0.5)'
        WHEN avg_testing < 1.0 THEN 'Medium Testing (0.5-1.0)'
        WHEN avg_testing < 2.0 THEN 'High Testing (1.0-2.0)'
        ELSE 'Very High Testing (>2.0)'
    END AS testing_category,
    COUNT(*) AS number_of_countries,
    ROUND(AVG(avg_cases), 2) AS avg_daily_cases_per_country,
    ROUND(MIN(avg_cases), 2) AS min_avg_cases,
    ROUND(MAX(avg_cases), 2) AS max_avg_cases
FROM country_testing
GROUP BY testing_category
ORDER BY avg_cases DESC;

/* There is a clear relationship between testing intensity and case detection. Countries that tested at high rates (over 2 tests per thousand people daily) detected nearly 70 times more cases than countries with minimal testing. This suggests that official case counts are heavily influenced by testing capacity, not just viral spread.

/* ============================================
   QUESTION 4: Countries with lowest testing rates
   - The "testing laggards"
   - Focus is on countries with significant populations/days
============================================ */

SELECT 
    t.country,
    ROUND(AVG(t.new_tests_per_thousand_7day_smoothed), 3) AS avg_tests_per_thousand,
    ROUND(MAX(t.new_tests_per_thousand_7day_smoothed), 3) AS peak_tests,
    MIN(t.date) AS first_test_date,
    COUNT(*) AS days_with_data
FROM testing t
WHERE t.new_tests_per_thousand_7day_smoothed IS NOT NULL
GROUP BY t.country
HAVING days_with_data > 30
ORDER BY avg_tests_per_thousand ASC
LIMIT 20;

/* Global COVID-19 data is not a simple reflection of viral spread. Testing capacity dramatically shapes what we see. Countries like Yemen and North Korea appear to have low case numbers, but this almost certainly reflects lack of testing, not lack of virus.

/* ============================================
   Testing Laggards: Do they have HIGHER death rates?
   - Because they only test severe cases
============================================ */

SELECT 
    t.country,
    ROUND(AVG(t.new_tests_per_thousand_7day_smoothed), 3) AS avg_tests,
    ROUND(AVG(cd.cfr), 2) AS avg_cfr,
    ROUND(AVG(cd.new_cases_7_day_avg_right), 2) AS avg_reported_cases,
    ROUND(AVG(cd.new_deaths_7_day_avg_right), 2) AS avg_reported_deaths
FROM testing t
JOIN cases_deaths cd ON t.country = cd.country AND t.date = cd.date
WHERE t.country IN (
    'Yemen', 'North Korea', 'Afghanistan', 'Nigeria', 'Haiti',
    'Syria', 'Ethiopia', 'Chad', 'Niger', 'Mali'
)
GROUP BY t.country
ORDER BY avg_tests;

/* Case Fatality Rate is inversely related to testing capacity. Countries that test very little report unrealistically low case counts and artificially high death rates, because they only detect the sickest patients.