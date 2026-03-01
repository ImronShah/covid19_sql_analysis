/* ============================================
   MORTALITY ANALYSIS: Countries with HIGHEST death rates
   - Using total_deaths_per_million (population-adjusted)
============================================ */

WITH latest_deaths AS (
    SELECT 
        country,
        total_deaths_per_million,
        date,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY date DESC) AS rn
    FROM cases_deaths
    WHERE total_deaths_per_million IS NOT NULL
        AND total_deaths_per_million > 0
        AND country NOT LIKE '%income%'
        AND country NOT IN ('World', 'Europe', 'Asia', 'Africa', 'North America', 'South America', 'Oceania', 'European Union')
)
SELECT 
    country,
    ROUND(total_deaths_per_million, 0) AS deaths_per_million,
    date
FROM latest_deaths
WHERE rn = 1
ORDER BY deaths_per_million DESC
LIMIT 15;

/* The highest COVID-19 death rates cluster in Eastern Europe and Peru, with Peru suffering the world's worst recorded toll at over 6,600 deaths per million as they have more than 1 in every 150 citizens passing away.

/* ============================================
   MORTALITY ANALYSIS: Countries with LOWEST death rates
   - Only include countries with at least some deaths reported
============================================ */

WITH latest_deaths AS (
    SELECT 
        country,
        total_deaths_per_million,
        date,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY date DESC) AS rn
    FROM cases_deaths
    WHERE total_deaths_per_million IS NOT NULL
        AND total_deaths_per_million >= 0
        AND country NOT LIKE '%income%'
        AND country NOT IN ('World', 'Europe', 'Asia', 'Africa', 'North America', 'South America', 'Oceania', 'European Union')
)
SELECT 
    country,
    ROUND(total_deaths_per_million, 2) AS deaths_per_million,
    date
FROM latest_deaths
WHERE rn = 1
    AND total_deaths_per_million > 0  -- Has at least some deaths
ORDER BY deaths_per_million ASC
LIMIT 15;


/* The world's lowest reported COVID-19 death rates are in Sub-Saharan Africa, but this reflects lack of testing and death registration, not viral avoidance. Burundi's reported rate of 1 death per million is 6,000 times lower than Peru's. The overlap between testing laggards and low reported deaths points to an uncomfortable truth. Countries with minimal testing capacity simply cannot count their dead accurately. Chad, Niger, Nigeria, DRC, Burkina Faso, and South Sudan all appear on both lists. Their vanishingly low death rates are not evidence of pandemic success. They reflect invisible mortality instead. These nations represent the pandemic's silent majority. They are victims who died without tests, without records, and without ever appearing in global statistics. */

-- See sample of countries to help with regional grouping
SELECT DISTINCT country 
FROM cases_deaths 
WHERE cfr IS NOT NULL
ORDER BY country;

/* ============================================
   MORTALITY ANALYSIS: CFR by Region (Cleaned)
   - Removing extreme outliers (CFR > 10%)
   - This gives more realistic regional averages
============================================ */

