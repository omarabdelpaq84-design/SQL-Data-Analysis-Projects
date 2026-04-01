USE GroceryDB;
GO

SELECT TOP 10 * 
FROM GroceryData;


-- Get Data Size 
SELECT COUNT(*) AS TotalRows 
FROM GroceryData;


-- Get Sample of Data 
SELECT TOP 10 * 
FROM GroceryData
ORDER BY NEWID();

-- Item Fat Content Values 
SELECT DISTINCT Item_Fat_Content
FROM GroceryData;


-- Item Fat Content Column Cleaning 
UPDATE GroceryData
SET Item_Fat_Content = 'Low Fat'
WHERE Item_Fat_Content IN ('low fat','LF');
UPDATE GroceryData
SET Item_Fat_Content = 'Regular'
WHERE Item_Fat_Content IN ('reg');

-- Check Value

SELECT DISTINCT Item_Fat_Content
FROM GroceryData;

-- Regular vs Low Fat Sales

SELECT Item_Fat_Content, SUM(Total_Sales) AS TotalSales
FROM GroceryData
GROUP BY Item_Fat_Content;

-- Count of Null Values in Item_Weight Column

SELECT COUNT(*) AS Null_Item_Weight
FROM GroceryData
WHERE Item_Weight IS NULL;


-- AVG Item_Weight Column

SELECT AVG(Item_Weight) AS Avg_Item_Weight
FROM GroceryData;


-- Handle Missing Values in Item_Weight 

UPDATE GroceryData
SET Item_Weight = (SELECT AVG(Item_Weight) FROM GroceryData)
WHERE Item_Weight IS NULL;


-- Check existence of missing values بعد التحديث

SELECT COUNT(*) AS Null_After_Update
FROM GroceryData
WHERE Item_Weight IS NULL;


-- Get Look of Data

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GroceryData';


-- Total Sales

SELECT SUM(Total_Sales) AS Total_Sales_All
FROM GroceryData;


-- Total Sales When Item Fat Content = Low Fat

SELECT SUM(Total_Sales) AS Total_Sales_LowFat
FROM GroceryData
WHERE Item_Fat_Content = 'Low Fat';


-- Total Sales When Item Fat Content = Regular

SELECT SUM(Total_Sales) AS Total_Sales_Regular
FROM GroceryData
WHERE Item_Fat_Content = 'Regular';


-- Which one is more profitable (Fat Content vs Sales)

SELECT Item_Fat_Content, SUM(Total_Sales) AS TotalSales
FROM GroceryData
GROUP BY Item_Fat_Content
ORDER BY TotalSales DESC;


-- Average Sales

SELECT AVG(Total_Sales) AS Avg_Sales
FROM GroceryData;


-- Average Sales in 2022

SELECT AVG(Total_Sales) AS Avg_Sales_2022
FROM GroceryData
WHERE Outlet_Establishment_Year = 2022;


-- Item Counts

SELECT COUNT(DISTINCT Item_Identifier) AS Total_Items
FROM GroceryData;


-- Sold Item Counts in 2022

SELECT COUNT(*) AS Items_Sold_2022
FROM GroceryData
WHERE Outlet_Establishment_Year = 2022;


-- Average Rating

SELECT AVG(Rating) AS Avg_Rating
FROM GroceryData;


-- All Together (For Each Categorical Column)

SELECT 
    v.CategoryName,
    v.CategoryValue,
    COUNT(*) AS CountRecords,
    COUNT(DISTINCT [Item_Identifier]) AS UniqueItems,
    SUM(ISNULL([Total_Sales],0)) AS TotalSales,
    AVG(CASE WHEN [Total_Sales] IS NULL THEN NULL ELSE [Total_Sales] END) AS AvgSales,
    AVG(CAST([Rating] AS FLOAT)) AS AvgRating
