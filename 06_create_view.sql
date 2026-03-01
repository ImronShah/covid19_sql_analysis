/* ============================================
   CSV 1: Monthly Global Deaths
   Purpose: Line chart showing pandemic waves
============================================ */

SELECT 
    strftime('%Y-%m', date) AS month,
    ROUND(AVG(new_deaths_per_million), 3) AS avg_deaths_per_million,
    SUM(new_deaths) AS total_deaths
FROM cases_deaths
WHERE new_deaths_per_million IS NOT NULL
    AND country NOT LIKE '%income%'
    AND country NOT IN ('World', 'Europe', 'Asia', 'Africa', 'North America', 'South America', 'Oceania')
GROUP BY month
HAVING avg_deaths_per_million IS NOT NULL
ORDER BY month;

/* ============================================
   CSV 2: Continent Summary
   Purpose: Bar chart comparing continents
============================================ */

WITH country_continent AS (
    SELECT 
        cd.country,
        AVG(cd.new_deaths_per_million) AS deaths_per_million,
        AVG(t.new_tests_per_thousand_7day_smoothed) AS tests_per_thousand,
        CASE 
            WHEN cd.country IN ('Albania', 'Austria', 'Belarus', 'Belgium', 'Bosnia and Herzegovina', 'Bulgaria', 'Croatia', 'Czechia', 'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 'Iceland', 'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Moldova', 'Netherlands', 'North Macedonia', 'Norway', 'Poland', 'Portugal', 'Romania', 'Russia', 'Serbia', 'Slovakia', 'Slovenia', 'Spain', 'Sweden', 'Switzerland', 'Ukraine', 'United Kingdom') THEN 'Europe'
            WHEN cd.country IN ('Canada', 'Mexico', 'United States') THEN 'North America'
            WHEN cd.country IN ('Argentina', 'Bolivia', 'Brazil', 'Chile', 'Colombia', 'Ecuador', 'Guyana', 'Paraguay', 'Peru', 'Suriname', 'Uruguay', 'Venezuela') THEN 'South America'
            WHEN cd.country IN ('China', 'India', 'Indonesia', 'Japan', 'South Korea', 'Malaysia', 'Philippines', 'Singapore', 'Thailand', 'Vietnam', 'Bangladesh', 'Pakistan', 'Iran', 'Iraq', 'Israel', 'Saudi Arabia', 'Turkey', 'United Arab Emirates') THEN 'Asia'
            WHEN cd.country IN ('Algeria', 'Egypt', 'Ethiopia', 'Kenya', 'Morocco', 'Nigeria', 'South Africa', 'Tanzania', 'Uganda', 'Ghana', 'DRC', 'Mali', 'Niger', 'Burkina Faso', 'Mozambique', 'Madagascar', 'Angola', 'Cameroon', 'Zimbabwe', 'Malawi', 'Zambia', 'Senegal', 'Chad', 'Rwanda', 'Guinea', 'Benin', 'Burundi', 'Somalia', 'Togo', 'Sierra Leone', 'South Sudan') THEN 'Africa'
            WHEN cd.country IN ('Australia', 'New Zealand', 'Fiji', 'Papua New Guinea') THEN 'Oceania'
            ELSE NULL
        END AS continent
    FROM cases_deaths cd
    LEFT JOIN testing t ON cd.country = t.country
    WHERE cd.new_deaths_per_million IS NOT NULL
    GROUP BY cd.country
)
SELECT 
    continent,
    COUNT(*) AS number_of_countries,
    ROUND(AVG(deaths_per_million), 2) AS avg_deaths_per_million,
    ROUND(AVG(tests_per_thousand), 2) AS avg_tests_per_thousand,
    ROUND(SUM(deaths_per_million * 1000000), 0) AS estimated_total_deaths
FROM country_continent
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY avg_deaths_per_million DESC;

/* ============================================
   CSV 3: Global Testing Map
   Purpose: Interactive map showing testing rates
============================================ */

SELECT 
    cd.country,
    ROUND(AVG(t.new_tests_per_thousand_7day_smoothed), 2) AS avg_tests_per_thousand,
    ROUND(MAX(t.new_tests_per_thousand_7day_smoothed), 2) AS peak_tests_per_thousand,
    ROUND(AVG(cd.new_deaths_per_million), 2) AS deaths_per_million,
    MIN(t.date) AS first_test_date,
    MAX(t.date) AS latest_test_date,
    CASE 
        WHEN AVG(t.new_tests_per_thousand_7day_smoothed) < 0.1 THEN 'Minimal Testing'
        WHEN AVG(t.new_tests_per_thousand_7day_smoothed) < 1 THEN 'Low Testing'
        WHEN AVG(t.new_tests_per_thousand_7day_smoothed) < 5 THEN 'Moderate Testing'
        WHEN AVG(t.new_tests_per_thousand_7day_smoothed) < 10 THEN 'High Testing'
        ELSE 'Very High Testing'
    END AS testing_category
FROM cases_deaths cd
JOIN testing t ON cd.country = t.country
WHERE t.new_tests_per_thousand_7day_smoothed IS NOT NULL
    AND cd.country NOT LIKE '%income%'
    AND cd.country NOT IN ('World', 'Europe', 'Asia', 'Africa', 'North America', 'South America', 'Oceania')
GROUP BY cd.country
HAVING avg_tests_per_thousand IS NOT NULL
ORDER BY avg_tests_per_thousand DESC;