-- Covid 19 Data Exploration

-- This project was based on the data exploration
-- presented on https://youtu.be/qfyynHBFOsM

USE CovidProject;

-- Understand data

SELECT COUNT(*) as VacCount
FROM covidvaccinations;

SELECT COUNT(*) as DeaCount
FROM coviddeaths;

SELECT *
FROM coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 3, 4;

SELECT *
FROM covidvaccinations
WHERE continent IS NOT NULL 
ORDER BY 3, 4;

SELECT location,
	   date,
	   total_cases,
	   new_cases,
	   total_deaths,
	   population
FROM coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Brazil

SELECT location, 
	   date,
	   total_cases,
	   total_deaths,
	   100*(total_deaths/total_cases) as DeathPercentage
FROM coviddeaths
WHERE location LIKE '%brazil%' AND continent IS NOT NULL 
ORDER BY 2;

-- Total Cases vs Population
-- Shows what percentage of population was infected with Covid in Brazil everyday

SELECT location,
	   date,
	   population,
	   total_cases,
	   100*(total_cases/population) as PercentPopulationInfected
FROM coviddeaths
WHERE location LIKE '%brazil%'
ORDER BY 2;

-- Countries with Highest Infection Rate compared to Population

SELECT location,
	   population,
	   MAX(total_cases) as HighestInfectionCount,
	   100*Max((total_cases/population)) as PercentPopulationInfected
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with the highest death count per population

SELECT location,
	   MAX(CAST(total_deaths AS INT)) AS Total_Death_Count -- per country
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Continents with the highest death count per population

Select continent,
	   MAX(cast(Total_deaths AS INT)) AS Total_Death_Count -- per continent
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- Calculate world population

WITH ContPop (continent, TotalPopulation) AS (
	Select continent,
		   SUM(DISTINCT population)
	FROM coviddeaths
	WHERE continent IS NOT NULL
	GROUP BY continent
)
SELECT SUM(TotalPopulation) AS World_Population
FROM ContPop;

-- Total deaths in the world

SELECT SUM(new_cases) AS Total_cases,
	   SUM(cast(new_deaths AS INT)) AS Total_deaths,
	   100*SUM(cast(new_deaths AS INT))/SUM(new_Cases) AS Death_Percentage
FROM coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated) AS (
	SELECT dea.continent,
		   dea.location,
		   dea.date,
		   dea.population,
		   vac.new_vaccinations,
		   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)
	FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *,
	   100*(Rolling_People_Vaccinated/Population) AS Percent_Vaccinated
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM coviddeaths dea
JOIN covidVaccinations vac
On dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *,
	   100*(RollingPeopleVaccinated/Population) AS Percent_Vaccinated
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent,
			dea.location,
			dea.date,
			dea.population,
			vac.new_vaccinations,
			SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
	FROM coviddeaths dea
	JOIN covidVaccinations vac
	On dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT TOP(1000) * FROM PercentPopulationVaccinated;