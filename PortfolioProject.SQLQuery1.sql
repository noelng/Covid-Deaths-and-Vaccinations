use PortfolioProject;

select * 
from CovidVaccinations
where location like '%income%'
order by 3,4

select * 
from CovidDeaths
order by 3,4

------------------------ By location ------------------------

------------------------ Select data to be used ------------------------
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2

------------------------ Total cases vs total deaths ------------------------
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'Death Percentage (%)'
from CovidDeaths
where location like '%states%'
order by 1,2 

------------------------ Total cases vs population ------------------------
select location, date, total_cases, population, (total_cases/population)*100 as 'Infected Population Percentage (%)'
from CovidDeaths
where location like '%states%'
order by 1,2 

------------------------ Highest infection rate to population ------------------------
select location, max(total_cases) as totalnumberofinfection, population, max((total_cases/population))*100 as 'Infected Population Percentage (%)'
from CovidDeaths
group by location, population
order by 'Infected Population Percentage (%)' DESC

------------------------ Countries with highest death count per population ------------------------
select location, max(cast(total_deaths as int)) as totalnumberofdeath
from CovidDeaths
where continent is not null
group by location
order by totalnumberofdeath DESC

------------------------ By continent ------------------------

------------------------ Continents with highest death count per population ------------------------
select location, max(cast(total_deaths as int)) as totalnumberofdeath
from CovidDeaths
where continent is null
group by location
order by totalnumberofdeath DESC

select continent, max(cast(total_deaths as int)) as totalnumberofdeath
from CovidDeaths
where location not like '%income%' AND continent is not null 
group by continent
order by totalnumberofdeath DESC

------------------------ Global numbers ------------------------
select date, sum(new_cases) as totalcases, sum(cast(new_deaths as int)) as totaldeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as 'Death Percentage (%)'
from CovidDeaths
where continent is not null
group by date
order by date

select sum(new_cases) as totalcases, sum(cast(new_deaths as int)) as totaldeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as 'Death Percentage (%)'
from CovidDeaths
where continent is not null

------------------------ Total population vs vaccinations ------------------------
select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		sum(convert(bigint, v.new_vaccinations)) over (partition by d.location  order by d.location, d.date) as total_vaccination, 
		((sum(convert(bigint, v.new_vaccinations)) over (partition by d.location  order by d.location, d.date))/d.population)*100 as vaccination_rate
from CovidDeaths d
join CovidVaccinations1 v
	on d.location = v.location and d.date = v.date
where d.continent is not null
order by 2,3

------------------------ CTE ------------------------
with PopvsVac (continent, location, date, population, new_vaccination, total_vaccination)
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		sum(convert(bigint, v.new_vaccinations)) over (partition by d.location  order by d.location, d.date) as total_vaccination
from CovidDeaths d
join CovidVaccinations v
	on d.location = v.location and d.date = v.date
where d.continent is not null
)
select*, (total_vaccination/population)*100 as percentage
from PopvsVac

------------------------ Using Temp Table to perform Calculation on Partition By in previous query ------------------------
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	and d.date = v.date

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated

------------------------ Creating View to store data for visualizations ------------------------
drop view if exists PercentPopulationVaccinated

create view PercentPopulationVaccinated as
select d.continent, d.location, d.date, d.population, v.new_vaccinations
, sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location, d.Date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 

--
--
--
--
--
--
--
--
--
/*
Queries used for Tableau Project
*/

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location

--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc