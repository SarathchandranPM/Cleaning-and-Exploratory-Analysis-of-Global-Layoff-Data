-- DATA CLEANING PROJECT --

select * from layoffs;

-- 1) Create a staging table, a temporary table to perform data cleaning operations --

create table layoffs_staging
like layoffs;

insert layoffs_staging
select * from layoffs;

select * from layoffs_staging;

-- 2) Removing Duplicate --

select * from layoffs_staging;

with duplicate_cte as
(
select *, row_number()
over
(partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_num
from layoffs_staging
)
select * from duplicate_cte
where row_num > 1;

-- with duplicate_cte as
-- (
-- select *, row_number()
-- over
-- (partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_num
-- from layoffs_staging
-- )
-- delete from duplicate_cte
-- where row_num > 1;

-- We have identified the duplicate rows. We can't delete data from the table returned by a CTE as that table is not updatable. 
-- So, let's create another table and store all data in layoffs_staging along with row_num:
-- Right click on layoffs_staging --> copy to clipboard --> create statement:

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from layoffs_staging2;

-- Insert same data as layoffs_staging, along with row_num:

insert layoffs_staging2
select *, row_number()
over
(partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_num
from layoffs_staging;

select * from layoffs_staging2 where row_num > 1;

-- Delete all rows where row_num > 1:

delete from layoffs_staging2 where row_num > 1;

-- 3) Standardizing Data --

-- Removing whitespaces from company field values:

update layoffs_staging2
set company = trim(company);

-- Fixing name inconsitency in industry field values (For example, "Crypto", "Crypto Currency" and "CryptoCurrency" are essentially the same. We don't need three different values for the same industry. We are going to use "Crypto" as the standard name for industry):

select distinct industry from layoffs_staging2 order by 1;
select distinct industry from layoffs_staging2 where industry like "Crypto%"; 

update layoffs_staging2
set industry = "Crypto"
where industry like "Crypto%";

-- Fixing name inconsitency in country field values

select distinct country from layoffs_staging2 order by 1;
select distinct country from layoffs_staging2
where country like "United States%";

update layoffs_staging2
set country = "United States"
where country like "United States%";

-- OR

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like "United States%";

-- Changing the format of date field values from text to date

update layoffs_staging2
set `date`= str_to_date(`date`, '%m/%d/%Y');

alter table layoffs_staging2
modify column `date` date;

-- Dealing with blank values in industry field:

select distinct industry from layoffs_staging2 order by 1;

select * from layoffs_staging2
where industry is null or industry = '';

-- select * from layoffs_staging2
-- where company like 'Bally%';

select * 
from layoffs_staging2 t1 join layoffs_staging2 t2
on t1.company = t2.company
where t1.industry = '' and length(t2.industry <> 0);

update layoffs_staging2 t1 join layoffs_staging2 t2
on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry = '' and length(t2.industry <> 0);

-- The above operation won't work, because we can't populate blank cells. 
-- We first need to convert black values to null and then we can populate. Just like in Power BI:

update layoffs_staging2
set industry = null
where industry = '';

update layoffs_staging2 t1 join layoffs_staging2 t2
on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null and t2.industry is not null;

-- test if it worked or not:

select * from layoffs_staging2 where company = 'airbnb';
-- You can see the the aibnb entry whose industry field value was blank before has populated with the Travel, which is the industry field value on the next airbnb entry
-- We still have a company whose industry is null. 
select * from layoffs_staging2 where company like 'Bally%';
-- Since there's only one entry for this company we have no other entry to refer the industry. So, we leave it that way.

-- Removing rows where both total_laid_off and percentage_laid_off are null
-- Why? Since both fields are null we don't get any insight about the layoffs in those companies.

select * 
from layoffs_staging2
where 
total_laid_off is null
and 
percentage_laid_off is null;

delete
from layoffs_staging2
where 
total_laid_off is null
and 
percentage_laid_off is null;

-- Removing the row_num column:

alter table layoffs_staging2 
drop column row_num;

select * from layoffs_staging2;