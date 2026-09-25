-- create database
CREATE DATABASE CentralSuperstore

USE CentralSuperstore;


-- create raw data table
CREATE TABLE RawSuperstore
(
    Row_ID INT,
    Order_ID VARCHAR(20),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(20),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(100),
    City VARCHAR(100),
    State VARCHAR(100),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50),
    Product_ID VARCHAR(20),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales DECIMAL(12,2),
    Quantity INT,
    Discount DECIMAL(5,2),
    Profit DECIMAL(12,2)
);


CREATE TABLE Customer(
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID VARCHAR(20) NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Segment VARCHAR(50) NOT NULL
);


CREATE TABLE Products (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID VARCHAR(20) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    SubCategory VARCHAR(50) NOT NULL,
    ProductName VARCHAR(255) NOT NULL
);


CREATE TABLE Locations(
    LocationKey INT IDENTITY(1,1) PRIMARY KEY,
    Country VARCHAR(100) NOT NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL,
    PostalCode VARCHAR(20),
    Region VARCHAR(50) NOT NULL
);

CREATE TABLE Dates
(
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Day INT NOT NULL,
    DayName VARCHAR(20) NOT NULL
);

CREATE TABLE ShipMode(
    ShipModeKey INT IDENTITY(1,1) PRIMARY KEY,
    ShipMode VARCHAR(50) NOT NULL
);


-- FACT SALES the main table
CREATE TABLE FactSales
(
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,

    RowID INT NOT NULL,
    OrderID VARCHAR(20) NOT NULL,

    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    LocationKey INT NOT NULL,
    DateKey INT NOT NULL,
    ShipModeKey INT NOT NULL,

    ShipDate DATE NOT NULL,
    Sales DECIMAL(12,2) NOT NULL,
    Quantity INT NOT NULL,
    Discount DECIMAL(5,2) NOT NULL,
    Profit DECIMAL(12,2) NOT NULL
);

--FK
ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Customer
FOREIGN KEY (CustomerKey)
REFERENCES Customer(CustomerKey);

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Product
FOREIGN KEY (ProductKey)
REFERENCES Products(ProductKey);

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Location
FOREIGN KEY (LocationKey)
REFERENCES Locations(LocationKey);

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Date
FOREIGN KEY (DateKey)
REFERENCES Dates(DateKey);

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_ShipMode
FOREIGN KEY (ShipModeKey)
REFERENCES ShipMode(ShipModeKey);


SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';



-- ==================================================================================
-- insert

INSERT INTO Customer
(
    CustomerID,
    CustomerName,
    Segment
)
SELECT DISTINCT
    Customer_ID,
    Customer_Name,
    Segment
FROM RawSuperstore;


INSERT INTO Products
(
    ProductID,
    Category,
    SubCategory,
    ProductName
)
SELECT DISTINCT
    Product_ID,
    Category,
    Sub_Category,
    Product_Name
FROM RawSuperstore;

INSERT INTO Locations
(
    Country,
    City,
    State,
    PostalCode,
    Region
)
SELECT DISTINCT
    Country,
    City,
    State,
    Postal_Code,
    Region
FROM RawSuperstore;

-----------------------------
INSERT INTO ShipMode
(
    ShipMode
)
SELECT DISTINCT
    Ship_Mode
FROM RawSuperstore;

-----------------------
INSERT INTO Dates
(
    DateKey,
    FullDate,
    Year,
    Quarter,
    Month,
    MonthName,
    Day,
    DayName
)
SELECT
    CONVERT(INT, CONVERT(VARCHAR(8), FullDate, 112)) AS DateKey,
    FullDate,
    YEAR(FullDate) AS Year,
    DATEPART(QUARTER, FullDate) AS Quarter,
    MONTH(FullDate) AS Month,
    DATENAME(MONTH, FullDate) AS MonthName,
    DAY(FullDate) AS Day,
    DATENAME(WEEKDAY, FullDate) AS DayName
FROM
(
    SELECT DISTINCT Order_Date AS FullDate
    FROM RawSuperstore
) AS DateList;

-----------------------------
INSERT INTO FactSales
(
    RowID,
    OrderID,
    CustomerKey,
    ProductKey,
    LocationKey,
    DateKey,
    ShipModeKey,
    ShipDate,
    Sales,
    Quantity,
    Discount,
    Profit
)
SELECT
    Raw.Row_ID,
    Raw.Order_ID,
    Customer.CustomerKey,
    Products.ProductKey,
    Locations.LocationKey,
    Dates.DateKey,
    ShipMode.ShipModeKey,
    Raw.Ship_Date,
    Raw.Sales,
    Raw.Quantity,
    Raw.Discount,
    Raw.Profit
