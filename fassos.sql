drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'03-01-2021'),
(3,'08-01-2021'),
(4,'15-01-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time timestamp,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'03-01-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'04-01-2021 13:53:03','23.4','40','NaN'),
(5,3,'08-01-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'08-01-2021 21:30:45','25km','25mins',null),
(8,2,'08-01-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'11-01-2021 18:50:20','10km','10minutes',null);


CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date timestamp);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','02-01-2021 23:51:23'),
(3,102,2,'','NaN','02-01-2021 23:51:23'),
(4,103,1,'4','','04-01-2021 13:23:46'),
(4,103,1,'4','','04-01-2021 13:23:46'),
(4,103,2,'4','','04-01-2021 13:23:46'),
(5,104,1,null,'1','08-01-2021 21:00:29'),
(6,101,2,null,null,'08-01-2021 21:03:13'),
(7,105,2,null,'1','08-01-2021 21:20:29'),
(8,102,1,null,null,'09-01-2021 23:54:33'),
(9,103,1,'4','1,5','10-01-2021 11:22:59'),
(10,104,1,null,null,'11-01-2021 18:34:49'),
(10,104,1,'2,6','1,4','11-01-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


--1 how many rolls were ordered?
select count(roll_id) as roll_cnt from customer_orders;

--2 how many unique customer orders were made?
select count(distinct customer_id) as unique_custm_cnt from customer_orders;

--3 how many successful orders were made by each delivery?
select driver_id,count(distinct order_id) as unique_order as orders from 
(select *,
case when cancellation like '%Cancellation%' then 'cancel' 
else 'not cancel' end as cancel_orders
from driver_order)x
where cancel_orders='not cancel'
group by 1;

--4 how many of each type of roll was delivered?
select roll_id,count(roll_id) as roll_cnt from customer_orders where order_id in  
(select order_id from 
(select c.order_id,count(c.roll_id),
case when d.cancellation like '%Cancellation%' then 'cancel' 
else 'not cancel' end as cancel_orders
from customer_orders c
inner join driver_order d
on c.order_id = d.order_id
group by 1,3)x
where cancel_orders ='not cancel')
group by roll_id;

--5 how many veg and non-veg rolls were ordered by each customer?
select roll_name,count(roll_id) as roll_cnt from 
(select c.order_id,r.roll_id,r.roll_name,
case when d.cancellation like '%Cancellation%' then 'cancel' 
else 'not cancel' end as cancel_orders
from customer_orders c
inner join rolls r
on r.roll_id = c.roll_id
inner join driver_order d
on c.order_id = d.order_id)x
where cancel_orders='not cancel'
group by 1;


--6 what was the maximum rolls delivered in a single order?

select order_id,roll_cnt from 
(select c.order_id,count(c.roll_id) as roll_cnt,
case when d.cancellation like '%Cancellation%' then 'cancel' 
else 'not cancel' end as cancel_orders
from customer_orders c
inner join driver_order d
on c.order_id = d.order_id
group by 1,3)x
where cancel_orders='not cancel'
order by 2 desc
limit 1;

--7 for each customer how many delivered rolls had 
--	atleast one change and how many had no changes? 

with temp_customer_table 
(order_id,customer_id,roll_id,not_include_items,
 extra_items_included,order_date) as 
		(select *,
		 case when not_include_items is null or not_include_items =''
		  then '0' else not_include_items end as temp_not_include_items,
		 case when extra_items_included is null or extra_items_included =''
		 or extra_items_included ='NaN'
		  then '0' else extra_items_included end as temp_extra_items_included
		from customer_orders),
--select * from temp_customer_table;
temp_driver_orders as
		(select *,
		case when cancellation like '%Cancellation%' then  0 else 1 
		 end as new_cancellation
		from driver_order)
--select * from temp_driver_orders;
select distinct customer_id,changes_made,count(order_id) as order_cnt from
		(select t1.order_id,t1.customer_id,t1.temp_not_include_items,
		 t1.temp_extra_items_included,t1.roll_id,
		case when t1.temp_not_include_items ='0'
		 and t1.temp_extra_items_included='0' then 'no change'
		else 'change' end as changes_made
		from temp_customer_table t1
		inner join temp_driver_orders t2
		on t1.order_id = t2.order_id
		where t2.new_cancellation=1)x
group by 1,2
order by 2;

--8 how many rolls were delivered that had both exclusions and extras?
with temp_customer_table 
(order_id,customer_id,roll_id,not_include_items,
 extra_items_included,order_date) as 
		(select *,
		 case when not_include_items is null or not_include_items =''
		  then '0' else not_include_items end as temp_not_include_items,
		 case when extra_items_included is null or extra_items_included =''
		 or extra_items_included ='NaN'
		  then '0' else extra_items_included end as temp_extra_items_included
		from customer_orders),
--select * from temp_customer_table;
temp_driver_orders as
		(select *,
		case when cancellation like '%Cancellation%' then  0 else 1 
		 end as new_cancellation
		from driver_order)
--select * from temp_driver_orders;
select changes_made,count(changes_made) as order_cnt from
		(select t1.order_id,t1.customer_id,t1.temp_not_include_items,
		 t1.temp_extra_items_included,t1.roll_id,
		case when t1.temp_not_include_items !='0'
		 and t1.temp_extra_items_included!='0' then 'both_inc_exc'
		else 'only_one_inc_exc' end as changes_made
		from temp_customer_table t1
		inner join temp_driver_orders t2
		on t1.order_id = t2.order_id
		where t2.new_cancellation=1)x
group by 1
order by 1;

--9 what was the total number of rolls ordered each hour of the day?
select hour_range,count(hour_range) from  
(select 
concat(date_part('hour',order_date),'-',
	   date_part('hour',order_date)+1) as hour_range
from customer_orders)x
group by 1
order by 2 desc;

--10 what was the number of orders for each day of the week?
select days,count(distinct order_id) from
	(select  *,to_char(order_date,'day') as days from customer_orders)x
group by 1
order by 1; 

--11 what was the avg time and minutes it took for each driver at the fassos HQ
--		to pickup the order?

select driver_id,ceil(sum(pickup_duration)/count(order_id)) as avg_duration from 
	(select distinct d.driver_id,d.order_id,
	 abs(date_part('min', c.order_date-d.pickup_time)) as pickup_duration  
	from customer_orders c
	inner join driver_order d
	on c.order_id=d.order_id
	where d.pickup_time is not null)x
group by 1
order by 1;
 
 --12 is there any relationship between the number of rolls and how long the order 
 -- takes to prepare?
select order_id,count(roll_id),pickup_duration
--ceil(sum(pickup_duration)/count(roll_id)) as avg_duration 
	from 
	(select c.order_id,c.roll_id,
	 abs(date_part('min', c.order_date-d.pickup_time)) as pickup_duration  
	from customer_orders c
	inner join driver_order d
	on c.order_id=d.order_id
	where d.pickup_time is not null)x
group by 1,3
order by 1;

--13 what was the average distance travelled by each customer?

with cte as (
select distinct c.customer_id, 
replace(d.distance,'km','')::float as dist	
from customer_orders c
	inner join driver_order d
	on c.order_id=d.order_id
	where d.pickup_time is not null 
	order by 1)
select customer_id,avg(dist) as avg_dist from cte
group by 1;

--14 what was the difference between shortest and longest delivery times for all orders?
--select * from driver_order

select (max(duartn::int)-min(duartn::int)) as duartn_diff from
	(select order_id, 
	 split_part(split_part(duration,' ',1),'m',1) as duartn
	from driver_order
	where distance is not null)x;
	
--15 what was the average speed for each driver for each delivery and 
		--	do you notice any trend for these values?

with cte as(
select order_id,driver_id,
round((distance_in_km::decimal)/((time_in_min::int)*60),4) as speed from 
(select order_id,driver_id,
 split_part(split_part(duration,' ',1),'m',1) as time_in_min,
replace(distance,'km','')::float as distance_in_km	
from driver_order
where distance is not null)x)
select driver_id,concat(round(avg(speed),4),' ','km/hr') as avg_speed from cte
group by 1
order by 1;

--16 what is the successful delivery percentage of each driver?
 
with cte as(
select driver_id,count(driver_id) as cnt_driver,
	sum(cancel_order) as total_cancel  from
(select driver_id,order_id,
case when cancellation like '%Cancellation%' then 0 else 1 end as cancel_order
 --row_number() over(order by count(order_id)) as rn
from driver_order
)x
group by 1)
select driver_id,round(total_cancel::decimal/cnt_driver,2) as percentage_per 
from cte
order by 1;
 
 

 



 
 

 
 


 