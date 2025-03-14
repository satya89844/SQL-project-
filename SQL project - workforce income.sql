create database workforce_income


SELECT * FROM salaries;

--Investigating the job market based on company size in 2021
SELECT 
    company_size,
    COUNT(*) AS total_jobs,
    AVG(salary_in_usd) AS avg_salary_usd,
    MIN(salary_in_usd) AS min_salary_usd,
    MAX(salary_in_usd) AS max_salary_usd
FROM salaries
WHERE work_year = 2021
GROUP BY company_size
ORDER BY total_jobs DESC;

--Top 2 job titles with the highest average salary for part-time positions in 2023:

SELECT TOP 2
    job_title, 
    AVG(salary_in_usd) AS avg_salary_usd
FROM salaries
WHERE work_year = 2023 
AND employment_type = 'PT'  -- PT stands for Part-Time
GROUP BY job_title
ORDER BY avg_salary_usd DESC;

--Countries where mid-level salary is higher than the overall mid-level salary in 2023

  SELECT AVG(salary_in_usd) AS overall_avg_mid_salary
FROM salaries
WHERE work_year = 2023 
AND experience_level = 'MI';

SELECT 
    employee_residence AS country,
    AVG(salary_in_usd) AS avg_mid_level_salary
FROM salaries
WHERE work_year = 2023 
AND experience_level = 'MI'  
GROUP BY employee_residence
HAVING AVG(salary_in_usd) > (
    SELECT AVG(salary_in_usd)
    FROM salaries
    WHERE work_year = 2023 
    AND experience_level = 'MI'
);


--Highest and lowest average salary locations for senior-level employees in 2023
WITH SeniorLevelSalaries AS (
    SELECT 
        employee_residence AS location,
        AVG(salary_in_usd) AS avg_salary
    FROM salaries
    WHERE work_year = 2023
    AND experience_level = 'SE'  -- 'SE' stands for Senior-Level
    GROUP BY employee_residence
)
SELECT 
    location, avg_salary,
    CASE 
        WHEN avg_salary = (SELECT MAX(avg_salary) FROM SeniorLevelSalaries) THEN 'Highest'
        WHEN avg_salary = (SELECT MIN(avg_salary) FROM SeniorLevelSalaries) THEN 'Lowest'
    END AS salary_status
FROM SeniorLevelSalaries
WHERE avg_salary IN (
    (SELECT MAX(avg_salary) FROM SeniorLevelSalaries),
    (SELECT MIN(avg_salary) FROM SeniorLevelSalaries)
);


--Salary growth rates by job title
WITH SalaryComparison AS (
    SELECT 
        job_title,
        AVG(CASE WHEN work_year = 2022 THEN salary_in_usd END) AS avg_salary_2022,
        AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS avg_salary_2023
    FROM salaries
    WHERE work_year IN (2022, 2023)
    GROUP BY job_title
)
SELECT 
    job_title,
    avg_salary_2022,
    avg_salary_2023,
    CASE 
        WHEN avg_salary_2022 IS NOT NULL AND avg_salary_2022 > 0 
        THEN ROUND(((avg_salary_2023 - avg_salary_2022) / avg_salary_2022) * 100, 2)
        ELSE NULL
    END AS salary_growth_rate_percentage
FROM SalaryComparison
ORDER BY salary_growth_rate_percentage DESC;

--Top three countries with the highest salary growth for entry- level roles from 2020 to 2023
WITH SalaryGrowth AS (
    SELECT 
        employee_residence AS country,
        COUNT(*) AS employee_count,
        AVG(CASE WHEN work_year = 2020 THEN salary_in_usd END) AS avg_salary_2020,
        AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS avg_salary_2023
    FROM salaries
    WHERE work_year IN (2020, 2023)  
    AND experience_level = 'EN'  -- 'EN' stands for Entry-Level
    GROUP BY employee_residence
    HAVING COUNT(*) > 50  -- Ensure countries have more than 50 employees
)
SELECT TOP 3 
    country,
    employee_count,
    avg_salary_2020,
    avg_salary_2023,
    ROUND(((avg_salary_2023 - avg_salary_2020) / avg_salary_2020) * 100, 2) AS salary_growth_rate_percentage
FROM SalaryGrowth
WHERE avg_salary_2020 IS NOT NULL AND avg_salary_2023 IS NOT NULL
ORDER BY salary_growth_rate_percentage DESC;


