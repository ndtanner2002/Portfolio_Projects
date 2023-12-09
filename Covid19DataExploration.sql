	Select *
	From PortfolioProject..CovidDeaths
	Where continent is not null
	Order by 3,4

	Select *
	From PortfolioProject..CovidVaccinations
	Order by 3,4

-- Select data that we are going to be using

	Select location, date, total_cases, new_cases, total_deaths, population
	From PortfolioProject..CovidDeaths
	Order by 1,2

-- Looking at Total Cases vs Total Deaths
-- shows likelihood of death if you contract Covid-19 in your country

	SELECT location, date, total_cases, total_deaths, (CONVERT(DECIMAL, total_deaths) / CONVERT(DECIMAL, total_cases)) * 100 AS DeathPercentage
	FROM PortfolioProject..CovidDeaths
	where location like'%states%'
	Order by 1,2;

-- Looking at Total Cases vs Population
-- shows what percentage of population got Covid-19

	SELECT location, date, total_cases, population, (CONVERT(DECIMAL, total_cases) / CONVERT(DECIMAL, population)) * 100 AS InfectedPopulatinPercentage
	FROM PortfolioProject..CovidDeaths
	--where location like'%states%'
	Order by 1,2;

-- Looking at what countries have the highest infection rates

	SELECT location, population, max(total_cases) as HighestInfectionCount, max((CONVERT(DECIMAL, total_cases) / CONVERT(DECIMAL, population))) * 100 AS HighestInfectionPercentage
	FROM PortfolioProject..CovidDeaths
	-- where location like'%states%'
	Group by location, population
	Order by HighestInfectionPercentage desc;

-- Shows the countries with the highest death count per population

	SELECT location, max(cast(total_deaths as int)) as TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	-- where location like'%states%'
	Where continent is null
	Group by location
	Order by TotalDeathCount desc;

-- This shows the continents with the highest death counts.

	SELECT continent, max(cast(total_deaths as int)) as TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	-- where location like'%states%'
	Where continent is not null
	Group by continent
	Order by TotalDeathCount desc;

-- Global numbers

SELECT
    --date,
    SUM(new_cases) as total_cases,
    SUM(CAST(new_deaths AS INT)) as total_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL -- Prevent division by zero
        ELSE (SUM(CAST(new_deaths AS INT)) * 100.0) / SUM(new_cases)
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY date;


-- Looking at total population vs vaccinations


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date rows between unbounded preceding and current row) as rolling_people_vaccinated
-- , (rolling_people_vaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- using a CTE

With popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date rows between unbounded preceding and current row) as rolling_people_vaccinated
-- , (rolling_people_vaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (rolling_people_vaccinated/population)*100 as rolling_vaccination_rate
from popvsvac



-- using a Temp table

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime, 
population numeric, 
new_vaccinations numeric, 
rolling_people_vaccinated numeric
)

insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date rows between unbounded preceding and current row) as rolling_people_vaccinated
-- , (rolling_people_vaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (rolling_people_vaccinated/population)*100 as rolling_vaccination_rate
from #PercentPopulationVaccinated


-- creating view to store data for later visualizations

USE PortfolioProject;
GO
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date rows between unbounded preceding and current row) as rolling_people_vaccinated
-- , (rolling_people_vaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


Select * 
from PercentPopulationVaccinated
