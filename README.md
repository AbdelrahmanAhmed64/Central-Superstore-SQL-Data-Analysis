# Central Superstore SQL Data Warehouse & Business Analytics

 Project Overview

This project transforms raw Superstore sales data into a structured SQL Server data warehouse and uses SQL to generate meaningful business insights.

The project follows a simplified data workflow:

Raw Data → Data Warehouse → SQL Analytics → Business Insights**

The source dataset contains transaction-level sales data from the **Central region**. The data was imported into SQL Server, transformed into a **Star Schema**, and analyzed using SQL queries.

---

## Business Objective

The main objective of this project is to analyze sales performance and identify important business patterns related to:

- Sales and profitability
- Product and category performance
- Customer value and behavior
- Discounts and their relationship with profitability
- Monthly and yearly trends
- Geographic performance
- Shipping performance
- Repeat vs one-time customers
- High-sales and low-profit products

The project also demonstrates how SQL Server can be used to build a structured analytical database instead of relying only on raw transaction data.

---

## Dataset

The project uses a Superstore sales dataset focused on the Central region.

### Dataset Summary

| Metric | Value |
|---|---:|
| Source Sheet | Central_Region |
| Region | Central |
| Transaction Rows | 2,323 |
| Unique Orders | 1,175 |
| Unique Customers | 629 |
| Distinct Product IDs | 1,310 |
| Distinct Order Dates | 720 |
| Source Columns | 21 |

### Main Source Columns

- Row ID
- Order ID
- Order Date
- Ship Date
- Ship Mode
- Customer ID
- Customer Name
- Segment
- Country
- City
- State
- Postal Code
- Region
- Product ID
- Category
- Sub-Category
- Product Name
- Sales
- Quantity
- Discount
- Profit

---

## Data Warehouse Architecture

The raw dataset was transformed into a Star Schema consisting of five dimension tables and one central fact table.

### Dimension Tables

- `Customer`
- `Products`
- `Locations`
- `Dates`
- `ShipMode`

### Fact Table

- `FactSales`

### Star Schema

```text
                    Customer
                       |
                       |
Products --------- FactSales --------- Locations
                       |
                       |
                     Dates
                       |
                       |
                   ShipMode
```

The `FactSales` table contains the transaction-level measures and foreign keys connecting the fact table to the dimension tables.

---

## Fact Table Grain

The grain of the `FactSales` table is:

> **One row represents one sales transaction line.**

The dataset contains 2,323 transaction rows but only 1,175 unique orders because a single order can contain multiple products.

Therefore, order-level calculations use:

```sql
COUNT(DISTINCT OrderID)
```

instead of simply counting rows.

---

## ETL Process

The project follows a simplified ETL workflow:

```text
Central_Superstore.xlsx
          ↓
        CSV
          ↓
   RawSuperstore
          ↓
      Transform
          ↓
 ┌────────┼────────┬──────────┬────────┬──────────┐
 ↓        ↓        ↓          ↓        ↓
Customer Products Locations  Dates  ShipMode
 └────────┴────────┴──────────┴────────┴──────────┘
                    ↓
                FactSales
                    ↓
             SQL Analytics
                    ↓
            Business Insights
```

### Extract

The original data was provided in an Excel workbook containing 2,323 transaction records.

### Transform

The raw data was transformed into separate dimension tables and a central fact table.

Date attributes such as year, quarter, month, and day name were also created.

### Load

The transformed data was loaded into the SQL Server data warehouse and connected through primary and foreign keys.

---

## Important Data Quality Handling

During the data warehouse creation, a data quality issue was identified in the product data.

Some `Product_ID` values appeared with different `Product_Name` values.

Because of this, product matching was performed using both:

```text
Product_ID + Product_Name
```

instead of using `Product_ID` alone.

This ensured that all 2,323 source transactions were correctly matched with product records.

---

## SQL Analysis

The project contains **27 analytical queries** covering different business questions.

### Basic Business Analysis

1. Sales performance overview
2. Sales and profit by category
3. Sales and profit by segment
4. Top customers by sales and profit
5. Top products by sales
6. Loss-making products
7. Monthly sales and profit trend
8. Yearly sales and profit performance

### Advanced Analysis

