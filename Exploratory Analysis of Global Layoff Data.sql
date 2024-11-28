select * from layoffs_staging2;

-- Highest layoff and % percentage layoff by a company

select max(total_laid_off) 'highest layoff by a company', max(percentage_laid_off) 'highest % layoff by a company'
from layoffs_staging2;

-- Companies that laid off 1% of total workforce:

select * from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

-- Companies and number of layoffs:

select company,sum(total_laid_off) 'total layoff count'
from layoffs_staging2
group by company
order by 2 desc;

-- Which industries was most affected?

select industry, sum(total_laid_off) 'total layoff count'
from layoffs_staging2
group by industry
order by 2 desc;

-- Employees in what countries are most affected?

select country, sum(total_laid_off) 'total layoff count'
from layoffs_staging2
group by country
order by 2 desc;

-- What year saw the most layoff?

select year(`date`) as 'year', sum(total_laid_off) 'total layoff count'
from layoffs_staging2
group by year(`date`)
order by 2 desc;

select substr(`date`, 1, 7) 'year-month', sum(total_laid_off) 'total layoff count'
from layoffs_staging2
group by substr(`date`, 1, 7)
order by 1;

-- Layoff breakdown by month

with rolling_sum_cte as 
(
select substr(`date`, 1, 7) as `month`, sum(total_laid_off) total_layoff
from layoffs_staging2
where substr(`date`, 1, 7) is not null
group by substr(`date`, 1, 7)
order by substr(`date`, 1, 7)
)
select 
`month`, 
total_layoff,
sum(total_layoff) over (order by `month`) rolling_sum
from rolling_sum_cte;

-- Total layoff by each company per year:

select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by company;

-- Ranking each company by total layoff

with company_rank_cte(company, `year`, layoff_count) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
)
select *, dense_rank() 
over(partition by `year` order by layoff_count desc) `rank by total layoff` 
from company_rank_cte;

-- Top 5 companies in terms of layoff by year

with company_rank_cte(company, `year`, layoff_count) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
),
company_year_rank_cte as
(
select *, dense_rank() 
over(partition by `year` order by layoff_count desc) `rank by total layoff` 
from company_rank_cte
)
select * 
from company_year_rank_cte
where `rank by total layoff` <= 5;