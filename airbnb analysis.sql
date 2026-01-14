-- =========================================================
-- 1. Pricing and Revenue Insights
-- =========================================================

-- What is the average price across all listings?
SELECT
	ROUND(AVG(price),2) AS "Average Price"
FROM airbnb_listings

-- What is the average price per neighbourhood group?
SELECT 
neighbourhood_group,
ROUND(AVG(price),2) AS "Average Price"
FROM airbnb_listings
GROUP BY neighbourhood_group
ORDER BY "Average Price" DESC

-- Which room type generates the highest average price?
SELECT
room_type AS "Room Type",
ROUND(AVG(price), 2) AS "Average Price"
FROM airbnb_listings
GROUP BY room_type
ORDER BY "Average Price" DESC LIMIT 1

SELECT
room_type,
average_price AS highest_average_price
FROM
(SELECT
room_type,
ROUND(AVG(price), 2) AS average_price,
ROW_NUMBER() OVER(ORDER BY AVG(price) DESC) AS rnk
FROM airbnb_listings
GROUP BY room_type) t
WHERE rnk = 1

-- Which neighbourhood has the highest average revenue potential (price * reviews_per_month)?
SELECT
neighbourhood,
ROUND(AVG((price * reviews_per_month)::numeric), 2) AS "Average Revenue"
FROM airbnb_listings
GROUP BY neighbourhood
ORDER BY "Average Revenue" DESC LIMIT 1


-- =========================================================
-- 2. Host Analysis
-- =========================================================

-- Which hosts have the most listings on the platform?
SELECT 
host_name AS "Host Name",
SUM(calculated_host_listings_count) AS "Total Listings"
FROM airbnb_listings
GROUP BY "Host Name"
ORDER BY "Total Listings" DESC LIMIT 5

-- What is the average price and availability for “Superhosts” vs “Individual” vs “Business” types?
SELECT 
host_type AS "Host Type",
ROUND(AVG(price), 2) AS "Average Price",
ROUND(AVG(availability_365)) AS "Average Availability"
FROM airbnb_listings
GROUP BY "Host Type"
ORDER BY "Average Price" DESC ,"Average Availability" DESC

-- How many hosts have more than 10 active listings?
SELECT
COUNT(host_id) AS "Total Hosts"
FROM airbnb_listings
WHERE calculated_host_listings_count >= 10


-- What is the average review score (reviews_per_month) for each host type?
SELECT
Host_type AS "Host Type",
ROUND(AVG(reviews_per_month)::numeric,2) AS "Review Score"
FROM airbnb_listings
GROUP BY "Host Type"
ORDER BY "Review Score" DESC

-- Identify hosts with outlier prices compared to their neighborhood average.
SELECT
a.host_name,
a.neighbourhood,
a.price,
ROUND(b.avg_price,2) AS neighbourhood_avg
FROM airbnb_listings as a
JOIN (
	SELECT
	neighbourhood,
	AVG(price) AS avg_price
	FROM airbnb_listings
	GROUP BY neighbourhood
) AS b
ON a.neighbourhood = b.neighbourhood
WHERE a.price > b.avg_price
ORDER BY a.price DESC





-- =========================================================
-- 3. Location & Demand Patterns
-- =========================================================

-- Which neighbourhood group has the highest number of listings?

SELECT
neighbourhood_group,
COUNT(*) AS total_listings
FROM airbnb_listings
GROUP BY neighbourhood_group
ORDER BY total_listings DESC
LIMIT 1

SELECT
	neighbourhood_group,
	total_listings AS highest_number_of_listings
FROM 
(
	SELECT
	neighbourhood_group,
	COUNT(*) AS total_listings,
	ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) as rnk
	FROM airbnb_listings
	GROUP BY neighbourhood_group
) t
WHERE rnk = 1


-- Find top 10 neighborhoods by review count (popularity proxy).
SELECT
neighbourhood,
SUM(number_of_reviews) AS review_count
FROM airbnb_listings
GROUP BY neighbourhood
ORDER BY review_count DESC
LIMIT 10


SELECT
neighbourhood,
review_count
FROM (
	SELECT
	neighbourhood,
	SUM(number_of_reviews) AS review_count,
	ROW_NUMBER() OVER(ORDER BY SUM(number_of_reviews) DESC) AS rnk
	FROM airbnb_listings
	GROUP BY neighbourhood
) t
WHERE rnk BETWEEN 1 AND 10

-- Which neighbourhoods have the lowest availability but highest prices — i.e., high-demand zones?
SELECT
neighbourhood,
ROUND(AVG(availability_365),2) AS availability,
ROUND(AVG(price::numeric),2) AS price
FROM airbnb_listings
GROUP BY neighbourhood
ORDER BY availability ASC , price DESC
LIMIT 10

-- =========================================================
-- 4. Time & Trend Analysis
-- =========================================================

-- What is the average monthly price trend based on review_month?
SELECT
review_month,
ROUND(AVG(price), 2) AS avg_monthly_price
FROM airbnb_listings
GROUP BY review_month
ORDER BY review_month


-- How does availability change month-to-month?
SELECT
review_month,
ROUND(AVG(availability_365), 2) AS avg_monthly_availability,
ROUND( AVG(availability_365) - LAG(AVG(availability_365)) OVER (ORDER BY review_month), 2) AS month_over_month_change
FROM airbnb_listings
GROUP BY review_month
ORDER BY review_month;

-- What is the distribution of listings by review year (activity timeline)?
SELECT
review_year,
COUNT(*) AS total_listings
FROM airbnb_listings
WHERE review_year IS NOT NULL
GROUP BY review_year
ORDER BY review_year

-- Which year saw the maximum reviews per listing?
SELECT
review_year,
ROUND(1.0 * SUM(number_of_reviews) / COUNT(DISTINCT id), 2) AS avg_reviews_per_listing
FROM airbnb_listings
WHERE review_year IS NOT NULL
GROUP BY review_year
ORDER BY avg_reviews_per_listing DESC
LIMIT 1;

-- Find the average days available per price category.
SELECT
price_category,
ROUND(AVG(availability_365), 2) AS avg_days_available
FROM airbnb_listings
WHERE price IS NOT NULL
GROUP BY price_category
ORDER BY price_category



-- =========================================================
-- 5. Customer Behavior
-- =========================================================

-- Which room types receive most customer engagement (reviews_per_month)?
SELECT
room_type,
ROUND(AVG(reviews_per_month::numeric), 2) AS avg_reviews_per_month
FROM airbnb_listings
WHERE reviews_per_month IS NOT NULL
GROUP BY room_type
ORDER BY avg_reviews_per_month DESC;

-- What’s the average review frequency per neighborhood group?
SELECT
neighbourhood_group,
ROUND(AVG(reviews_per_month::numeric), 2) AS avg_review_frequency
FROM airbnb_listings
WHERE reviews_per_month IS NOT NULL
GROUP BY neighbourhood_group
ORDER BY avg_review_frequency DESC;

-- Identify listings with consistent reviews but below-average prices (hidden gems).
WITH stats AS (
    SELECT
    AVG(price) AS avg_price,
    AVG(reviews_per_month) AS avg_reviews
    FROM airbnb_listings
    WHERE price IS NOT NULL AND reviews_per_month IS NOT NULL
)
SELECT
    id,
    name,
    neighbourhood_group,
    room_type,
    price,
    reviews_per_month,
    number_of_reviews,
    availability_365
FROM airbnb_listings, stats
WHERE 
    price < stats.avg_price                
    AND reviews_per_month >= stats.avg_reviews  
ORDER BY reviews_per_month DESC, price ASC
LIMIT 20;