FROM RawSuperstore AS Raw

INNER JOIN Customer
    ON Raw.Customer_ID = Customer.CustomerID

INNER JOIN Products
    ON Raw.Product_ID = Products.ProductID
    AND Raw.Product_Name = Products.ProductName

INNER JOIN Locations
    ON Raw.Country = Locations.Country
    AND Raw.City = Locations.City
    AND Raw.State = Locations.State
    AND ISNULL(Raw.Postal_Code, '') = ISNULL(Locations.PostalCode, '')
    AND Raw.Region = Locations.Region

INNER JOIN Dates
    ON Raw.Order_Date = Dates.FullDate

INNER JOIN ShipMode
    ON Raw.Ship_Mode = ShipMode.ShipMode;


SELECT  COUNT(*) AS TotalRows,
		 COUNT(DISTINCT RowID) AS UniqueRows,
		 COUNT(DISTINCT OrderID) AS UniqueOrders,
		 SUM(Sales) AS TotalSales,
		 SUM(Profit) AS TotalProfit,
		 SUM(Quantity) AS TotalQuantity
FROM FactSales;





--==================================================================================

-- 1.Sales KPI
SELECT  SUM(Sales) AS TotalSales,
		SUM(Profit) AS TotalProfit,
		COUNT(DISTINCT OrderID) AS TotalOrders,
	    SUM(Sales) / COUNT(DISTINCT OrderID) AS AverageOrderValue,
	    (SUM(Profit) / SUM(Sales)) * 100 AS ProfitMargin
FROM FactSales;


-- 2.sales and profit by category
SELECT Products.Category,
		SUM(FactSales.Sales) AS TotalSales,
		SUM(FactSales.Profit) AS TotalProfit,
		SUM(FactSales.Quantity) AS TotalQuantity
FROM FactSales
JOIN Products ON FactSales.ProductKey = Products.ProductKey
GROUP BY Products.Category
ORDER BY TotalSales DESC;



--  3. sales and profit by segment
SELECT
    Customer.Segment,
    SUM(FactSales.Sales) AS TotalSales,
    SUM(FactSales.Profit) AS TotalProfit
FROM FactSales
JOIN Customer ON FactSales.CustomerKey = Customer.CustomerKey
GROUP BY Customer.Segment
ORDER BY TotalSales DESC;

---- top customers by sales
--SELECT TOP 10 Customer.CustomerName, SUM(FactSales.Sales) AS TotalSales
--FROM FactSales
--JOIN Customer ON FactSales.CustomerKey = Customer.CustomerKey
--GROUP BY Customer.CustomerName
--ORDER BY TotalSales DESC;

----  top customers by profit
--SELECT TOP 10 Customer.CustomerName,
--			  SUM(FactSales.Profit) AS TotalProfit
--FROM FactSales
--JOIN Customer ON FactSales.CustomerKey = Customer.CustomerKey
--GROUP BY Customer.CustomerName
--ORDER BY TotalProfit DESC;

-- 4. top customers by sales and profit
SELECT TOP 10 Customer.CustomerName,
			  SUM(FactSales.Sales) AS TotalSales,
			  SUM(FactSales.Profit) AS TotalProfit
FROM FactSales
JOIN Customer ON FactSales.CustomerKey = Customer.CustomerKey
GROUP BY Customer.CustomerName
ORDER BY TotalSales DESC;


-- 5. top products by sales
SELECT TOP 10 Products.ProductName,
			  SUM(FactSales.Sales) AS TotalSales,
		      SUM(FactSales.Profit) AS TotalProfit
FROM FactSales
JOIN Products ON FactSales.ProductKey = Products.ProductKey
GROUP BY Products.ProductName
ORDER BY TotalSales DESC;

--------------------------------
-- 6. loss-making products
-- good sales , not good profit
SELECT top 10 Products.ProductName,
	   SUM(FactSales.Sales) AS TotalSales,
	   SUM(FactSales.Profit) AS TotalProfit
FROM FactSales
JOIN Products ON FactSales.ProductKey = Products.ProductKey
GROUP BY Products.ProductName
HAVING SUM(FactSales.Profit) < 0
ORDER BY TotalProfit ASC;

--------------------------------
-- 7. monthly sales and profit trend
-- 1.sales
--September 2013 34,408.69
--December 2015 26,269.29
--October 2015  25,098.06

