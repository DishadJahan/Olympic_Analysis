Select * from olympics_history;
Select * from olympic_regions;

==================================================================================================================================
--1. How many olympics games have been held?

SELECT count(distinct games) as No_of_Games
From olympics_history;

==================================================================================================================================
--2. List down all Olympics games held so far.

SELECT distinct year, season, city
from olympics_history
order by year;

==================================================================================================================================
--3. Mention the total no of nations who participated in each olympics game?

SELECT distinct games, count(distinct region) as Total_countries
from olympics_history oh
join olympic_regions rg
on rg.noc = oh.noc
group by games
order by games;

==================================================================================================================================
--4. Which year saw the highest and lowest no of countries participating in olympics?

With t1 as (SELECT oh.games, rg.region as countries
			from olympics_history oh
			join olympic_regions rg
			on rg.noc = oh.noc
			group by oh.games, rg.region),
	 t2 as (select games, count(1) as total_countries
			from t1
			group by games)
select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from t2
      order by 1;
	  
	  
------------------------------------------
-- or another way to get the same result: -------------------------------------------------
------------------------------------------

With t1 as (SELECT distinct oh.games, count(distinct rg.region) as total_countries
			from olympics_history oh
			join olympic_regions rg
			on rg.noc = oh.noc
			group by oh.games
			order by oh.games)
Select 
	concat(First_value(games) over(order by total_countries), ' - ', 
		   First_value(total_countries) over(order by total_countries)) as Lowest_countries,
	concat(First_value(games) over(order by total_countries desc), ' - ', 
		   First_value(total_countries) over(order by total_countries desc)) as Highest_countries 
from t1
limit 1;

==================================================================================================================================
--5. Which nation has participated in all of the olympic games?

with t1 as (Select count(distinct games) as total_games
			from olympics_history),
	 t2 as (SELECT games, rg.region as country
			from olympics_history oh
			join olympic_regions rg
			on rg.noc = oh.noc
			group by games, rg.region
		    order by games),
	 t3 as (select country, count(1) as total_participated_games
		    from t2
		    group by country)
Select t3.* 
from t3
join t1 on t1.total_games = t3.total_participated_games
order by 1;


==================================================================================================================================
--6. Identify the sport which was played in all summer olympics.

With t1 as (select count(distinct games) as total_summer_games
			from olympics_history
			where season = 'Summer'),
	 t2 as (Select distinct sport, games
			from olympics_history
			where season = 'Summer'
			order by games),
	 t3 as (select sport, count(games) as no_of_games
		    from t2
		    group by sport)
Select *
from t3
join t1
on t1.total_summer_games = t3.no_of_games;


==================================================================================================================================
--7. Which Sports were just played only once in the olympics?


with t1 as (select distinct games, sport
			from olympics_history),
	 t2 as (select sport, count(1) as no_of_games
			from t1
			group by sport)
select t2.*, t1.games
from t2
join t1
on t1.sport = t2.sport
where t2.no_of_games = 1
order by t1.games;


==================================================================================================================================
--8. Fetch the total no of sports played in each olympic games.

select distinct games, count(distinct sport) as no_of_sports
from olympics_history
group by games
order by 2 desc;


==================================================================================================================================
--9. Fetch oldest athletes to win a gold medal.

With t1 as (Select name, sex, 
			(case when age ='NA' Then '0' else age end) as Age,
			team, games, city, sport, event, medal
			from olympics_history
			where medal = 'Gold'),
	 t2 as (Select *,
			rank() over(order by age desc) as rnk
			from t1)
Select *
from t2
where rnk = 1;

==================================================================================================================================
--10. Find the Ratio of male and female athletes participated in all olympic games.

with t1 as (SELECT sex, count(1) as male_count
			from olympics_history
			where sex = 'M'
			group by sex),
	 t2 as (SELECT sex, count(1) as female_count
			from olympics_history
			where sex = 'F'
			group by sex)
Select concat('1 : ', round(t1.male_count::decimal/t2.female_count, 2)) as ratio
from t1, t2;

------------------------------------------
-- or another way to get the same result: -------------------------------------------------
------------------------------------------

with t1 as (select sex, count(1) as cnt
        	from olympics_history
        	group by sex),
     t2 as (select *, row_number() over(order by cnt) as rn
        	 from t1),
     min_cnt as (select cnt 
				 from t2 
				 where rn = 1),
     max_cnt as (select cnt 
				 from t2 
				 where rn = 2)
