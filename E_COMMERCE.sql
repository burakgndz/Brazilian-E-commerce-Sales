SELECT 
CUS.*,
ORD.order_id,
ORD.order_status,
ORD.order_purchase_timestamp,
ORD.order_approved_at,
ORD.order_delivered_carrier_date,
ORD.order_delivered_customer_date,
ORD.order_estimated_delivery_date,
OPS.payment_type,
OPS.payment_value,
OPS.payment_sequential,
OPS.payment_installments,
OIS.order_item_id,
OIS.product_id,
OIS.freight_value,
OIS.price,
OIS.shipping_limit_date,
PRD.product_category_name,
PCT.product_category_name_eng,
PRD.product_length_cm,
PRD.product_width_cm,
PRD.product_height_cm,
PRD.product_weight_g,
ORS.review_id,
ORS.review_score,
SEL.seller_id,SEL.seller_city,SEL.seller_state
INTO #TORDERS
FROM olist_customers_dataset CUS
INNER JOIN olist_orders_dataset ORD ON ORD.customer_id = CUS.customer_id
INNER JOIN olist_order_payments_dataset OPS ON ORD.order_id = OPS.order_id
INNER JOIN olist_order_items_dataset OIS ON ORD.order_id = OIS.order_id
INNER JOIN olist_order_reviews_dataset ORS ON ORD.order_id = ORS.order_id
INNER JOIN olist_products_dataset PRD ON OIS.product_id = PRD.product_id
INNER JOIN olist_sellers_dataset SEL ON OIS.seller_id = SEL.seller_id
INNER JOIN product_category_name_translation PCT ON PRD.product_category_name = PCT.product_category_name
-- CREATED A TEMP TABLE FOR E-COMMERCE DATASET

-- DELETE NULL VALUES FROM TABLE
DELETE FROM #TORDERS WHERE order_approved_at IS NULL
OR order_delivered_carrier_date IS NULL OR  order_delivered_customer_date IS NULL
OR product_weight_g IS NULL OR  product_length_cm IS NULL OR product_height_cm IS NULL OR product_width_cm IS NULL

-- ADD A NEW COLUMN FOR PRODUCT CATEGORIES AND USING 'CASE' CATEGORIZE NAMES
ALTER TABLE #TORDERS ADD product_category varchar(50)
UPDATE #TORDERS
SET product_category = 
CASE 
WHEN product_category_name_eng IN ('office_furniture', 'furniture_decor', 'furniture_living_room', 'kitchen_dining_laundry_garden_furniture', 'bed_bath_table',  'furniture_bedroom', 'furniture_mattress_and_upholstery') Then 'Furniture'
WHEN product_category_name_eng IN ('auto', 'computers_accessories', 'musical_instruments', 'consoles_games', 'watches_gifts', 'air_conditioning', 'telephony', 'electronics', 'fixed_telephony', 'tablets_printing_image', 'computers', 'small_appliances_home_oven_and_coffee', 'small_appliances', 'audio', 'signaling_and_security', 'security_and_services') then 'Electronics'
WHEN product_category_name_eng IN ('fashio_female_clothing', 'fashion_male_clothing', 'fashion_bags_accessories', 'fashion_shoes', 'fashion_sport', 'fashion_underwear_beach', 'fashion_childrens_clothes',  'cool_stuff') then 'Fashion'
WHEN product_category_name_eng IN ('home_comfort','home_confort', 'home_comfort_2', 'home_construction', 'garden_tools','housewares',  'home_appliances', 'home_appliances_2', 'flowers', 'costruction_tools_garden', 'construction_tools_lights', 'costruction_tools_tools', 'luggage_accessories', 'la_cuisine') then 'Home & Garden'
WHEN product_category_name_eng IN ('pet_shop','sports_leisure', 'toys', 'cds_dvds_musicals', 'music', 'dvds_blu_ray', 'cine_photo', 'party_supplies', 'christmas_supplies', 'arts_and_craftmanship', 'art') then 'Entertainment'
WHEN product_category_name_eng IN ('health_beauty', 'perfumery', 'diapers_and_hygiene','baby') then 'Beauty & Health'
WHEN product_category_name_eng IN ( 'market_place','food_drink', 'drinks', 'food') then 'Food & Drinks'
WHEN product_category_name_eng IN ('books_general_interest', 'books_technical', 'books_imported', 'stationery') then 'Books & Stationery'
WHEN product_category_name_eng IN ('construction_tools_construction', 'construction_tools_safety', 'industry_commerce_and_business', 'agro_industry_and_commerce') then 'Industry & Construction'
ELSE product_category 
END

-- DROP SOME COLUMNS THAT ARE NOT USEFULL
ALTER TABLE #TORDERS 
DROP COLUMN product_category_name, product_category_name_eng,product_length_cm,product_width_cm,product_height_cm,product_weight_g
-- ADD A NEW FEATURE  'SELLER LOCATION' AND 'CUSTOMER LOCATION'
ALTER TABLE #TORDERS ADD seller_location varchar(50)
UPDATE #TORDERS SET seller_location = seller_city+', ' +seller_state 
ALTER TABLE #TORDERS ADD customer_location varchar(50)
UPDATE #TORDERS SET customer_location = customer_city+', ' +customer_state 
ALTER TABLE #TORDERS DROP COLUMN customer_zip_code_prefix,seller_city, seller_state, customer_city, customer_state

