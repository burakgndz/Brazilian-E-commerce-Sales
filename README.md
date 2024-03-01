# Brazilian-E-commerce-Sales

Brazilian E-Commerce dataset is a public dataset provided by Olist. For more information, visit <a href="https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce">the kaggle page.</a> <br> <br>
The project’s goal is to extract overall insights and assess delivery performance. Initially, data is merged into a single file using Python, which contains all the necessary information. Basic data cleaning is performed during this step. Subsequently, additional cleaning takes place within Power BI. Finally, MSSQL is used to verify the results of the dashboard.

## Data Schema
Here's the data schema:

![schema](https://i.imgur.com/HRhd2Y0.png)


## 1) Python / Data Cleaning & Merging

```python
#import pandas for data manipulation
import pandas as pd

#load datasets
customer = pd.read_csv("olist_customers_dataset.csv")
order_items =  pd.read_csv("olist_order_items_dataset.csv")
order_payments =  pd.read_csv("olist_order_payments_dataset.csv")
order_reviews =  pd.read_csv("olist_order_reviews_dataset.csv")
orders =  pd.read_csv("olist_orders_dataset.csv")
product = pd.read_csv("olist_products_dataset.csv")
sellers = pd.read_csv("olist_sellers_dataset.csv")
product_category_name = pd.read_csv("product_category_name_translation.csv")

#merging
df = pd.merge(customer,orders, how="inner", on="customer_id")
df = df.merge(order_items,how="inner",on="order_id")
df = df.merge(order_payments,how="inner",on="order_id")
df = df.merge(order_reviews,how="inner",on="order_id")
df = df.merge(product,how="inner",on="product_id")
df = df.merge(sellers,how="inner",on="seller_id")
df = df.merge(product_category_name,how="inner",on="product_category_name")

#checking null count
df.isnull().sum()

#drop null values
df = df.dropna(subset=["order_approved_at","order_delivered_carrier_date","order_delivered_customer_date",
                       "product_weight_g",
                      "product_length_cm",
                      "product_height_cm",
                      "product_width_cm"])

# There are some null values in comment title and comment message, we do not want to drop these because, for this project,these null values do not affect the data.
df.review_comment_title.fillna("No Title",inplace=True)
df.review_comment_message.fillna("No Message",inplace=True)

#adding new feature
df["product_volume_cm3"] = df.product_length_cm*df.product_height_cm*df.product_width_cm
df = df.drop(["product_width_cm","product_length_cm","product_height_cm"],axis=1)

#organizing categories
def classify_category(x):
    categories = {
        'Furniture': ['office_furniture', 'furniture_decor', 'furniture_living_room', 'kitchen_dining_laundry_garden_furniture', 'bed_bath_table',  'furniture_bedroom', 'furniture_mattress_and_upholstery'],
        'Electronics': ['auto', 'computers_accessories', 'musical_instruments', 'consoles_games', 'watches_gifts', 'air_conditioning', 'telephony', 'electronics', 'fixed_telephony', 'tablets_printing_image', 'computers', 'small_appliances_home_oven_and_coffee', 'small_appliances', 'audio', 'signaling_and_security', 'security_and_services'],
        'Fashion': ['fashio_female_clothing', 'fashion_male_clothing', 'fashion_bags_accessories', 'fashion_shoes', 'fashion_sport', 'fashion_underwear_beach', 'fashion_childrens_clothes',  'cool_stuff'],
        'Home & Garden': ['home_comfort','home_confort', 'home_comfort_2', 'home_construction', 'garden_tools','housewares',  'home_appliances', 'home_appliances_2', 'flowers', 'costruction_tools_garden',  'construction_tools_lights', 'costruction_tools_tools', 'luggage_accessories', 'la_cuisine'],
        'Entertainment': ['pet_shop','sports_leisure', 'toys', 'cds_dvds_musicals', 'music', 'dvds_blu_ray', 'cine_photo', 'party_supplies', 'christmas_supplies', 'arts_and_craftmanship', 'art'],
        'Beauty & Health': ['health_beauty', 'perfumery', 'diapers_and_hygiene','baby'],
        'Food & Drinks': [ 'market_place','food_drink', 'drinks', 'food'],
        'Books & Stationery': ['books_general_interest', 'books_technical', 'books_imported', 'stationery'],
        'Industry & Construction': ['construction_tools_construction', 'construction_tools_safety', 'industry_commerce_and_business', 'agro_industry_and_commerce']
    }
    for category, keywords in categories.items():
        if x in keywords:
            return category
    return None

df['product_category'] = df['product_category_name_english'].apply(classify_category)

#drop product_category_name_english and product_category_name, we do not need them. Now we have product_category...
df = df.drop(["product_category_name_english","product_category_name"],axis=1)

#saving the dataset to a new file
df.to_csv("e_commerce_new.csv",index=False)
```
## 2) Power BI / Further Cleaning, Adding New Features & Data Visualization

In this section, additional data cleansing has been performed. These steps can be seen on MSSQL section below. Adding new feeatures such as exchange rate, seller location, customer location, arrival days, estimated delivery days, shipping days, processing days, arrival status, and seller to carrier status is done. Click <a href="https://github.com/burakgndz/Brazilian-E-commerce-Sales/blob/main/e-commerce_power_bi.pdf">here</a> to see the pdf of data visualization.

## 3) MSSQL / Verifing The Results

In this section, multiple joins are performed, and a temporary table is created for the e-commerce dataset. Afterward, the same procedure is followed as in the Python section, which involves eliminating null values, adding new features, organizing categories, and dropping unnecessary features. 

Here's the code for creating and finalizing the table: 

```sql
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

```

- Now it is time to find some KPI's:

```sql
-- # OF CUSTOMERS, TOTAL SALES(USD), TOTAL ORDERS, AVG ORDER VALUE(USD), AVG DELIVERY DAYS
SELECT 
COUNT(DISTINCT customer_unique_id) as '# of CUSTOMERS',
CAST(SUM(payment_value*EXR.Exchange_Rates)/POWER(10,6) AS DECIMAL(10,2)) AS TOTAL_SALES_IN_M_USD,
COUNT(DISTINCT order_id) AS TOTAL_ORDERS,
CAST(SUM(payment_value*EXR.Exchange_Rates)/COUNT(DISTINCT order_id) AS decimal(10,0)) AS AVG_ORDER_VALUE_IN_USD,
AVG(arrival_days) as AVG_DELIVERY_DAYS
FROM #TORDERS TOR
LEFT JOIN exchange_rate EXR ON CONVERT(DATE,TOR.order_purchase_timestamp)= EXR.Date
```

- Output:

![1](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/4f5b10bd-0569-414f-9e67-2701c9e0b44e)

- ARRIVAL STATUS
  
```sql
SELECT arrival_status,
COUNT(DISTINCT order_id) ARRIVAL_STATUS_VALUES,
CAST(CAST(100*COUNT(DISTINCT order_id) AS decimal(10,2))/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS decimal(10,2)) '% ARRIVAL STATUS'
FROM #TORDERS
GROUP BY  arrival_status
```

- Output:
  
  ![2](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/ba4abaf8-22b6-4721-a0dc-29cac684cb4a)

- SELLER TO CARRIER STATUS
  
```sql
SELECT seller_to_carrier_status,
COUNT(DISTINCT order_id) AS value,
CAST(CAST(100*COUNT(DISTINCT order_id) AS decimal(10,2))/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS decimal(10,1)) AS '% value'
FROM #TORDERS
GROUP BY seller_to_carrier_status
```
- Output:

![3](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/f5da8d19-619c-48e3-a8b9-8396672ad237)

- TOP 10 SELLER LOCATIONS
  
```sql
SELECT TOP 10
seller_location,
COUNT(DISTINCT order_id) TOTAL_ORDERS
FROM #TORDERS
GROUP BY seller_location
ORDER BY TOTAL_ORDERS DESC
```
- Output:

![4](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/348121fe-1f76-462a-ae26-dfc5205336fd)

- AVG REVIEW SCORE
  
```sql
SELECT 
CAST(AVG(CAST(review_score AS FLOAT)) AS decimal(10,2)) AS AVG_REVIEW_SCORE
FROM #TORDERS
```
- Output:

![5](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/3738ffdc-dee8-467d-8b53-618bc65452dd)

- PRODUCT CATEGORIES

```sql
SELECT 
product_category,
COUNT(DISTINCT order_id) TOTAL_ORDERS,
100*COUNT(DISTINCT order_id)/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS '% OF TOTAL ORDERS'
FROM #TORDERS
GROUP BY product_category
ORDER BY TOTAL_ORDERS DESC
```
- Output:

![6](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/1dfaaecc-fbea-42c8-875e-5c218071dd7b)

- PRODUCT CATEGORIES WITH AVG SHIPPING DAYS AND AVG PROCESSING DAYS
  
```sql
SELECT 
product_category,
CAST(AVG(CAST(processing_days AS float)) AS decimal(10,2)) avg_processing_days,
CAST(AVG(CAST(shipping_days AS float)) AS decimal(10,2)) avg_shipping_days
FROM #TORDERS
GROUP BY product_category
```
- Output:

![7](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/f3aef76d-f63f-490f-a845-f0a853f760bb)

- PAYMENT TYPES

```sql
SELECT
payment_type,
COUNT(DISTINCT order_id) TOTAL_ORDERS,
CAST(100.0*COUNT(DISTINCT order_id)/(SELECT COUNT(DISTINCT order_id) FROM #TORDERS) AS decimal(10,1)) AS '% ORDERS'
FROM #TORDERS
GROUP BY payment_type
```
- Output:
  
![8](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/a876af08-5db8-4203-ad81-717958bab0ce)

- PAYMENT INSTALLMENTS WITH PAYMENT TYPES

```sql
SELECT 
payment_installments,payment_type,
COUNT(DISTINCT order_id) TOTAL_ORDERS
FROM #TORDERS
GROUP BY payment_installments,payment_type
ORDER BY payment_installments
```
- Output:

![9](https://github.com/burakgndz/Brazilian-E-commerce-Sales/assets/56515947/efdf6188-0620-4882-b2a3-9b2f1b75c695)


## 4) Insights

Here're some insights: 
<ul>
  <li> The customer base is substantial, with a total of 89,702 customers. Total sales over the three years amounted to $5.67 million, indicating a healthy revenue stream. There were 92,624 total orders placed from 2016-2018, showing consistent demand for products. The average order value is $61, and the average delivery days stand at 12 </li>
  <li> 24th November 2017 is the peak of the graph. It is highly possible that the peak in the graph was influenced by Black Friday sales.</li>
  <li> Credit Card is the most popular payment type, accounting for 77.07% of all transactions. Most customers prefer to pay in one installment.</li>
  <li> The product category with the highest total orders is Electronics at 27%, closely followed by Furniture at 18%.</li>
  <li> Furniture products have the longest average processing and shipping days, taking approximately 3.10 and 9.07 days respectively. Food & Drinks products have the shortest average processing (2.81) and shipping days (7.39).</li>
  <li> Most of the orders (92.19%) arrived early/on time. This is consistent with seller to carrier chart (91% early/on time delivery). Average review score is 4.09, meaning customers are happy about the services. </li>
</ul>

For further work, adding an interactive map can help to understand order distribution better. 