WITH country_cfr AS (
    SELECT 
        country,
        AVG(cfr) AS avg_cfr,
        COUNT(*) AS days_recorded,
        CASE 
            WHEN country IN ('Canada', 'Mexico', 'United States') THEN 'North America'
            WHEN country IN ('Belize', 'Costa Rica', 'Cuba', 'Dominican Republic', 'El Salvador', 
                           'Guatemala', 'Haiti', 'Honduras', 'Jamaica', 'Nicaragua', 'Panama', 
                           'Puerto Rico', 'Trinidad and Tobago', 'Bahamas', 'Barbados', 'Bermuda',
                           'Cayman Islands', 'Curacao', 'Dominica', 'Grenada', 'Guadeloupe',
                           'Martinique', 'Saint Lucia', 'Saint Vincent and the Grenadines',
                           'Aruba', 'Antigua and Barbuda', 'Anguilla', 'British Virgin Islands',
                           'Montserrat', 'Saint Kitts and Nevis', 'Saint Barthelemy',
                           'Saint Martin (French part)', 'Sint Maarten (Dutch part)',
                           'Turks and Caicos Islands', 'United States Virgin Islands') THEN 'Caribbean & Central America'
            WHEN country IN ('Argentina', 'Bolivia', 'Brazil', 'Chile', 'Colombia', 'Ecuador',
                           'French Guiana', 'Guyana', 'Paraguay', 'Peru', 'Suriname', 'Uruguay',
                           'Venezuela', 'Falkland Islands') THEN 'South America'
            WHEN country IN ('Albania', 'Andorra', 'Austria', 'Belarus', 'Belgium', 'Bosnia and Herzegovina',
                           'Bulgaria', 'Croatia', 'Cyprus', 'Czechia', 'Denmark', 'Estonia', 'Faroe Islands',
                           'Finland', 'France', 'Germany', 'Gibraltar', 'Greece', 'Greenland', 'Guernsey',
                           'Hungary', 'Iceland', 'Ireland', 'Isle of Man', 'Italy', 'Jersey', 'Kosovo',
                           'Latvia', 'Liechtenstein', 'Lithuania', 'Luxembourg', 'Malta', 'Moldova',
                           'Monaco', 'Montenegro', 'Netherlands', 'North Macedonia', 'Norway', 'Poland',
                           'Portugal', 'Romania', 'Russia', 'San Marino', 'Serbia', 'Slovakia', 'Slovenia',
                           'Spain', 'Sweden', 'Switzerland', 'Ukraine', 'United Kingdom', 'Vatican') THEN 'Europe'
            WHEN country IN ('Algeria', 'Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi', 'Cameroon',
                           'Cape Verde', 'Central African Republic', 'Chad', 'Comoros', 'Congo', 'Democratic Republic of Congo',
                           'Djibouti', 'Egypt', 'Equatorial Guinea', 'Eritrea', 'Eswatini', 'Ethiopia',
                           'Gabon', 'Gambia', 'Ghana', 'Guinea', 'Guinea-Bissau', 'Kenya', 'Lesotho',
                           'Liberia', 'Libya', 'Madagascar', 'Malawi', 'Mali', 'Mauritania', 'Mauritius',
                           'Mayotte', 'Morocco', 'Mozambique', 'Namibia', 'Niger', 'Nigeria', 'Reunion',
                           'Rwanda', 'Saint Helena', 'Sao Tome and Principe', 'Senegal', 'Seychelles',
                           'Sierra Leone', 'Somalia', 'South Africa', 'South Sudan', 'Sudan', 'Tanzania',
                           'Togo', 'Tunisia', 'Uganda', 'Zambia', 'Zimbabwe') THEN 'Africa'
            WHEN country IN ('Afghanistan', 'Armenia', 'Azerbaijan', 'Bahrain', 'Bangladesh', 'Bhutan', 'Brunei',
                           'Cambodia', 'China', 'East Timor', 'Georgia', 'India', 'Indonesia', 'Iran',
                           'Iraq', 'Israel', 'Japan', 'Jordan', 'Kazakhstan', 'Kuwait', 'Kyrgyzstan', 'Laos',
                           'Lebanon', 'Malaysia', 'Maldives', 'Mongolia', 'Myanmar', 'Nepal',
                           'North Korea', 'Oman', 'Pakistan', 'Palestine', 'Philippines', 'Qatar',
                           'Saudi Arabia', 'Singapore', 'South Korea', 'Sri Lanka', 'Syria',
                           'Tajikistan', 'Thailand', 'Turkey', 'United Arab Emirates',
                           'Uzbekistan', 'Vietnam', 'Yemen') THEN 'Asia'
            WHEN country IN ('American Samoa', 'Australia', 'Cook Islands', 'Fiji', 'French Polynesia', 'Guam',
                           'Kiribati', 'Marshall Islands', 'Micronesia (country)', 'Nauru', 'New Caledonia',
                           'New Zealand', 'Niue', 'Northern Mariana Islands', 'Palau', 'Papua New Guinea',
                           'Pitcairn', 'Samoa', 'Solomon Islands', 'Tokelau', 'Tonga', 'Tuvalu',
                           'Vanuatu', 'Wallis and Futuna') THEN 'Oceania'
            ELSE 'Other'
        END AS region
    FROM cases_deaths
    WHERE cfr IS NOT NULL 
        AND cfr BETWEEN 0.1 AND 10  -- Only realistic CFR values
        AND country NOT IN ('Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania',
                          'World', 'World excl. China', 'World excl. China and South Korea',
                          'World excl. China, South Korea, Japan and Singapore', 'European Union (27)',
                          'High-income countries', 'Low-income countries', 'Lower-middle-income countries',
                          'Upper-middle-income countries', 'Asia excl. China')
    GROUP BY country
    HAVING days_recorded > 30
)

