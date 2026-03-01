/* ============================================
   POLICY ANALYSIS: Average Death Rate by Stringency Level
============================================ */

SELECT 
    ROUND(p.stringency_index / 10, 0) * 10 AS stringency_bucket,
    COUNT(*) AS days,
    ROUND(AVG(cd.new_deaths_per_million), 3) AS avg_deaths_per_million,
    ROUND(AVG(cd.new_cases_per_million), 3) AS avg_cases_per_million
FROM policy p
JOIN cases_deaths cd ON p.country = cd.country AND p.date = cd.date
WHERE p.stringency_index IS NOT NULL
    AND cd.new_deaths_per_million IS NOT NULL
    AND cd.new_deaths_per_million > 0
GROUP BY stringency_bucket
ORDER BY stringency_bucket;

/* Countries typically imposed stricter policies in response to rising cases and deaths, not before them. This explains why moderate stringency levels (40–70) show higher death rates than low stringency, they reflect the crisis that triggered the lockdowns, not the lockdowns themselves. However, at maximum stringency (100) , both cases and deaths drop dramatically, suggesting that complete lockdowns do work when fully implemented. The low case counts at high stringency (36 per million at level 100 vs 503 at level 20) prove that restrictions successfully reduced transmission, even if the death data is muddied by timing.
*/

/* ============================================
   POLICY ANALYSIS: Outcomes by Response Speed
   - Groups countries by how quickly they responded
============================================ */

WITH first_case AS (
    SELECT country, MIN(date) AS first_case_date
    FROM cases_deaths WHERE new_cases > 0 GROUP BY country
),

first_strict_policy AS (
    SELECT country, MIN(date) AS first_strict_date
    FROM policy WHERE stringency_index >= 50 GROUP BY country
),

response_time AS (
    SELECT 
        fc.country,
        JULIANDAY(fsp.first_strict_date) - JULIANDAY(fc.first_case_date) AS days_to_respond
    FROM first_case fc
    JOIN first_strict_policy fsp ON fc.country = fsp.country
    WHERE fsp.first_strict_date >= fc.first_case_date
),

avg_deaths AS (
    SELECT country, AVG(new_deaths_per_million) AS avg_death_rate
    FROM cases_deaths WHERE new_deaths_per_million > 0 GROUP BY country
)

SELECT 
    CASE 
        WHEN rt.days_to_respond <= 7 THEN 'Immediate (≤7 days)'
        WHEN rt.days_to_respond <= 30 THEN 'Quick (8–30 days)'
        WHEN rt.days_to_respond <= 60 THEN 'Moderate (31–60 days)'
        WHEN rt.days_to_respond <= 90 THEN 'Slow (61–90 days)'
        ELSE 'Very Slow (90+ days)'
    END AS response_speed,
    COUNT(*) AS countries,
    ROUND(AVG(ad.avg_death_rate), 3) AS avg_death_rate,
    MIN(rt.days_to_respond) AS fastest,
    MAX(rt.days_to_respond) AS slowest
FROM response_time rt
JOIN avg_deaths ad ON rt.country = ad.country
GROUP BY response_speed
ORDER BY fastest;

/* When grouped by response speed, a clear but counterintuitive pattern emerges. Countries that responded immediately within seven days averaged 3.50 deaths per million across 50 nations. Those that responded quickly between eight and thirty days fared worst with 5.12 deaths per million across 73 countries. This group likely locked down only after cases had already begun surging, and deaths continued to rise despite restrictions due to the natural lag between infection and mortality.

The moderate responders who waited thirty-one to sixty days achieved the lowest death rate at 3.15 deaths per million across 21 countries. These nations may have experienced milder initial outbreaks that did not demand immediate action. The slow responders who waited sixty-one to ninety days suffered the highest mortality at 8.46 deaths per million across just five countries, confirming that waiting too long while cases spread leads to devastating outcomes. Japan's unique case, taking over a year to implement strict measures yet recording only 0.56 deaths per million, reminds us that formal policy stringency does not capture the full picture of pandemic response. Cultural factors, mask adherence, border controls, and testing capacity all play crucial roles that numbers alone cannot reveal. */

/* ============================================
   POLICY ANALYSIS: Multiple Policies Compared
   - Shows average death rate at each policy level
============================================ */

SELECT 
    'School Closures' AS policy,
    p.c1m_school_closing AS level,
    ROUND(AVG(cd.new_deaths_per_million), 3) AS avg_deaths,
    COUNT(*) AS days
FROM policy p JOIN cases_deaths cd ON p.country = cd.country AND p.date = cd.date
WHERE cd.new_deaths_per_million > 0 GROUP BY p.c1m_school_closing

UNION ALL

SELECT 
    'Workplace Closures',
    p.c2m_workplace_closing,
    ROUND(AVG(cd.new_deaths_per_million), 3),
    COUNT(*)
FROM policy p JOIN cases_deaths cd ON p.country = cd.country AND p.date = cd.date
WHERE cd.new_deaths_per_million > 0 GROUP BY p.c2m_workplace_closing

UNION ALL

SELECT 
    'Stay-at-Home Orders',
    p.c6m_stay_at_home_requirements,
    ROUND(AVG(cd.new_deaths_per_million), 3),
    COUNT(*)
FROM policy p JOIN cases_deaths cd ON p.country = cd.country AND p.date = cd.date
WHERE cd.new_deaths_per_million > 0 GROUP BY p.c6m_stay_at_home_requirements

UNION ALL

SELECT 
    'Face Coverings',
    p.h6m_facial_coverings,
    ROUND(AVG(cd.new_deaths_per_million), 3),
    COUNT(*)
FROM policy p JOIN cases_deaths cd ON p.country = cd.country AND p.date = cd.date
WHERE cd.new_deaths_per_million > 0 GROUP BY p.h6m_facial_coverings

UNION ALL

SELECT 
    'Testing Policy',
    p.h2_testing_policy,
    ROUND(AVG(cd.new_deaths_per_million), 3),
    COUNT(*)
FROM policy p JOIN cases_deaths cd ON p.country = cd.country AND p.date = cd.date
WHERE cd.new_deaths_per_million > 0 GROUP BY p.h2_testing_policy

ORDER BY policy, level;

/* Analyzing individual policies is complicated by timing. Most restrictions were implemented after deaths had already risen, making strict measures appear associated with higher mortality in the raw data. The one exception was full stay-at-home orders, which showed the lowest death rates when actually enforced. This suggests that while policies often reacted to crises rather than preventing them, the most extreme measures did succeed in reducing deaths once implemented. */

