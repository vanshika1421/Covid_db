--1. Which country has the highest number of confirmed cases on a specific date?
SELECT DISTINCT report_date FROM covid_case_stats ORDER BY report_date LIMIT 10;
SELECT c.name, SUM(cs.confirmed) AS total_confirmed
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
WHERE cs.report_date = '2020-02-06'
GROUP BY c.country_id, c.name
ORDER BY total_confirmed DESC
LIMIT 1;
--UC2
SELECT 
    c.name AS country,
    s.state_name AS state,
    SUM(cs.deaths) AS total_deaths
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
JOIN state s
    ON cs.state_id = s.state_id
WHERE cs.report_date = '2020-02-06'
GROUP BY c.name, s.state_name
ORDER BY c.name, total_deaths DESC;
--3. List the continents along with the total number of confirmed cases, deaths, and recoveries.
SELECT 
    c.continent,
    SUM(cs.confirmed) AS confirmed_cases,
    SUM(cs.deaths) AS deaths,
    SUM(cs.recovered) AS recoveries
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
GROUP BY c.continent
ORDER BY c.continent;
-- UC4 — Average new deaths per day across all countries
SELECT 
    AVG(daily_deaths) AS average_new_deaths_per_day
FROM (
    SELECT 
        report_date,
        SUM(new_deaths) AS daily_deaths
    FROM covid_case_stats
    GROUP BY report_date
) AS daily_data;
-- UC5 — Maximum active cases in any country on a specific date
SELECT 
    c.name AS country,
    MAX(cs.active_cases) AS maximum_active_cases
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
WHERE cs.report_date = '2020-01-30'
GROUP BY c.name
ORDER BY maximum_active_cases DESC
LIMIT 1;


-- UC6
CREATE OR REPLACE PROCEDURE get_total_recovered(
    p_country_id INT,
    p_date DATE,
    OUT total_recovered INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(SUM(recovered), 0)
    INTO total_recovered
    FROM covid_case_stats
    WHERE country_id = p_country_id
      AND report_date = p_date;
END;
$$;
CALL get_total_recovered(1, '2020-01-30', NULL);
