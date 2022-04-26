/*

COVID-19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Dataset: https://ourworldindata.org/covid-deaths

*/

SELECT * 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL


-- Select data that is being used 

SELECT location, date, total_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


-- Total Cases vs Total Deaths 
-- Shows the likelyhood if you contract Covid in USA 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY location, date


-- Total Cases vs Populations 
-- Shows what percentage of population got Covid

SELECT location, date, total_cases, population, (total_cases/population) * 100 AS PercentOfPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%States'
AND continent IS NOT NULL
ORDER BY location, date


-- Looking at Countries with highest infection rate compared to population.

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentOfPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%States'
GROUP BY location, population
ORDER BY PercentOfPopulationInfected desc


-- Showing Countries with highest death count per Population. 

SELECT location, MAX(cast(total_deaths as bigint)) AS TotalDeathCount 
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%States'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc


-- Showing Continent with the highest death count per population.

SELECT continent, Max(cast(total_deaths AS bigint)) * 100 as TotalDeathCount 
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%States'
WHERE continent IS NOT NULL
-- WHERE continent IS NULL
GROUP BY continent
ORDER BY TotalDeathCount desc


-- Global Numbers 

SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS bigint)) AS TotalDeaths, SUM(cast(new_deaths AS bigint))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%States'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Total Cases Globally 

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS bigint)) AS TotalDeaths, SUM(cast(new_deaths AS bigint))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%States'
WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY date


SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
WHERE continent IS NOT NULL


-- Join CovidDeaths & CovidVaccinations tables 

SELECT *
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date


-- Total Polulation vs Vaccinations 

SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY continent, location ASC, date


-- Total Polulation vs Vaccinations 
-- Shows Percentage of Population that has recieved at least one Covid Vaccine. 
-- Rolling number that increases over time

SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS ContinuousPeopleVaccinated 
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location ASC, date


-- Using CTE to perform Calculation on Partition By in previous query 

WITH CTE_Population_vs_Vaccinations (Continent, Location, Date, Population, New_Vaccinations, ContinuousPeopleVaccinated)
	AS 
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS ContinuousPeopleVaccinated 
	FROM PortfolioProject.dbo.CovidDeaths AS dea
	JOIN PortfolioProject.dbo.CovidVaccinations AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		--ORDER BY location ASC, date
	)
	
SELECT *, (ContinuousPeopleVaccinated / Population) * 100
FROM CTE_Population_vs_Vaccinations


-- Using Temp Table to perform Calculation on Partition previous query

DROP TABLE IF EXISTS #Temp_PercentPopulationVaccinated

CREATE TABLE #Temp_PercentPopulationVaccinated 
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime, 
	Population numeric,
	New_Vaccinations numeric,
	ContinuousPeopleVaccinated numeric
	)

INSERT INTO #Temp_PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS ContinuousPeopleVaccinated 
	FROM PortfolioProject.dbo.CovidDeaths AS dea
	JOIN PortfolioProject.dbo.CovidVaccinations AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		--ORDER BY location ASC, date

SELECT *, (ContinuousPeopleVaccinated / Population) * 100
FROM #Temp_PercentPopulationVaccinated


-- Creating View to to store data for visualizations
-- View for Percentage of Population that has recieved at least one Covid Vaccine.

Create VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS ContinuousPeopleVaccinated 
	FROM PortfolioProject.dbo.CovidDeaths AS dea
	JOIN PortfolioProject.dbo.CovidVaccinations AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL


-- View for Total Death per Continent

CREATE VIEW TotalDeathPerContinent AS
SELECT continent, Max(cast(total_deaths AS bigint)) * 100 as TotalDeathCount 
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%States'
WHERE continent IS NOT NULL
-- WHERE continent IS NULL
GROUP BY continent
--ORDER BY TotalDeathCount desc