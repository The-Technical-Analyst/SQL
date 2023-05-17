/****** Script for SelectTopNRows command from SSMS  ******/
SELECT *
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$

--USEFUL DATA

SELECT Location, date, total_cases,new_cases,total_deaths, population
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
Order by 1,2

--(1a) Total_Cases Vs Total_Deaths (Death_Percentage)
SELECT Location, date, total_cases,new_cases,total_deaths, 
(total_Deaths/(convert(float,total_cases)))*100 AS Death_Percentage
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
--WHERE Location like '%states%'
Order by 1,2

--(2a) Total Cases Vs Population
SELECT Location, date, total_cases,total_deaths, Population,
(total_cases/population)*100 AS Case_Per_Population
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE Location like '%Nigeria%'
Order by 1,2

--(2b) Total Deaths Vs Population
SELECT Location, date, total_cases,total_deaths, Population,
(total_deaths/population)*100 AS Deaths_Per_Population
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
--WHERE Location like '%Nigeria%'
Order by Deaths_Per_Population asc

--(2c) Country with Highest Death Rate By Popuation
SELECT Location, population, MAX(cast(total_deaths as int)) AS Highest_Death_Count,
MAX((total_deaths/population))*100 AS Percent_Population_Death
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
--WHERE Location like '%Nigeria%'
WHERE continent is not null --AND location = 'Nigeria'
GROUP BY Location,  population
ORDER BY Highest_Death_Count desc


--(2d) Country with Highest Infection Rate
SELECT Location, population, MAX(total_cases) AS Highest_Infection_Count,
MAX((total_cases/population))*100 AS Percent_Population_Infected
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
GROUP BY Location, population
ORDER BY Percent_Population_Infected desc

----(2e) Continent with Higest death count
SELECT continent, MAX(cast (total_deaths as int)) AS Highest_Death_Count_By_Continent
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
GROUP BY continent
ORDER BY Highest_Death_Count_By_Continent desc
---- THIS SECTION NEEDS TO BE REVIEWED THE DATA SEEMS TO BE INCONSISTENT AND COULD PROBABLY BE INCORRECT

--(2e[ii]) Continent with Highest Infection Rate
SELECT continent, MAX(cast (total_cases as int)) AS Highest_Infection_Count_By_Continent
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
GROUP BY continent
ORDER BY Highest_Infection_Count_By_Continent desc

--(3) GLOBAL NUMBERS I.E DEATH COUNT
SELECT   SUM(cast (new_cases as float)) AS Reported_Cases, SUM(cast (new_deaths as float)) AS Reported_Deaths,
SUM(cast (new_deaths as float))/SUM(cast (new_cases as float))*100 AS Reported_Death_Percentage
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
--GROUP BY continent
ORDER BY Reported_Death_Percentage asc