9. Customers above average sales
10. Customer sales segmentation
11. Sub-category sales and profit analysis
12. Category performance vs average
13. Discount impact on sales and profit
14. Customer order frequency
15. Repeat vs one-time customers
16. Shipping performance by ship mode
17. Sales and profit by city
18. Sales and profit by state
19. State profitability ranking
20. State contribution to total sales
21. High-sales but low-profit products

### CTE and Window Functions

22. Cumulative monthly sales
23. Yearly sales comparison

---

## SQL Concepts Demonstrated

The project demonstrates practical SQL Server concepts including:

- SELECT
- WHERE
- GROUP BY
- ORDER BY
- HAVING
- JOINs
- INNER JOIN
- LEFT JOIN
- Aggregate Functions
- COUNT(DISTINCT)
- CASE
- Subqueries
- Common Table Expressions (CTEs)
- Window Functions
- `SUM() OVER()`
- `RANK()`
- Self Join
- `NULLIF()`
- Views
- Stored Procedures
- Primary Keys
- Foreign Keys

---

## Reusable Database Objects

### View

A reusable KPI View was created:

```text
vw_SalesKPIs
```

It provides:

- Total Sales
- Total Profit
- Total Orders
- Average Order Value
- Profit Margin

### Stored Procedure

A parameterized Stored Procedure was created:

```text
sp_SalesAnalysis
```

It accepts:

```text
@Year
@Category
```

and returns sales, profit, quantity, orders, and profit margin for the selected year and category.

---

## Key Business Insights

### Overall Performance

| KPI | Result |
|---|---:|
| Total Sales | 501,239.88 |
| Total Profit | 39,706.45 |
| Total Orders | 1,175 |
| Average Order Value | 426.59 |
| Profit Margin | 7.92% |

### Main Findings

- **Technology** generated the highest sales and strongest overall profit among the three categories.
- **Furniture** generated high sales but resulted in an overall loss.
- **Consumer** customers generated the highest sales.
- **Corporate** customers generated significantly higher profit despite lower sales than Consumer.
- Repeat customers represented approximately **55% of the customer base** and generated approximately **73% of total sales**.
- Some high-selling products were loss-making, showing that revenue alone is not enough to evaluate product performance.
- Higher discount levels were strongly associated with lower profitability in this dataset.
- **Texas** generated the highest state-level sales but also recorded the largest overall loss.
- **Michigan** ranked first in total state profit.
- **Houston** had the highest city-level sales but recorded a significant loss.
- **2015** was the strongest year in terms of total profit.
- **2016** generated almost the same sales as 2015 but with significantly lower profit.
- Same Day shipping had the shortest average shipping time, while Standard Class had the longest.

---

## Validation

Several validation checks were performed to verify the data warehouse.

### Row Validation

```text
RawSuperstore Rows = 2,323
FactSales Rows     = 2,323
```

### Unique Row Validation

```text
Raw Unique Row IDs  = 2,323
Fact Unique Row IDs = 2,323
```

### FactSales Summary

```text
Transaction Rows = 2,323
Unique Orders    = 1,175
Total Quantity   = 8,780
```

These checks confirm that the transaction rows were successfully transferred into the fact table without losing or duplicating Row IDs.

---

## Tools & Technologies

- **Microsoft Excel** — Original dataset
- **CSV** — Data transfer and import
- **Microsoft SQL Server** — Data warehouse and database
- **SQL Server Management Studio (SSMS)** — SQL development and database management
- **SQL** — Data transformation, analysis, and business insights

---

## Project Structure

```text
Central-Superstore-SQL-Project/
│
├── README.md
│
├── SQL/
│   └── Central_Superstore_SQL_Project.sql
│
├── Data/
│   └── Central_Superstore.csv
│
├── Documentation/
│   └── Central_Superstore_SQL_Project_Documentation.pdf
│
└── Screenshots/
```

---

## Project Outcome

This project demonstrates the complete workflow from raw transaction data to a structured analytical data warehouse and business insights.

It combines:

**Data Preparation + Data Warehousing + SQL Analytics + Validation + Business Analysis**

The project also demonstrates the ability to use SQL not only for retrieving data, but for structuring data, analyzing business performance, identifying problems, and supporting data-driven decision-making.
