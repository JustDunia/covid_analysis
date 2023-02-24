-- total cases vs total deaths in Poland

SELECT
location, date, total_cases, total_deaths, (total_deaths/total_cases*100) death_rate
FROM CovidDeaths
WHERE location = 'Poland'
ORDER BY 1,2


-- total cases vs population in Poland

SELECT
location, date, total_cases, population, (total_cases/population*1000) infection_rate_per_mille
FROM CovidDeaths
WHERE location = 'Poland'
ORDER BY 1,2


-- countries with the highest infection rate

SELECT
location, population, MAX(total_cases) total_cases, MAX((total_cases/population*1000)) infection_rate_per_mille
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY population DESC


-- countries with the highest covid mortality rate

SELECT
location, MAX(total_cases) total_cases, MAX(CAST(total_deaths AS int)) total_deaths, MAX(CAST(total_deaths AS int))/MAX(total_cases)*100 mortality_percent
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY mortality_percent DESC


-- Create view for continents by mortality rate

CREATE VIEW MortalitRates_by_continent
AS
SELECT
location, MAX(total_cases) total_cases, MAX(CAST(total_deaths AS int)) total_deaths, MAX(CAST(total_deaths AS int))/MAX(total_cases)*100 mortality_percent
FROM CovidDeaths
WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location


-- Selecting view ordered by the highest mortality rate

SELECT *
FROM MortalitRates_by_continent
ORDER BY 4 DESC


 -- Daily global new cases and deaths

SELECT
date, SUM(new_cases) cases, SUM(CAST(new_deaths AS int)) deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Global new cases and deaths by month

SELECT
MONTH(date) month, YEAR(date) year, SUM(new_cases) NewCases, SUM(CAST(new_deaths AS int)) NewDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY YEAR(date), MONTH(date)
ORDER BY NewCases DESC


-- Procedure for obtaining vaccinations cumulative count among population of selected country

CREATE PROCEDURE VaccCount_by_location @location varchar(50)
AS
SELECT
death.location, death.date, death.population, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations AS int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) total_vaccinations,
(SUM(CAST(vacc.new_vaccinations AS int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date)) / population * 100 vaccination_rate 
FROM CovidDeaths death
JOIN CovidVaccinations vacc
	ON death.date = vacc.date
	AND death.location = vacc.location
WHERE death.location = @location
ORDER BY 2


-- Procedure execution for Poland

EXEC VaccCount_by_location @location = 'Poland'


-- Countries with fully vaccinated people over 10% of population

WITH CTE_fully_vaccinated_people AS
(
SELECT
death.location, death.population, MAX(CONVERT(int, vacc.people_fully_vaccinated)) fully_vaccinated
FROM CovidDeaths death
JOIN CovidVaccinations vacc
	ON death.date = vacc.date
	AND death.location = vacc.location
WHERE death.location IS NOT NULL
GROUP BY death.location, death.population
HAVING MAX(CONVERT(int, vacc.people_fully_vaccinated)) IS NOT NULL
)

SELECT location, fully_vaccinated/population*100 vaccination_rate
FROM CTE_fully_vaccinated_people
WHERE fully_vaccinated/population*100 >= 10
ORDER BY vaccination_rate DESC