-- ADD NEW FEATURES SUCH AS ARRIVAL DAYS, ESTIMATED DELIVERY DAYS, SHIPPING DAYS, PROCESSING DAYS, ARRIVAL STATUS AND SELLER TO CARRIER STATUS
ALTER TABLE #TORDERS ADD estimated_delivery_days int, arrival_days int, 
shipping_days int, processing_days int, arrival_status varchar(50),
seller_to_carrier_status varchar(50)

-- UPDATE THESE NEW FEATURES ACCORDING TO DATA
UPDATE #TORDERS
SET arrival_days = Cast(DATEDIFF(HOUR,order_purchase_timestamp,order_delivered_customer_date)/24.0 as decimal(10,0)),
estimated_delivery_days = Cast( DATEDIFF(HOUR,order_purchase_timestamp,order_estimated_delivery_date)/24.0 as decimal(10,0)) ,
shipping_days = Cast( DATEDIFF(HOUR,order_delivered_carrier_date,order_delivered_customer_date)/24.0 as decimal(10,0)),
processing_days =  Cast( DATEDIFF(HOUR,order_purchase_timestamp,order_delivered_carrier_date)/24.0 as decimal(10,0)),
seller_to_carrier_status = CASE 
WHEN shipping_limit_date >= order_delivered_carrier_date then 'Early / On Time'
ELSE 'Late'
END,
arrival_status = CASE 
WHEN order_estimated_delivery_date>= order_delivered_customer_date then 'Early / On Time'
ELSE 'Late'
END,
payment_type = CASE WHEN payment_type='boleto' then 'ticket' else payment_type END

-- THERE ARE NOT MANY DATA FOR CANCELED ORDERS, SO IT IS BETTER TO DROP ROWS WITH CANCELED STATUS AND FOCUS ON DELIVERED ORDERS
DELETE FROM #TORDERS WHERE order_status = 'canceled' 

-- REMOVE OUTLIERS AND UNCONSISTENT DATA
DELETE FROM #TORDERS WHERE order_purchase_timestamp > order_approved_at
OR order_approved_at > order_delivered_carrier_date 
OR order_delivered_carrier_date > order_delivered_customer_date
OR order_approved_at > order_estimated_delivery_date
OR estimated_delivery_days >60
OR arrival_days > 60
OR shipping_days >60

--DROP TABLE #TORDERS

-- FINDING KPI'S
-- # OF CUSTOMERS, TOTAL SALES(USD), TOTAL ORDERS, AVG ORDER VALUE(USD), AVG DELIVERY DAYS
SELECT 
COUNT(DISTINCT customer_unique_id) as '# of CUSTOMERS',
CAST(SUM(payment_value*EXR.Exchange_Rates)/POWER(10,6) AS DECIMAL(10,2)) AS TOTAL_SALES_IN_M_USD,
COUNT(DISTINCT order_id) AS TOTAL_ORDERS,
CAST(SUM(payment_value*EXR.Exchange_Rates)/COUNT(DISTINCT order_id) AS decimal(10,0)) AS AVG_ORDER_VALUE_IN_USD,
AVG(arrival_days) as AVG_DELIVERY_DAYS
FROM #TORDERS TOR
LEFT JOIN exchange_rate EXR ON CONVERT(DATE,TOR.order_purchase_timestamp)= EXR.Date

-- ARRIVAL STATUS
SELECT arrival_status,
COUNT(DISTINCT order_id) ARRIVAL_STATUS_VALUES,
CAST(CAST(100*COUNT(DISTINCT order_id) AS decimal(10,2))/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS decimal(10,2)) '% ARRIVAL STATUS'
FROM #TORDERS
GROUP BY  arrival_status

-- SELLER TO CARRIER STATUS
SELECT seller_to_carrier_status,
COUNT(DISTINCT order_id) AS value,
CAST(CAST(100*COUNT(DISTINCT order_id) AS decimal(10,2))/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS decimal(10,1)) AS '% value'
FROM #TORDERS
GROUP BY seller_to_carrier_status

-- TOP 10 SELLER LOCATIONS
SELECT TOP 10
seller_location,
COUNT(DISTINCT order_id) TOTAL_ORDERS
FROM #TORDERS
GROUP BY seller_location
ORDER BY TOTAL_ORDERS DESC

-- AVG REVIEW SCORE
SELECT 
CAST(AVG(CAST(review_score AS FLOAT)) AS decimal(10,2)) AS AVG_REVIEW_SCORE
FROM #TORDERS

-- PRODUCT CATEGORIES
SELECT 
product_category,
COUNT(DISTINCT order_id) TOTAL_ORDERS,
100*COUNT(DISTINCT order_id)/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS '% OF TOTAL ORDERS'
FROM #TORDERS
GROUP BY product_category
ORDER BY TOTAL_ORDERS DESC

-- PRODUCT CATEGORIES WITH AVG SHIPPING DAYS AND AVG PROCESSING DAYS
SELECT 
product_category,
CAST(AVG(CAST(processing_days AS float)) AS decimal(10,2)) avg_processing_days,
CAST(AVG(CAST(shipping_days AS float)) AS decimal(10,2)) avg_shipping_days
FROM #TORDERS
GROUP BY product_category

-- PAYMENT TYPES
SELECT
payment_type,
COUNT(DISTINCT order_id) TOTAL_ORDERS,
CAST(100.0*COUNT(DISTINCT order_id)/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS decimal(10,1)) AS '% ORDERS'
FROM #TORDERS
GROUP BY payment_type

-- PAYMENT INSTALLMENTS WITH PAYMENT TYPES
SELECT 
payment_installments,payment_type,
COUNT(DISTINCT order_id) TOTAL_ORDERS
FROM #TORDERS
GROUP BY payment_installments,payment_type
ORDER BY payment_installments