--2. profit
--October 2015  10,656.87
--December 2015  7,364.14
--December 2014  4,191.51
SELECT Dates.Year, Dates.Month, Dates.MonthName,
       SUM(FactSales.Sales) AS TotalSales,
       SUM(FactSales.Profit) AS TotalProfit
FROM FactSales
JOIN Dates ON FactSales.DateKey = Dates.DateKey
GROUP BY Dates.Year, Dates.Month, Dates.MonthName
ORDER BY Dates.Year,  Dates.Month;



-- 8. yearly sales and profit performance
SELECT Dates.Year,
       SUM(FactSales.Sales) AS TotalSales,
       SUM(FactSales.Profit) AS TotalProfit,
       COUNT(DISTINCT FactSales.OrderID) AS TotalOrders
FROM FactSales
JOIN Dates ON FactSales.DateKey = Dates.DateKey
GROUP BY Dates.Year
ORDER BY Dates.Year;

----------------------------------------
-- advanced
----------------------------------------
-- 9. customers above average sales
SELECT Customer.CustomerName, SUM(FactSales.Sales) AS TotalSales
FROM FactSales
JOIN Customer ON FactSales.CustomerKey = Customer.CustomerKey
GROUP BY Customer.CustomerName
HAVING SUM(FactSales.Sales) >
(
    SELECT AVG(CustomerSales.TotalSales)
    FROM
    (
        SELECT
            CustomerKey,
            SUM(Sales) AS TotalSales
        FROM FactSales
        GROUP BY CustomerKey
    ) AS CustomerSales
)
ORDER BY TotalSales DESC;


-- 10. customer sales segmentation
SELECT Customer.CustomerName,
       SUM(FactSales.Sales) AS TotalSales,
    CASE
        WHEN SUM(FactSales.Sales) >= 5000 THEN 'High Value'
        WHEN SUM(FactSales.Sales) >= 2000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerType
FROM FactSales
JOIN Customer ON FactSales.CustomerKey = Customer.CustomerKey
GROUP BY Customer.CustomerName
ORDER BY TotalSales DESC;


--window fun and cte
-- 11. sub category sales and profit analysis
WITH SubCategorySales AS
(
    SELECT Products.SubCategory,
          SUM(FactSales.Sales) AS TotalSales,
          SUM(FactSales.Profit) AS TotalProfit
    FROM FactSales
    JOIN Products ON FactSales.ProductKey = Products.ProductKey
    GROUP BY Products.SubCategory
)
SELECT SubCategory, TotalSales, TotalProfit,
       (TotalProfit / NULLIF(TotalSales, 0)) * 100 AS ProfitMargin
FROM SubCategorySales
ORDER BY TotalSales DESC;


-- 12. category performance vs average
WITH CategorySales AS
(
    SELECT  Products.Category,
            SUM(FactSales.Sales) AS TotalSales
    FROM FactSales
    JOIN Products ON FactSales.ProductKey = Products.ProductKey
    GROUP BY Products.Category
)
SELECT Category, TotalSales,
       AVG(TotalSales) OVER () AS AverageCategorySales,
    CASE
        WHEN TotalSales > AVG(TotalSales) OVER ()
            THEN 'Above Average'
        ELSE 'Below Average'
    END AS Performance
FROM CategorySales
ORDER BY TotalSales DESC;


-------------------------------------------------
-- 13. discount impact on sales and profit
SELECT
    CASE
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.20 THEN 'Low Discount'
        WHEN Discount <= 0.40 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS DiscountLevel,
    COUNT(*) AS TotalItems,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit,
    (SUM(Profit) / NULLIF(SUM(Sales), 0)) * 100 AS ProfitMargin
FROM FactSales
GROUP BY
    CASE
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.20 THEN 'Low Discount'
        WHEN Discount <= 0.40 THEN 'Medium Discount'
        ELSE 'High Discount'
    END
ORDER BY TotalSales DESC;

--------------------------------------------------------
-- 14. customer order frequency
SELECT Customer.CustomerName,
	   COUNT(DISTINCT FactSales.OrderID) AS TotalOrders,
       SUM(FactSales.Sales) AS TotalSales,
       SUM(FactSales.Sales) / COUNT(DISTINCT FactSales.OrderID) AS AverageOrderValue
