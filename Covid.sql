--copy covidvaccinations from 'D:\Projects\Covid\covidvaccinations.csv' with delimiter ';' csv header;
--copy coviddeaths from 'D:\Projects\Covid\coviddeaths.csv' with delimiter ';' csv header;


--SET datestyle to dmy;

--CREATE TABLE covidvaccinations (iso_code text,continent text,location text,date DATE,new_tests numeric,total_tests numeric,total_tests_per_thousand numeric,new_tests_per_thousand numeric,new_tests_smoothed numeric,new_tests_smoothed_per_thousand numeric,positive_rate numeric,tests_per_case numeric,tests_units text,total_vaccinations numeric,people_vaccinated numeric,people_fully_vaccinated numeric,total_boosters numeric,new_vaccinations numeric,new_vaccinations_smoothed numeric,total_vaccinations_per_hundred numeric,people_vaccinated_per_hundred numeric,people_fully_vaccinated_per_hundred numeric,total_boosters_per_hundred numeric,new_vaccinations_smoothed_per_million numeric,new_people_vaccinated_smoothed numeric,new_people_vaccinated_smoothed_per_hundred numeric,stringency_index numeric,population_density numeric,median_age numeric,aged_65_older numeric,aged_70_older numeric,gdp_per_capita numeric,extreme_poverty numeric,cardiovasc_death_rate numeric,diabetes_prevalence numeric,female_smokers numeric,male_smokers numeric,handwashing_facilities numeric,hospital_beds_per_thousand numeric,life_expectancy numeric,human_development_index numeric,excess_mortality_cumulative_absolute numeric,excess_mortality_cumulative numeric,excess_mortality numeric,excess_mortality_cumulative_per_million numeric);
--CREATE TABLE coviddeaths(iso_code text,continent text,location text,date date,population numeric,total_cases numeric,new_cases numeric,new_cases_smoothed numeric, total_deaths numeric, new_deaths numeric, new_deaths_smoothed numeric,total_cases_per_million numeric, new_cases_per_million numeric,new_cases_smoothed_per_million numeric,total_deaths_per_million numeric,new_deaths_per_million numeric, new_deaths_smoothed_per_million numeric, reproduction_rate numeric, icu_patients numeric, icu_patients_per_million numeric,hosp_patients numeric, hosp_patients_per_million numeric, weekly_icu_admissions numeric, weekly_icu_admissions_per_million numeric, weekly_hosp_admissions numeric,weekly_hosp_admissions_per_million numeric);


--Select data that we are going to be using 
select location, date, total_cases, new_cases, total_deaths, population 
from coviddeaths
where continent is not null --deselects values for entire continents (Europe, Asia, etc.)
order by 1,2;

-- Looking at Total Cases VS Total Deaths
--Shows the probability of dying from covidae if already infected in each country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deaths_per
from coviddeaths
--where location = 'Russia'
order by 1,2;



--Total number of cases compared to population size
select location, date, total_cases, population, (total_cases/population)*100 as cases_per
from coviddeaths
--where location = 'Russia'
order by 1,2;


--Countries with the highest number of infected persons relative to the population
select location, max(total_cases) as HighestInfectionCount, population, max((total_cases/population)*100) as cases_per
from coviddeaths
where continent is not null 
group by location, population
order by cases_per desc;


--Countries with the highest number of fatalities
select location, max(total_deaths) as TotalDeathsCount
from coviddeaths
where continent is not null
group by location
order by TotalDeathsCount desc;
--Countries with the highest number of fatalities
Create View most_count_deaths_location as (	
select location, max(total_deaths) as TotalDeathsCount
from coviddeaths
where continent is not null
group by location
order by TotalDeathsCount desc
)


--Countries with the highest percentage of covid mortality relative to population
select location, max(total_deaths) as HighestDeathsCount, population, max((total_Deaths/population)*100) as Deaths_per
from coviddeaths
where continent is not null
group by location, population
order by deaths_per desc;
-- Creating a VIEW for subsequent visualization
Create View most_deathsper_location as (	
select location, max(total_deaths) as HighestDeathsCount, population, max((total_Deaths/population)*100) as Deaths_per
from coviddeaths
where continent is not null
group by location, population
order by deaths_per desc
)


--Continents with the highest number of fatalities
select location, max(total_deaths) as TotalDeathsCount
from coviddeaths
where continent is null
group by location
order by TotalDeathsCount desc;
-- Creating a VIEW for subsequent visualization
Create View most_continent_count_deaths as (	
select location, max(total_deaths) as TotalDeathsCount
from coviddeaths
where continent is null
group by location
order by TotalDeathsCount desc
)


--Global figures by date
select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as deaths_per
from coviddeaths
--where location = 'Russia'
Where continent is not null
group by date
having sum(new_cases) <> 0
order by 1,2;


--Global figures for the entire period
select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as deaths_per
from coviddeaths
--where location = 'Russia'
Where continent is not null
--group by date
--having sum(new_cases) <> 0
order by 1,2;


--Number of people immunized
Select vac.continent, vac.location, vac.date, total_vaccinations, vac.new_vaccinations
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where vac.continent is not null
order by 2,3;


--Number of vaccinated persons with demonstrable change from day to day
Select vac.continent, vac.location, vac.date, vac.new_vaccinations, sum(vac.new_vaccinations) 
over (partition by vac.location order by vac.location, vac.date) as sum_vaccinations
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where vac.continent is not null
order by 2,3;


--Number vaccinated relative to the population, using CTE
with VacVsPop (continent, location, date, population, new_vaccinations, sum_vaccinations)
as(
Select vac.continent, vac.location, vac.date, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) 
over (partition by vac.location order by vac.location, vac.date) as sum_vaccinations
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where vac.continent is not null
order by 2,3
)
select *, (sum_vaccinations/population)*100 as vaccination_per from VacVsPop;


--Number of vaccinated relative to the population, using a time table
drop table if exists vaccination_per; --delete the temporary table if it already exists
create temp table vaccination_per
(
	continent text,
	location text,
	date date,
	population numeric,
	new_vaccination numeric,
	sum_vaccinations numeric
);
insert into vaccination_per
Select vac.continent, vac.location, vac.date, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) 
over (partition by vac.location order by vac.location, vac.date) as sum_vaccinations
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where vac.continent is not null
order by 2,3;

select *, (sum_vaccinations/population)*100 as vaccination_per from vaccination_per;
-- Creating a VIEW for subsequent visualization
Create View vaccination_per as  (	
Select vac.continent, vac.location, vac.date, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) 
over (partition by vac.location order by vac.location, vac.date) as sum_vaccinations
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where vac.continent is not null
order by 2,3
)


