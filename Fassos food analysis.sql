create database fasoos;
use fasoos;

drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date varchar(50)); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES 
(1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');

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
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time varchar(50),distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date varchar(50));
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values 
(1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');
drop table customer_orders;
select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

-- 1. Row and metrics 
-- 2. driver and customer_exprience 
-- 3. infridents and optimization
-- 4. pricing and ratings 

-- Q1 how many  rolls  were  ordered 
select count(roll_id)as total_rolls_orderd from customer_orders;

-- Q2 their  are two types  of rolls how much rows  each orderd 
select
	t2.roll_name,
	count(t1.roll_id) as total_roll_orderd 
from 
	customer_orders t1
join 
	rolls t2
on 
	t1.roll_id = t2.roll_id 
group by 
	t2.roll_name;

-- Q3 how many unique customers where made 
select 
	count(distinct(customer_id)) as unique_customers
from 
	customer_orders;

-- Q4 how many successfull orders where  ordered by  each driver 
select 
	driver_id ,
    count(cancellation) as successfull_orders
from 
	driver_order
where 
	cancellation not in('Cancellation','Customer Cancellation')
group by 
	driver_id ;

-- Q5 how many each type of rolls where delivered 
select roll_id , count(roll_id)from customer_orders where order_id in(select order_id from 
		(select *,
		case
		when cancellation in('Cancellation','Customer_Cancellation') then 'c' else 'nc'end as order_cancel_details from driver_order) t
where order_cancel_details = 'nc')
group by roll_id;


-- Q6 how many veg and  nonveg  rolls  by each of the customers 
select 
	customer_id,
    count(roll_id) as total_ordered,
    case 
		when roll_id  = 1 then 'nonveg' else 'veg' end as order_details 
from customer_orders 
group by customer_id , order_details 
order by customer_id ;




-- Q7 for each customer ,how many delivered rolls had at least 1 change and how many had  no  changes ?

with temp_customers_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
select order_id, customer_id , roll_id,
case when  not_include_items is null or not_include_items  = ''then 0 else not_include_items end as new_not_include_items,
case when  extra_items_included is null or extra_items_included  = '' or extra_items_included = 'NaN' then 0 else extra_items_included end as extra_items_included,
order_date from customer_orders
),
 temp_driver_orders(order_id,driver_id,pickup_time,distance,duration,cancellation ) as 
(
select order_id ,driver_id,pickup_time , distance , duration,
case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order
)
select customer_id , chg_no_chg  , count(order_id) at_least_1change from (
select *  , case when not_include_items = '0' and extra_items_included = '0' then 'no change' else 'change' end as chg_no_chg  from temp_customers_orders where order_id in(
select order_id  from temp_driver_orders where cancellation!= 0))a
group by customer_id , chg_no_chg
order by customer_id asc ;


-- Q8 how many rolls where delivered that had both exculsions and  extras 

with temp_customers_orders(order_id,customer_id,roll_id,new_not_include_items,new_extra_items_included,order_date) as 
(
select  order_id , customer_id , roll_id,
case 
	when not_include_items is null or  not_include_items = '' then 0 else  not_include_items end as new_not_include_items,
case 
	when extra_items_included is null or extra_items_included  = '' or extra_items_included  = 'NaN' then 0 else extra_items_included  end  as new_extra_items_included ,
order_date from customer_orders
),
temp_driver_orders(order_id,driver_id,pickup_time,distance,duration,cancellation) as 
(
select order_id , driver_id, pickup_time , distance , duration ,
case 
	when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation 
from driver_order
)
select changes_in_order , count(changes_in_order) as both_included_and_excluded from
(select * ,
case 
	when new_not_include_items != 0 and new_extra_items_included != 0 then 'both include and exclude' else 'either 1 include or exclude' end as changes_in_order 
from temp_customers_orders where order_id in (
select order_id from temp_driver_orders where cancellation != 0))a
group by changes_in_order;


-- First, ensure the column type is VARCHAR
ALTER TABLE customer_orders MODIFY COLUMN order_date VARCHAR(20);

-- Convert the VARCHAR order_date to DATETIME
ALTER TABLE customer_orders ADD COLUMN order_date_converted DATETIME;

SET SQL_SAFE_UPDATES = 0;

UPDATE customer_orders
SET order_date_converted = STR_TO_DATE(order_date, '%m-%d-%Y %H:%i:%s');

-- Optionally, drop the old column and rename the new column
ALTER TABLE customer_orders DROP COLUMN order_date;
ALTER TABLE customer_orders CHANGE order_date_converted order_date DATETIME;

select * from customer_orders ;

-- Q9 what was the  number of orders for each hour of  the  day 
select
	hours_range , count(hours_range) as order_count