FROM FactSales
JOIN Customer ON FactSales.CustomerKey = Customer.CustomerKey
GROUP BY Customer.CustomerName
HAVING COUNT(DISTINCT FactSales.OrderID) > 1
ORDER BY TotalOrders DESC, TotalSales DESC;


-- 15. repeat vs one-time customers
WITH CustomerOrders AS
(
    SELECT  CustomerKey,
			COUNT(DISTINCT OrderID) AS TotalOrders,
			SUM(Sales) AS TotalSales
    FROM FactSales
    GROUP BY CustomerKey
)
SELECT
    CASE
        WHEN TotalOrders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS CustomerType,
    COUNT(*) AS TotalCustomers,
    SUM(TotalOrders) AS TotalOrders,
    SUM(TotalSales) AS TotalSales,
    SUM(TotalSales) / COUNT(*) AS AverageCustomerSales
FROM CustomerOrders
GROUP BY
    CASE
        WHEN TotalOrders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END
ORDER BY TotalSales DESC;



-- shipe
-----------------------------------------------------
-- 16. shipping performance by ship mode
WITH OrderShipping AS
(
    SELECT
        FactSales.OrderID,
        FactSales.ShipModeKey,
        MIN(Dates.FullDate) AS OrderDate,
        MIN(FactSales.ShipDate) AS ShipDate
    FROM FactSales
    JOIN Dates
        ON FactSales.DateKey = Dates.DateKey
    GROUP BY
        FactSales.OrderID,
        FactSales.ShipModeKey
)
SELECT  ShipMode.ShipMode,
		COUNT(*) AS TotalOrders,
	   AVG(DATEDIFF(DAY, OrderDate, ShipDate) * 1.0) AS AverageShippingDays,
	   MIN(DATEDIFF(DAY, OrderDate, ShipDate)) AS MinShippingDays,
	   MAX(DATEDIFF(DAY, OrderDate, ShipDate)) AS MaxShippingDays
FROM OrderShipping
JOIN ShipMode ON OrderShipping.ShipModeKey = ShipMode.ShipModeKey
GROUP BY ShipMode.ShipMode
ORDER BY AverageShippingDays;




--Region/Location
-------------------------------------------
-- 17. sales and profit by city
SELECT TOP 15 Locations.City, Locations.State,
	   SUM(FactSales.Sales) AS TotalSales,
       SUM(FactSales.Profit) AS TotalProfit,
       COUNT(DISTINCT FactSales.OrderID) AS TotalOrders
FROM FactSales
JOIN Locations ON FactSales.LocationKey = Locations.LocationKey
GROUP BY  Locations.City, Locations.State
ORDER BY TotalSales DESC;




-- 18. sales and profit by state
SELECT   Locations.State,
		 SUM(FactSales.Sales) AS TotalSales,
		 SUM(FactSales.Profit) AS TotalProfit,
		 COUNT(DISTINCT FactSales.OrderID) AS TotalOrders,
		 (SUM(FactSales.Profit) / NULLIF(SUM(FactSales.Sales), 0)) * 100 AS ProfitMargin
FROM FactSales
JOIN Locations  ON FactSales.LocationKey = Locations.LocationKey
GROUP BY Locations.State
ORDER BY TotalSales DESC;

----------------------------------------------------------
---------------------------------------------------------
-- 19. state profitability ranking
SELECT  Locations.State,
		SUM(FactSales.Sales) AS TotalSales,
	    SUM(FactSales.Profit) AS TotalProfit,
	    RANK() OVER (ORDER BY SUM(FactSales.Profit) DESC) AS ProfitRank
FROM FactSales
JOIN Locations ON FactSales.LocationKey = Locations.LocationKey
GROUP BY Locations.State
ORDER BY ProfitRank;


-- 20. state contribution to total sales
SELECT Locations.State,
	   SUM(FactSales.Sales) AS TotalSales,
	   SUM(SUM(FactSales.Sales)) OVER () AS OverallSales,
	   (SUM(FactSales.Sales) / SUM(SUM(FactSales.Sales)) OVER ()) * 100 AS SalesContribution
FROM FactSales
JOIN Locations ON FactSales.LocationKey = Locations.LocationKey
GROUP BY Locations.State
ORDER BY SalesContribution DESC;



-- 21. high sales but low profit products
SELECT Products.ProductName,
		SUM(FactSales.Sales) AS TotalSales,
		SUM(FactSales.Profit) AS TotalProfit,
		(SUM(FactSales.Profit) / NULLIF(SUM(FactSales.Sales), 0)) * 100 AS ProfitMargin