--Updating remote work ratio for employees earning more than $90,000 in the US and AU:
UPDATE salaries
SET remote_ratio = 100
WHERE salary_in_usd > 90000
AND employee_residence IN ('US', 'AU');

SELECT employee_residence, salary_in_usd, remote_ratio 
FROM salaries
WHERE salary_in_usd > 90000 
AND employee_residence IN ('US', 'AU');

--Year with the highest average salary for each job title:
WITH AvgSalaryByYear AS (
    SELECT 
        job_title,
        work_year,
        ROUND(AVG(salary_in_usd), 2) AS avg_salary
    FROM salaries
    GROUP BY job_title, work_year
),
RankedSalaries AS (
    SELECT 
        job_title,
        work_year,
        avg_salary,
        RANK() OVER (PARTITION BY job_title ORDER BY avg_salary DESC) AS salary_rank
    FROM AvgSalaryByYear
)
SELECT 
    job_title,
    work_year AS highest_salary_year,
    avg_salary AS highest_avg_salary
FROM RankedSalaries
WHERE salary_rank = 1
ORDER BY highest_avg_salary DESC;

--Percentage of employment types for different job titles:
WITH EmploymentCounts AS (
    SELECT 
        job_title,
        COUNT(*) AS total_count,
        COUNT(CASE WHEN employment_type = 'FT' THEN 1 END) AS full_time_count,
        COUNT(CASE WHEN employment_type = 'PT' THEN 1 END) AS part_time_count,
        COUNT(CASE WHEN employment_type = 'CT' THEN 1 END) AS contract_count,
        COUNT(CASE WHEN employment_type = 'FL' THEN 1 END) AS freelance_count
    FROM salaries
    GROUP BY job_title
)
SELECT 
    job_title,
    total_count,
    ROUND((full_time_count * 100.0 / total_count), 2) AS full_time_percentage,
    ROUND((part_time_count * 100.0 / total_count), 2) AS part_time_percentage,
    ROUND((contract_count * 100.0 / total_count), 2) AS contract_percentage,
    ROUND((freelance_count * 100.0 / total_count), 2) AS freelance_percentage
FROM EmploymentCounts
ORDER BY total_count DESC;


--COUNTRIES OFFERING FULL REMOTE WORK FOR MANAGERS WITH SALARIES OVER $90,000
SELECT 
    employee_residence AS country,
    COUNT(*) AS num_of_managers
FROM salaries
WHERE job_title LIKE '%Manager%'
AND salary_in_usd > 90000
AND remote_ratio = 100
GROUP BY employee_residence
ORDER BY num_of_managers DESC;


--12 Top 5 countries with the most large companies
SELECT TOP 5 
    company_location AS country,
    COUNT(*) AS large_company_count
FROM salaries
WHERE company_size = 'L'
GROUP BY company_location
ORDER BY large_company_count DESC;

--13Percentage of employees with fully remote roles earning more than $100,000
WITH TotalEmployees AS (
    SELECT COUNT(*) AS total_count FROM salaries
),
RemoteHighEarners AS (
    SELECT COUNT(*) AS remote_high_earners_count
    FROM salaries
    WHERE remote_ratio = 100 
    AND salary_in_usd > 100000
)
SELECT 
    r.remote_high_earners_count,
    t.total_count,
    ROUND((r.remote_high_earners_count * 100.0 / t.total_count), 2) AS percentage_remote_high_earners
FROM RemoteHighEarners r, TotalEmployees t;



--14Locations where entry-level average salaries exceed market average for entry level:

WITH MarketAvg AS (
    -- Calculate the overall market average salary for entry-level roles
    SELECT AVG(salary_in_usd) AS overall_market_avg
    FROM salaries
    WHERE experience_level = 'EN'
),
LocationAvg AS (
    -- Calculate location-wise average salary for entry-level roles
    SELECT 
        employee_residence AS location,
        AVG(salary_in_usd) AS avg_salary
    FROM salaries
    WHERE experience_level = 'EN'
    GROUP BY employee_residence
)
SELECT 
    l.location,
    l.avg_salary,
    m.overall_market_avg
FROM LocationAvg l
JOIN MarketAvg m ON l.avg_salary > m.overall_market_avg
ORDER BY l.avg_salary DESC;