from (
SELECT 
    *,
    CONCAT(
        CAST(hour(order_date) AS CHAR),
        '-',
        CAST(hour(DATE_ADD(order_date, INTERVAL 1 HOUR)) AS CHAR)
    ) AS hours_range
FROM 
    customer_orders) a
group by hours_range;

-- Q10 what  was the number of  orders for each day of the weak 

select 
	distinct(dayname(order_date)) as day_name , 
	count(distinct(order_id)) as  orders_count_per_Day
from 
(
select * ,
	day(order_date) as per_day_order from customer_orders
) a
group by 
	day_name
order by 
	orders_count_per_Day asc;


-- 2. DRIVER AND CUSTOMER EXPERIANCE 

-- Q1 what was the average time in minutes if took for each driver to arrive at the fassos HQ to pickup the order
drop table driver_order;
ALTER TABLE driver_order MODIFY COLUMN pickup_time VARCHAR(20);

-- Convert the VARCHAR order_date to DATETIME
ALTER TABLE driver_order ADD COLUMN pickup_time_converted DATETIME;

UPDATE driver_order
SET pickup_time_converted = STR_TO_DATE(pickup_time, '%m-%d-%Y %H:%i:%s');

-- Optionally, drop the old column and rename the new column
ALTER TABLE driver_order DROP COLUMN pickup_time;
ALTER TABLE driver_order CHANGE pickup_time_converted pickup_time DATETIME;
select * from driver_order;



-- Q1 what was the average time in minutes if took for each driver to arrive at the fassos HQ to pickup the order

WITH temp_customer_order as 
(
SELECT 
	order_id,
	customer_id,
    order_date,
MINUTE
	(order_date) as order_time
FROM
	customer_orders
),
temp_driver_order as
(
SELECT
	order_id ,
    driver_id ,
    pickup_time,
MINUTE
	(pickup_time) as reaching_time
FROM
	driver_order 
WHERE  
	pickup_time is not null
)
SELECT 
	driver_id , 
	sum(timediff) / count(order_id)  AS AVGTIME
FROM
(
SELECT * FROM 
(
SELECT *,
	row_number() over(partition by order_id order by timediff) as rnk from 
(
SELECT
	t2.driver_id ,
	t1.order_id ,
    abs(timestampdiff(minute , t2.pickup_time , t1.order_date)) as timediff
FROM
	temp_customer_order t1
JOIN
	temp_driver_order t2
ON
	t1.order_id = t2.order_id)a)t
WHERE  rnk = 1)c
GROUP BY 
	driver_id;


-- Q2 is there any realationship between the number of rolls and how long the order takes time to prepare ?? 
select 
	roll_name,
    count(roll_name ) as total_roll_ordered  , 
    sum(timedifference) as time_taken_to_prepare_in_min,
    round(sum(timedifference) / count(roll_name ),2) as per_order_time
from
(
select 
	t1.order_id , t1.customer_id , 
    t1.roll_id , t1.order_date , 
    t2.pickup_time , t3.roll_name,
	abs(timestampdiff(minute , t2.pickup_time , t1.order_date)) as timedifference
from 
	customer_orders t1
join 
	driver_order  t2
on 
	t1.order_id = t2.order_id
join 
	rolls t3
on 
	t1.roll_id = t3.roll_id
where
	t2.pickup_time is not null)a
group by
	roll_name;


-- Q3 what was  the average distance travelled for each of the customer ? 

select 
	t2.customer_id ,
    round(avg(t1.distance),2) avg_distance_travel 
from
	driver_order t1
join 
	customer_orders t2
on 
	t1.order_id = t2.order_id
where 
	t1.pickup_time is not null
group by 
	t2.customer_id ;
 
-- Q4 what was the difference between the longest and the shortest delivery times for all orders

select
max(new_duration) - min(new_duration) time_diff_btw_long_short_order 
from
(
select *,
case 
	when duration like '%min%' then left(duration , locate('m',duration)-1) else duration end as new_duration
from 
	driver_order
where 
	duration is not null
)a;

-- Q5 what was the average speed for each driver for each delivery?  
select 
	t2.driver_id ,
	t1.order_id ,
	timestampdiff(minute, t1.order_date , t2.pickup_time) as time_in_min, 
    
case 
	when 
		distance like '%km' 
	then 
		left(distance , locate('km',distance)-1) 
	else 
		distance 
end as
	new_distance,
	
	round((t2.distance / timestampdiff(minute, t1.order_date , t2.pickup_time)),3) as speed
from 
	customer_orders t1
join 
	driver_order t2
on 
	t1.order_id = t2.order_id 
where 
	t2.pickup_time is not null  
order by

	t2.driver_id  ;



