FROM FactSales
JOIN Products ON FactSales.ProductKey = Products.ProductKey
GROUP BY Products.ProductName
HAVING SUM(FactSales.Sales) >= 3000
		AND SUM(FactSales.Profit) < 0
ORDER BY TotalSales DESC;    


----------------------------------------------------
--Window Functions
-----------------------------------------------------

-- 22. cumulative monthly sales
WITH MonthlySales AS
(
    SELECT Dates.Year, Dates.Month, Dates.MonthName,
           SUM(FactSales.Sales) AS TotalSales
    FROM FactSales
    JOIN Dates ON FactSales.DateKey = Dates.DateKey
    GROUP BY Dates.Year, Dates.Month, Dates.MonthName
)
SELECT Year, Month, MonthName, TotalSales,
       SUM(TotalSales) OVER (
        ORDER BY Year, Month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeSales
FROM MonthlySales
ORDER BY Year, Month;



-- 23. yearly sales comparison
WITH YearlySales AS
(
    SELECT  Dates.Year,
            SUM(FactSales.Sales) AS TotalSales
    FROM FactSales
    JOIN Dates ON FactSales.DateKey = Dates.DateKey
    GROUP BY Dates.Year
)
SELECT  CurrentYear.Year,
		CurrentYear.TotalSales,
		PreviousYear.TotalSales AS PreviousYearSales,
		CurrentYear.TotalSales - PreviousYear.TotalSales AS SalesGrowth,
    (
        (CurrentYear.TotalSales - PreviousYear.TotalSales)
        / NULLIF(PreviousYear.TotalSales, 0)
    ) * 100 AS GrowthPercentage
FROM YearlySales AS CurrentYear
LEFT JOIN YearlySales AS PreviousYear
    ON CurrentYear.Year = PreviousYear.Year + 1
ORDER BY CurrentYear.Year;



----------------------------------------------------
--View
-----------------------------------------------------

-- 24. create business kpi view

CREATE VIEW vw_SalesKPIs AS
SELECT  SUM(Sales) AS TotalSales,
		SUM(Profit) AS TotalProfit,
		COUNT(DISTINCT OrderID) AS TotalOrders,
		SUM(Sales) / COUNT(DISTINCT OrderID) AS AverageOrderValue,
		(SUM(Profit) / NULLIF(SUM(Sales), 0)) * 100 AS ProfitMargin
FROM FactSales;
GO

-- test
SELECT *
FROM vw_SalesKPIs;



----------------------------------------------------
--stored procedure
-----------------------------------------------------

-- 25. create stored procedure for sales analysis
-- Technology in 2015 
CREATE PROCEDURE sp_SalesAnalysis
    @Year INT,
    @Category VARCHAR(50)
AS
BEGIN

    SELECT Dates.Year, Products.Category,
           SUM(FactSales.Sales) AS TotalSales,
           SUM(FactSales.Profit) AS TotalProfit,
           SUM(FactSales.Quantity) AS TotalQuantity,
           COUNT(DISTINCT FactSales.OrderID) AS TotalOrders,
           (SUM(FactSales.Profit) / NULLIF(SUM(FactSales.Sales), 0)) * 100 AS ProfitMargin
    FROM FactSales
    JOIN Dates ON FactSales.DateKey = Dates.DateKey
    JOIN Products ON FactSales.ProductKey = Products.ProductKey
    WHERE  Dates.Year = @Year
           AND Products.Category = @Category
    GROUP BY Dates.Year, Products.Category;

END;
GO

-- Technology in 2015
EXEC sp_SalesAnalysis
    @Year = 2015,
    @Category = 'Technology';

-- Furniture in 2016
EXEC sp_SalesAnalysis
    @Year = 2016,
    @Category = 'Furniture';




------------------------------------------------------------
-- 26. final data validation
SELECT
    (SELECT COUNT(*) FROM RawSuperstore) AS RawRows,
    (SELECT COUNT(*) FROM FactSales) AS FactRows,
    (SELECT COUNT(DISTINCT Row_ID) FROM RawSuperstore) AS RawUniqueRows,
    (SELECT COUNT(DISTINCT RowID) FROM FactSales) AS FactUniqueRows;

-- 27. final totals validation
SELECT
    'RawSuperstore' AS SourceTable,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit,
    SUM(Quantity) AS TotalQuantity
FROM RawSuperstore

UNION ALL

SELECT
    'FactSales' AS SourceTable,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit,
    SUM(Quantity) AS TotalQuantity
FROM FactSales;