--VACCINATIONS COUNT
SELECT Deaths.continent, Deaths.date, Deaths.location, Deaths.population, Vaccinations.new_vaccinations,
SUM(CAST(Vaccinations.new_vaccinations AS float)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS Vaccination_Count
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$ AS Deaths
JOIN COVID_ANALYSIS_PROJECT..Covid_Vaccinations$ AS Vaccinations
ON Deaths.location = Vaccinations.location
AND Deaths.date = Vaccinations.date
WHERE Deaths.continent is not null --AND Vaccinations.new_vaccinations is not null
ORDER BY Deaths.location


--USE CTE
WITH PopulationVaccinated (continent, date, location, population, new_vaccinations, Vaccination_Count)
AS 
(
SELECT Deaths.continent, Deaths.date, Deaths.location, Deaths.population, Vaccinations.new_vaccinations,
SUM(CAST(Vaccinations.new_vaccinations AS float)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS Vaccination_Count
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$ AS Deaths
JOIN COVID_ANALYSIS_PROJECT..Covid_Vaccinations$ AS Vaccinations
ON Deaths.location = Vaccinations.location
AND Deaths.date = Vaccinations.date
WHERE Deaths.continent is not null AND Vaccinations.new_vaccinations is not null
--ORDER BY Deaths.location
)
SELECT *, (Vaccination_Count/population)*100 AS Percentage_Population_Vaccinated
FROM PopulationVaccinated



-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations
, SUM(CONVERT(float,Vaccinations.new_vaccinations)) OVER (Partition by Deaths.Location Order by Deaths.location, Deaths.Date) as RollingPeopleVaccinated
--,(Vaccination_Count/population)*100
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$ AS Deaths
JOIN COVID_ANALYSIS_PROJECT..Covid_Vaccinations$ AS Vaccinations
ON Deaths.location = Vaccinations.location
AND Deaths.date = Vaccinations.date
--where dea.continent is not null 
--order by 2,3

Select * --(Vaccination_Count/population)*100
From #PercentPopulationVaccinated


-- CREATING VIEWS FOR VISUALIZATION

-- 1 POPULATION VACCINATED
Create View Population_Vaccinated AS 
Select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
SUM(CONVERT(float,Vaccinations.new_vaccinations)) OVER (PARTITION BY Deaths.Location ORDER BY Deaths.location, Deaths.Date) as Vaccination_Count
--,(Vaccination_Count/population)*100
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$ AS Deaths
JOIN COVID_ANALYSIS_PROJECT..Covid_Vaccinations$ AS Vaccinations
ON Deaths.location = Vaccinations.location
AND Deaths.date = Vaccinations.date
where Deaths.continent is not null 


--2 DEATH PERCENTAGE
CREATE VIEW Death_Percentage AS
SELECT Location, date, total_cases,new_cases,total_deaths, 
(total_Deaths/(convert(float,total_cases)))*100 AS Death_Percentage
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
--WHERE Location like '%states%'



--3 REPORTED CASES COMPARED WITH TOTAL POPULATION
CREATE VIEW Case_Per_Population AS
SELECT Location, date, total_cases,total_deaths, Population,
(total_cases/population)*100 AS Case_Per_Population
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE Location like '%Nigeria%'



--4 REPORTED DEATHS COMPARED WITH TOTAL POPULATION
CREATE VIEW Percent_Population_Death AS 
SELECT Location, population, MAX(cast(total_deaths as int)) AS Highest_Death_Count,
MAX((total_deaths/population))*100 AS Percent_Population_Death
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
--WHERE Location like '%Nigeria%'
WHERE continent is not null --AND location = 'Nigeria'
GROUP BY Location, population


--5 INFECTION RANKING BY COUNTRY
CREATE VIEW Percent_Population_Infected AS
SELECT Location, population, MAX(total_cases) AS Highest_Infection_Count,
MAX((total_cases/population))*100 AS Percent_Population_Infected
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
GROUP BY Location, population

--6 DEATH RANKING BY CONTINENT
CREATE VIEW Highest_Death_Count_By_Continent AS
SELECT continent, MAX(cast (total_deaths as int)) AS Highest_Death_Count_By_Continent
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
GROUP BY continent


--7 DEATH PERCENTAGE BY NEW CASES
CREATE VIEW Reported_Death_Percentage AS
SELECT   SUM(cast (new_cases as float)) AS Reported_Cases, SUM(cast (new_deaths as float)) AS Reported_Deaths,
SUM(cast (new_deaths as float))/SUM(cast (new_cases as float))*100 AS Reported_Death_Percentage
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
GROUP BY continent

--8 INFECTION RANKING BY CONTINENT
CREATE VIEW Highest_Infection_Count_By_Continent AS
SELECT continent, MAX(cast (total_cases as int)) AS Highest_Infection_Count_By_Continent
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$
WHERE continent is not null
GROUP BY continent


--9 VACCINATION COUNT
CREATE VIEW Vaccination_Count AS
SELECT Deaths.continent, Deaths.date, Deaths.location, Deaths.population, Vaccinations.new_vaccinations,
SUM(CAST(Vaccinations.new_vaccinations AS float)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS Vaccination_Count
FROM COVID_ANALYSIS_PROJECT..Covid_Deaths$ AS Deaths
JOIN COVID_ANALYSIS_PROJECT..Covid_Vaccinations$ AS Vaccinations
ON Deaths.location = Vaccinations.location
AND Deaths.date = Vaccinations.date
WHERE Deaths.continent is not null --AND Vaccinations.new_vaccinations is not null