SELECT 
    region,
    COUNT(*) AS countries,
    ROUND(AVG(avg_cfr), 2) AS regional_avg_cfr,
    ROUND(MIN(avg_cfr), 2) AS lowest_cfr,
    ROUND(MAX(avg_cfr), 2) AS highest_cfr
FROM country_cfr
WHERE region != 'Other'
GROUP BY region
ORDER BY regional_avg_cfr DESC;

/* After removing data artifacts, regional Case Fatality Rates converge between 0.5% and 1.4%, with South America highest and Oceania lowest. Africa's position in the middle (1.22%) likely still understates true mortality given widespread testing gaps identified earlier. */

/* ============================================
   MORTALITY ANALYSIS: Did Early Testing Lead to Lower Death Rates?
   - Finds first testing date for each country
   - Compares with average CFR (cleaned, 0.1-10%)
============================================ */

WITH first_test AS (
    -- Find the earliest date each country started testing
    SELECT 
        country,
        MIN(date) AS first_test_date
    FROM testing
    WHERE new_tests IS NOT NULL 
        AND new_tests > 0
    GROUP BY country
),

country_cfr AS (
    -- Calculate average CFR for each country (cleaned)
    SELECT 
        cd.country,
        AVG(cd.cfr) AS avg_cfr,
        COUNT(*) AS days_recorded
    FROM cases_deaths cd
    WHERE cd.cfr IS NOT NULL 
        AND cd.cfr BETWEEN 0.1 AND 10
    GROUP BY cd.country
    HAVING days_recorded > 30
)

SELECT 
    ft.country,
    ft.first_test_date,
    ROUND(cc.avg_cfr, 2) AS avg_cfr,
    ROUND(JULIANDAY(ft.first_test_date) - JULIANDAY('2020-01-01'), 0) AS days_since_pandemic_start
FROM first_test ft
JOIN country_cfr cc ON ft.country = cc.country
WHERE cc.avg_cfr IS NOT NULL
ORDER BY ft.first_test_date;
/* The relationship between testing intensity and case fatality rates becomes clear when examining countries with the highest testing volumes. Nations at the very top of the testing list achieved remarkably low CFRs. Faroe Islands conducted 46.5 tests per thousand people and recorded a CFR of just 0.18 percent. Cyprus tested at 44.1 per thousand with a 0.4 percent CFR. Singapore and the United Arab Emirates both maintained high testing rates and kept their CFRs at 0.2 percent and 0.28 percent respectively. Even larger nations like Denmark and Austria, testing at 12.8 and 26.3 per thousand, held CFRs below 0.6 percent. The pattern holds consistently. Countries that tested more found milder cases, expanded their case denominators, and produced lower fatality rates as a result. Notable exceptions exist, however. Slovakia tested at 11.3 per thousand yet recorded a 1.16 percent CFR. Georgia tested at 7.4 per thousand with a 1.05 percent rate. These outliers suggest that testing volume alone cannot guarantee low mortality. Other factors like healthcare capacity, population age, and policy responses also play crucial roles.

 */

/* ============================================
   Group countries by when they started testing
============================================ */

WITH first_test AS (
    SELECT 
        country,
        MIN(date) AS first_test_date
    FROM testing
    WHERE new_tests IS NOT NULL AND new_tests > 0
    GROUP BY country
),

country_cfr AS (
    SELECT 
        cd.country,
        AVG(cd.cfr) AS avg_cfr
    FROM cases_deaths cd
    WHERE cd.cfr BETWEEN 0.1 AND 10
    GROUP BY cd.country
)

SELECT 
    CASE 
        WHEN ft.first_test_date < '2020-03-01' THEN 'Early Testers (Before Mar 2020)'
        WHEN ft.first_test_date < '2020-06-01' THEN 'Mid Testers (Mar-May 2020)'
        WHEN ft.first_test_date < '2020-09-01' THEN 'Late Testers (Jun-Aug 2020)'
        ELSE 'Very Late Testers (Sep 2020 or later)'
    END AS testing_speed,
    COUNT(*) AS countries,
    ROUND(AVG(cc.avg_cfr), 2) AS avg_cfr,
    MIN(ft.first_test_date) AS earliest_date,
    MAX(ft.first_test_date) AS latest_date
