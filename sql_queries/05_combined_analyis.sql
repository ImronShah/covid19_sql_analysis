WITH first_case AS (
    SELECT 
        country,
        MIN(date) AS first_case_date
    FROM cases_deaths
    WHERE new_cases > 0 AND new_cases IS NOT NULL
    GROUP BY country
),

first_policy AS (
    SELECT 
        country,
        MIN(date) AS first_policy_date
    FROM policy
    WHERE stringency_index >= 50
        AND date >= '2020-01-01'
    GROUP BY country
),

response_time AS (
    SELECT 
        fc.country,
        fc.first_case_date,
        fp.first_policy_date,
        JULIANDAY(fp.first_policy_date) - JULIANDAY(fc.first_case_date) AS days_to_respond
    FROM first_case fc
    JOIN first_policy fp ON fc.country = fp.country
    WHERE fp.first_policy_date >= fc.first_case_date
),

testing_summary AS (
    SELECT 
        country,
        AVG(new_tests_per_thousand_7day_smoothed) AS avg_testing_rate
    FROM testing
    WHERE new_tests_per_thousand_7day_smoothed IS NOT NULL
    GROUP BY country
),

mortality_summary AS (
    SELECT 
        country,
        AVG(new_deaths_per_million) AS avg_deaths_per_million
    FROM cases_deaths
    WHERE new_deaths_per_million IS NOT NULL 
        AND new_deaths_per_million > 0
    GROUP BY country
)

SELECT 
    rt.country,
    ROUND(ts.avg_testing_rate, 2) AS tests_per_thousand,
    ROUND(ms.avg_deaths_per_million, 2) AS deaths_per_million,
    rt.days_to_respond,
    rt.first_case_date,
    rt.first_policy_date
FROM response_time rt
JOIN testing_summary ts ON rt.country = ts.country
JOIN mortality_summary ms ON rt.country = ms.country
WHERE ts.avg_testing_rate IS NOT NULL
    AND ms.avg_deaths_per_million IS NOT NULL
ORDER BY ms.avg_deaths_per_million ASC;

/* Combined Analysis: Testing, Policy and Outcomes
After filtering for countries with complete and reliable data, three distinct groups emerge. Each tells a different story about the pandemic.

Countries with Limited Data
Countries like Nigeria, the Democratic Republic of Congo, Niger and Chad appear at the very top of the best performers list with death rates below 0.1 per million. Their testing rates are similarly near zero. These numbers are not evidence of pandemic success. They reflect an absence of data. Without testing, cases go undetected. Without death registration, mortality goes uncounted. These nations remind us that global statistics are only as good as the systems that produce them. The virus did not spare them. It simply remained invisible.

Countries with Strong Outcomes
The United Arab Emirates, Singapore, China and South Korea stand out as countries that combined high testing with effective policy responses. The UAE tested at 20.6 per thousand and recorded just 0.35 deaths per million. Singapore tested at 17.1 per thousand with 0.87 deaths. China tested at 9.8 per thousand with 0.10 deaths. These nations acted early, tested aggressively and maintained consistent restrictions. Their low death rates are credible and earned.

Countries with High Mortality
At the other end of the spectrum, Bulgaria, Slovenia, Latvia, France and Spain suffered catastrophic losses despite moderate to high testing. Bulgaria recorded 23.9 deaths per million with 1.8 tests per thousand. Slovenia lost 21.9 per million with 2.9 tests. France lost 15.2 per million with 5.4 tests. These countries responded quickly, many within days of their first cases, yet the virus spread through aging populations and dense urban centers. Testing alone could not save them. Once the virus spread widely, mortality followed.

The Japan Case
Japan stands apart. With low testing at 0.5 per thousand and an astonishing 410 day delay in implementing strict policies, Japan still recorded only 0.56 deaths per million. This defies the patterns seen elsewhere and suggests that cultural factors, mask adherence and border controls played roles that formal policy metrics cannot capture. Japan is a reminder that stringency indexes do not tell the whole story.

Response Speed and Its Limits
The data shows that response speed alone does not guarantee low mortality. Bulgaria responded in 5 days and suffered 23.9 deaths. The UAE took 53 days and suffered 0.35 deaths. Geography, demographics and healthcare capacity mattered as much as timing. Fast response helped, but only when combined with favorable conditions.

What the Data Reveals
This analysis shows that pandemic outcomes were shaped by three forces: the capacity to measure, the speed to respond and the underlying vulnerability of each population. Countries that excelled mastered all three. Countries that appear successful but tested minimally merely masked their losses. And countries that tested thoroughly still perished in large numbers when the virus found fertile ground. The data does not offer a single lesson. It offers many, and they are not always comfortable.*/