select concat('1 : ', round(max_cnt.cnt::decimal/min_cnt.cnt, 2)) as ratio
from min_cnt, max_cnt;

==================================================================================================================================
--11. Write SQL query to fetch the top 5 athletes who have won the most gold medals.

With t1 as (Select distinct name, team, count(medal) as no_of_medals
			from olympics_history
			where medal = 'Gold'
			group by name, team
			order by no_of_medals desc),
	 t2 as (Select *,
			dense_rank() over(order by no_of_medals desc) as rank
			from t1)
select name, team, no_of_medals
from t2
where rank <= 5;

==================================================================================================================================
--12. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

select rg.region as country, count(medal) as total_medals_won
from olympics_history oh
join olympic_regions rg
on rg.noc = oh.noc
where medal <> 'NA'
group by country
order by 2 desc
limit 5;

------------------------------------------
-- or another way to get the same result: -------------------------------------------------
------------------------------------------

with t1 as (select rg.region as country, count(medal) as total_medals_won
			from olympics_history oh
			join olympic_regions rg
			on rg.noc = oh.noc
			where medal <> 'NA'
			group by country),
	 t2 as (Select *,
		    dense_rank() over(order by total_medals_won desc) as rnk
		    from t1)
Select *
from t2
where rnk <= 5;

==================================================================================================================================
--13. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

With t1 as (Select name, count(medal) as total_medals_won 
			from olympics_history
			where medal <> 'NA'
			group by name),
	 t2 as (Select *,
		    dense_rank() over(order by total_medals_won desc) as rnk
		    from t1)
Select *
from t2
where rnk <= 5;


==================================================================================================================================
--14. Write a SQL query to list down the  total gold, silver and bronze medals won by each country.

Create EXTENSION tablefunc;

Select nr.region as country, oh.medal, count(1) as total_medals 
from olympics_history oh
join olympic_regions nr
on oh.noc = nr.noc
Where medal <> 'NA'
group by nr.region, oh.medal
order by nr.region, oh.medal;

Select country,
	COALESCE (gold, 0) as Gold,
	COALESCE (silver, 0) as Silver,
	COALESCE (bronze, 0) as Bronze
from crosstab('Select nr.region as country, oh.medal, count(1) as total_medals 
			  from olympics_history oh
			  join olympic_regions nr
			  on oh.noc = nr.noc
			  Where medal <> ''NA''
			  group by nr.region, oh.medal
			  order by nr.region, oh.medal',
			  'values (''Bronze''), (''Gold''), (''Silver'')')
	 as result (country varchar, bronze bigint, gold bigint, silver bigint)
Order by gold desc, silver desc, bronze desc;

==================================================================================================================================
--15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

Select substring(games_country, 1, position(' - ' in games_country) - 1) as games,
	   substring(games_country, position(' - ' in games_country) + 3) as country,
	   COALESCE (gold, 0) as Gold,
	   COALESCE (silver, 0) as Silver,
	   COALESCE (bronze, 0) as Bronze
from crosstab('Select concat(games, '' - '', nr.region) as games_country, oh.medal, count(1) as total_medals 
			  from olympics_history oh
			  join olympic_regions nr
			  on oh.noc = nr.noc
			  Where medal <> ''NA''
			  group by games_country, nr.region, oh.medal
			  order by games_country, nr.region, oh.medal',
			  'values (''Bronze''), (''Gold''), (''Silver'')')
			as result (games_country varchar, bronze bigint, gold bigint, silver bigint)
Order by games_country;


==================================================================================================================================
--16. Write SQL query to display for each Olympic Games, which country won the highest gold, silver and bronze medals.

With temp as (
			Select substring(games_country, 1, position(' - ' in games_country) - 1) as games,
				   substring(games_country, position(' - ' in games_country) + 3) as country,
				   COALESCE (gold, 0) as Gold,
				   COALESCE (silver, 0) as Silver,
				   COALESCE (bronze, 0) as Bronze
			from crosstab('Select concat(games, '' - '', nr.region) as games_country, oh.medal, count(1) as total_medals 
						  from olympics_history oh
						  join olympic_regions nr
						  on oh.noc = nr.noc
						  Where medal <> ''NA''
						  group by games_country, nr.region, oh.medal
						  order by games_country, nr.region, oh.medal',
						  'values (''Bronze''), (''Gold''), (''Silver'')')
				 as result (games_country varchar, bronze bigint, gold bigint, silver bigint)
			Order by games_country)