FROM first_test ft
JOIN country_cfr cc ON ft.country = cc.country
GROUP BY testing_speed
ORDER BY MIN(ft.first_test_date);

/* The relationship between testing timing and mortality reveals a modest but meaningful pattern. Countries that began testing before March 2020 achieved an average CFR of 0.95 percent across 27 nations. Those testing between March and May 2020 averaged 1.06 percent across 73 countries. Late testers from June to August 2020 averaged 1.05 percent. Even countries that waited until September 2020 or later averaged 1.03 percent. The difference between early testers and everyone else sits at roughly 0.1 percentage points. Looking at individual countries reinforces this pattern. The United Arab Emirates tested on January 29 and held CFR to 0.28 percent. Singapore tested early and stayed at 0.2 percent. Japan, South Korea, and Israel all tested before late February and kept CFRs under 0.6 percent. The United States tested on March 1 and recorded 1.28 percent. Italy tested on February 25 and ended at 0.79 percent. Timing alone does not guarantee low mortality, but early testing appears to provide an advantage. */ 

/* ============================================
   Does testing VOLUME correlate with lower death rates?
============================================ */

WITH testing_intensity AS (
    SELECT 
        country,
        AVG(new_tests_per_thousand_7day_smoothed) AS avg_testing_rate
    FROM testing
    WHERE new_tests_per_thousand_7day_smoothed IS NOT NULL
    GROUP BY country
),

country_cfr AS (
    SELECT 
        cd.country,
        AVG(cd.cfr) AS avg_cfr
    FROM cases_deaths cd
    WHERE cd.cfr BETWEEN 0.1 AND 10
    GROUP BY cd.country
)

SELECT 
    ti.country,
    ROUND(ti.avg_testing_rate, 3) AS avg_tests_per_thousand,
    ROUND(cc.avg_cfr, 2) AS avg_cfr
FROM testing_intensity ti
JOIN country_cfr cc ON ti.country = cc.country
WHERE ti.avg_testing_rate IS NOT NULL
    AND cc.avg_cfr IS NOT NULL
ORDER BY ti.avg_testing_rate DESC
LIMIT 20;

/* The most successful countries combined early testing with high volume. The United Arab Emirates began testing on January 29 and maintained a rate of 20.6 tests per thousand, achieving a 0.28 percent CFR. Denmark started on February 2 with 12.8 tests per thousand and held CFR to 0.41 percent. Singapore tested early and sustained 17.1 tests per thousand for a 0.2 percent rate. Israel tested on February 20 with 6.6 tests per thousand and reached 0.43 percent. These nations demonstrate that volume amplifies the benefits of timing. Countries that tested early but at lower volume did not fare as well. The United States started on March 1 with moderate testing and recorded 1.28 percent. Italy began on February 25 with limited early capacity and ended at 0.79 percent. Early testing without sufficient volume cannot capture mild cases or guide public health response effectively. The nations that excelled did both. They started early and tested often, creating a complete picture of viral spread and enabling targeted interventions. */

/* ============================================
   MORTALITY ANALYSIS: How Death Rates Changed Over Time
   - Monthly average of deaths per million (population-adjusted)
   - Shows waves, peaks, and declines clearly
============================================ */

SELECT 
    strftime('%Y-%m', date) AS year_month,
    AVG(new_deaths_per_million) AS avg_deaths_per_million,
    SUM(new_deaths) AS total_deaths
FROM cases_deaths
WHERE new_deaths_per_million IS NOT NULL
    AND country NOT LIKE '%income%'
    AND country NOT IN ('World', 'Europe', 'Asia', 'Africa', 'North America', 'South America', 'Oceania')
GROUP BY year_month
ORDER BY year_month;

/* Global COVID-19 mortality followed a clear pattern of waves and eventual decline. Deaths first peaked in April 2020 at 1.00 per million before the winter of 2020–2021, when January 2021 recorded 2.43 deaths per million, the pandemic's deadliest month. Further waves from Delta and Omicron kept mortality high through late 2021 and early 2022, with February 2022 reaching 2.38 per million. From March 2022 onward, death rates steadily declined, falling below 0.1 per million by mid-2023 and stabilising near zero through 2026. The pandemic's mortality crisis, in global terms, ended two years ago. */