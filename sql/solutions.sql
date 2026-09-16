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