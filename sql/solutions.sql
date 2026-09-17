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
--uc7
CREATE OR REPLACE PROCEDURE update_deaths(
    p_country_id INT,
    p_date DATE,
    p_deaths INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE covid_case_stats
    SET deaths = p_deaths
    WHERE country_id = p_country_id
      AND report_date = p_date;
END;
$$;
CALL update_deaths(1, '2020-01-30', 50);

--UC8
CREATE OR REPLACE VIEW v_country_cases_specific_date AS
SELECT 
    c.name AS country,
    SUM(cs.confirmed) AS confirmed,
    SUM(cs.deaths) AS deaths,
    SUM(cs.recovered) AS recovered
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
WHERE cs.report_date = '2020-01-30'
GROUP BY c.country_id, c.name;

SELECT * 
FROM v_country_cases_specific_date;

--UC9 — Latest data for each country
CREATE OR REPLACE VIEW v_latest_country_data AS
SELECT 
    c.name AS country,
    cs.report_date,
    SUM(cs.confirmed) AS confirmed,
    SUM(cs.deaths) AS deaths,
    SUM(cs.recovered) AS recovered
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
WHERE cs.report_date = (
    SELECT MAX(report_date)
    FROM covid_case_stats
)
GROUP BY c.country_id, c.name, cs.report_date;

--UC10
SELECT 
    c.name AS country,
    SUM(cs.confirmed + cs.deaths + cs.recovered) AS total_cases
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
GROUP BY c.country_id, c.name
ORDER BY total_cases DESC;
--UC11
SELECT 
    c.name AS country,
    SUM(cs.new_confirmed) AS total_new_cases
FROM country c
JOIN covid_case_stats cs
    ON c.country_id = cs.country_id
WHERE cs.report_date = '2020-01-30'
GROUP BY c.country_id, c.name
ORDER BY total_new_cases DESC
LIMIT 1;
--UC12
WITH weekly_data AS (
    SELECT
        country_id,
        MIN(report_date) AS start_date,
        MAX(report_date) AS end_date
    FROM covid_case_stats
    WHERE report_date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY country_id
),
country_totals AS (
    SELECT
        w.country_id,
        MAX(CASE 
            WHEN cs.report_date = w.start_date 
            THEN cs.confirmed 
        END) AS start_confirmed,
        MAX(CASE 
            WHEN cs.report_date = w.end_date 
            THEN cs.confirmed 
        END) AS end_confirmed
    FROM weekly_data w
    JOIN covid_case_stats cs
        ON cs.country_id = w.country_id
    GROUP BY w.country_id
)
SELECT
    c.name AS country,
    start_confirmed,
    end_confirmed,
    CASE
        WHEN start_confirmed = 0 THEN NULL
        ELSE ROUND(
            ((end_confirmed - start_confirmed) * 100.0)
            / start_confirmed,
            2
        )
    END AS percentage_increase
FROM country_totals ct
JOIN country c
    ON c.country_id = ct.country_id
ORDER BY percentage_increase DESC;