-- 15Countries paying the maximum average salary for each job title:
WITH JobSalaryByCountry AS (
    -- Calculate the average salary for each job title in each country
    SELECT 
        job_title, 
        employee_residence AS country, 
        AVG(salary_in_usd) AS avg_salary
    FROM salaries
    GROUP BY job_title, employee_residence
),
MaxSalaries AS (
    -- Get the max average salary for each job title
    SELECT 
        job_title, 
        MAX(avg_salary) AS max_avg_salary
    FROM JobSalaryByCountry
    GROUP BY job_title
)
-- Find the country that pays this max salary for each job title
SELECT 
    j.job_title, 
    j.country, 
    j.avg_salary AS max_avg_salary
FROM JobSalaryByCountry j
JOIN MaxSalaries m 
    ON j.job_title = m.job_title 
    AND j.avg_salary = m.max_avg_salary
ORDER BY max_avg_salary DESC;

--16 Countries with sustained salary growth over three years
WITH CountryYearlySalary AS (
    -- Calculate the average salary per country per year
    SELECT 
        employee_residence AS country, 
        work_year, 
        AVG(salary_in_usd) AS avg_salary
    FROM salaries
    GROUP BY employee_residence, work_year
),
GrowthCheck AS (
    -- Join salary data for three consecutive years and check growth trend
    SELECT 
        c1.country,
        c1.avg_salary AS salary_2021,
        c2.avg_salary AS salary_2022,
        c3.avg_salary AS salary_2023
    FROM CountryYearlySalary c1
    JOIN CountryYearlySalary c2 
        ON c1.country = c2.country AND c1.work_year = 2021 AND c2.work_year = 2022
    JOIN CountryYearlySalary c3 
        ON c1.country = c3.country AND c3.work_year = 2023
    WHERE c1.avg_salary < c2.avg_salary 
      AND c2.avg_salary < c3.avg_salary  -- Ensures continuous growth
)
SELECT * FROM GrowthCheck
ORDER BY salary_2023 DESC;



--17 PERCENTAGE OF FULLY REMOTE WORK BY EXPERIENCE LEVEL (2021 VS 2024)
WITH TotalEmployees AS (
    -- Count total employees per experience level in 2021 & 2024
    SELECT 
        experience_level, 
        work_year, 
        COUNT(*) AS total_count
    FROM salaries
    WHERE work_year IN (2021, 2024)
    GROUP BY experience_level, work_year
),
RemoteEmployees AS (
    -- Count fully remote employees per experience level in 2021 & 2024
    SELECT 
        experience_level, 
        work_year, 
        COUNT(*) AS remote_count
    FROM salaries
    WHERE work_year IN (2021, 2024) 
      AND remote_ratio = 100
    GROUP BY experience_level, work_year
)
-- Calculate percentage of fully remote employees
SELECT 
    t.experience_level, 
    t.work_year, 
    r.remote_count, 
    t.total_count, 
    ROUND((r.remote_count * 100.0 / t.total_count), 2) AS remote_percentage
FROM TotalEmployees t
JOIN RemoteEmployees r 
    ON t.experience_level = r.experience_level 
    AND t.work_year = r.work_year
ORDER BY t.experience_level, t.work_year;

--18 Average salary increase percentage by experience level and job title (2023 to 2024):
WITH SalaryByYear AS (
    -- Calculate the average salary per experience level and job title for 2023 & 2024
    SELECT 
        experience_level, 
        job_title, 
        work_year, 
        AVG(salary_in_usd) AS avg_salary
    FROM salaries
    WHERE work_year IN (2023, 2024)
    GROUP BY experience_level, job_title, work_year
),
SalaryComparison AS (
    -- Join 2023 and 2024 salary data
    SELECT 
        s23.experience_level, 
        s23.job_title, 
        s23.avg_salary AS avg_salary_2023,
        s24.avg_salary AS avg_salary_2024,
        ROUND(((s24.avg_salary - s23.avg_salary) / s23.avg_salary) * 100, 2) AS salary_increase_percentage
    FROM SalaryByYear s23
    JOIN SalaryByYear s24 
        ON s23.experience_level = s24.experience_level
        AND s23.job_title = s24.job_title
        AND s23.work_year = 2023
        AND s24.work_year = 2024
)
SELECT * FROM SalaryComparison
ORDER BY salary_increase_percentage DESC;