select distinct games,
		concat(first_value(country) over(partition by games order by gold desc), ' - ', 
			   first_value(gold) over(partition by games order by gold desc)),
		concat(first_value(country) over(partition by games order by silver desc), ' - ', 
			   first_value(silver) over(partition by games order by silver desc)),
		concat(first_value(country) over(partition by games order by bronze desc), ' - ', 
			   first_value(bronze) over(partition by games order by bronze desc))
from temp
order by games;


==================================================================================================================================
--17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.


With t1 as (Select substring(games_country, 1, position(' - ' in games_country) - 1) as games,
				   substring(games_country, position(' - ' in games_country) + 3) as country,
				   COALESCE (gold, 0) as Gold,
				   COALESCE (silver, 0) as Silver,
				   COALESCE (bronze, 0) as Bronze
			from crosstab('Select concat(games, '' - '', nr.region) as games_country, 
						  		  oh.medal, 
						  		  count(1) as total_medals 
						  from olympics_history oh
						  join olympic_regions nr
						  	on oh.noc = nr.noc
						  Where medal <> ''NA''
						  group by games_country, nr.region, oh.medal
						  order by games_country, nr.region, oh.medal',
						  'values (''Bronze''), (''Gold''), (''Silver'')')
				 as result (games_country varchar, bronze bigint, gold bigint, silver bigint)),
		t2 as (select oh.games, rg.region as country, count(1) as total_medals
			   from olympics_history oh
			   join olympic_regions rg
			   on oh.noc = rg.noc
			   Where medal <> 'NA'
			   group by oh.games, rg.region
			   order by 1, 2)
select distinct t1.games,
		concat(first_value(t1.country) over(partition by t1.games order by t1.gold desc), ' - ', 
			   first_value(t1.gold) over(partition by t1.games order by t1.gold desc)) as max_gold,
		concat(first_value(t1.country) over(partition by t1.games order by t1.silver desc), ' - ', 
			   first_value(t1.silver) over(partition by t1.games order by t1.silver desc)) as max_silver,
		concat(first_value(t1.country) over(partition by t1.games order by t1.bronze desc), ' - ', 
			   first_value(t1.bronze) over(partition by t1.games order by t1.bronze desc)) as max_bronze,
	    concat(first_value(t2.country) over(partition by t2.games order by t2.total_medals desc nulls last), ' - ', 
			   first_value(t2.total_medals) over(partition by t2.games order by t2.total_medals desc nulls last)) as max_medals
from t1
join t2 
	on t1.games = t2.games
	and t1.country = t2.country
order by games;


==================================================================================================================================
--18. Which countries have never won gold medal but have won silver/bronze medals?

Select * from 
	(select country,
			COALESCE (gold, 0) as Gold,
			COALESCE (silver, 0) as Silver,
			COALESCE (bronze, 0) as Bronze
from crosstab('Select nr.region as country, oh.medal, count(1) as total_medals 
			  from olympics_history oh
			  join olympic_regions nr
			  	on oh.noc = nr.noc
			  Where medal <> ''NA''
			  group by nr.region, oh.medal
			  order by nr.region, oh.medal',
			  'values (''Bronze''), (''Gold''), (''Silver'')')
			as result (country varchar, bronze bigint, gold bigint, silver bigint)) x
where gold = 0 and (silver > 0 or bronze > 0)
Order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;

==================================================================================================================================
--19. In which Sport/event, India has won highest medals.

With t1 as (select nr.region as country, oh.sport, oh.medal
			from olympics_history oh
			join olympic_regions nr
			on oh.noc = nr.noc),
     t2 as (select * 
			from t1
			where country = 'India' 
			and medal <> 'NA')
Select sport, count(1) as total_medals_won 
from t2
group by sport
order by total_medals_won desc
limit 1;

==================================================================================================================================
--20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games.

With t1 as (select oh.games, nr.region as country, oh.sport, oh.medal
			from olympics_history oh
			join olympic_regions nr
			on oh.noc = nr.noc),
     t2 as (select * 
			from t1
			where country = 'India' 
			and medal <> 'NA')
Select country, sport, games, count(2) as total_medals_won 
from t2
group by country, sport, games
order by total_medals_won desc;

==================================================================================================================================














