FROM GroceryData
CROSS APPLY (VALUES
    ('Item_Type', [Item_Type]),
    ('Item_Fat_Content', [Item_Fat_Content]),
    ('Outlet_Type', [Outlet_Type]),
    ('Outlet_Size', [Outlet_Size]),
    ('Outlet_Location_Type', [Outlet_Location_Type]),
    ('Outlet_Identifier', [Outlet_Identifier])
) v(CategoryName, CategoryValue)
GROUP BY v.CategoryName, v.CategoryValue
ORDER BY v.CategoryName, TotalSales DESC;
;WITH Agg AS (
    SELECT 
        v.CategoryName,
        v.CategoryValue,
        COUNT(*) AS CountRecords,
        COUNT(DISTINCT [Item_Identifier]) AS UniqueItems,
        SUM(ISNULL([Total_Sales],0)) AS TotalSales,
        AVG(CASE WHEN [Total_Sales] IS NULL THEN NULL ELSE [Total_Sales] END) AS AvgSales,
        AVG(CAST([Rating] AS FLOAT)) AS AvgRating,
        ROW_NUMBER() OVER (PARTITION BY v.CategoryName ORDER BY SUM(ISNULL([Total_Sales],0)) DESC) AS rn
    FROM GroceryData
    CROSS APPLY (VALUES
        ('Item_Type', [Item_Type]),
        ('Item_Fat_Content', [Item_Fat_Content]),
        ('Outlet_Type', [Outlet_Type]),
        ('Outlet_Size', [Outlet_Size]),
        ('Outlet_Location_Type', [Outlet_Location_Type]),
        ('Outlet_Identifier', [Outlet_Identifier])
    ) v(CategoryName, CategoryValue)
    GROUP BY v.CategoryName, v.CategoryValue
)
SELECT CategoryName, CategoryValue, CountRecords, UniqueItems, TotalSales, AvgSales, AvgRating
FROM Agg
WHERE rn <= 5
ORDER BY CategoryName, TotalSales DESC;
--Get Unique Outlets

SELECT DISTINCT Outlet_Identifier
FROM GroceryData;

--Get Oldest and Newest Outlet

SELECT MIN(Outlet_Establishment_Year) AS OldestOutletYear,
       MAX(Outlet_Establishment_Year) AS NewestOutletYear
FROM GroceryData;


--Item Type Distribution

SELECT Item_Type, COUNT(*) AS CountItems
FROM GroceryData
GROUP BY Item_Type
ORDER BY CountItems DESC;

--Average Rating per Outlet Type
SELECT Outlet_Type, AVG(Rating) AS AvgRating
FROM GroceryData
GROUP BY Outlet_Type
ORDER BY AvgRating DESC;

--Top 5 Items by Total Sales
Select Top 5 Item_Identifier , SUM(Total_Sales) AS TotalSales
FROM GroceryData
GROUP BY Item_Identifier
ORDER BY TotalSales DESC;

--Average Weight per Item Type
Select Item_Type , AVG(Item_Weight) AS AvgWeight
FROM GroceryData
GROUP BY Item_Type
ORDER BY AvgWeight DESC;

--Sales by Outlet Location Type
SELECT Outlet_Location_Type, SUM(Total_Sales) AS TotalSales
FROM GroceryData
GROUP BY Outlet_Location_Type
ORDER BY TotalSales DESC;

--Rating vs Sales Correlation Check
SELECT Rating, AVG(Total_Sales) AS AvgSales
FROM GroceryData
GROUP BY Rating
ORDER BY Rating DESC;

--Most Profitable Item Type per Outlet
SELECT SUM(DISTINCT Total_Sales) AS TOTALSALES,
       Outlet_Identifier,
       Item_Type
FROM GroceryData
GROUP BY Outlet_Identifier, Item_Type
ORDER BY TOTALSALES DESC;

--"هات اسم كل منتج ونوعه مع نوع الـ Outlet اللي اتباع فيه"
SELECT g.Item_Identifier,
       g.Item_Type,
       o.Outlet_Type
FROM GroceryData g
JOIN (
    SELECT DISTINCT Outlet_Identifier, Outlet_Type
    FROM GroceryData
) o
ON g.Outlet_Identifier = o.Outlet_Identifier;

--هات إجمالي المبيعات لكل Outlet مع عدد المنتجات المميزة اللي اتباع فيها
SELECT o.Outlet_Identifier,
       o.Outlet_Type,
       SUM(g.Total_Sales) AS TotalSales,
       COUNT(DISTINCT g.Item_Identifier) AS UniqueItemsSold
FROM GroceryData g
JOIN (
    SELECT DISTINCT Outlet_Identifier, Outlet_Type
    FROM GroceryData
) o
ON g.Outlet_Identifier = o.Outlet_Identifier
GROUP BY o.Outlet_Identifier, o.Outlet_Type
ORDER BY TotalSales DESC;
