--Part A
--#1
--2
--2.	Find the products with profit margins as percentage of sales (profits/sales) of at least 15%. 
--    Display the results in descending order of total actual sales.  Round the percentage to two digits using ROUND(….,2) function
SELECT ProdCoffee.ProdName, ROUND(SUM(ActProfit)/SUM(ActSales),2) ProductMargin
FROM FactCoffee
INNER JOIN ProdCoffee
ON ProdCoffee.ProductID = FactCoffee.ProductID
GROUP BY ProdName
HAVING sum(actProfit)/sum(actsales) >=0.15
ORDER BY sum(actSales) DESC;

--3
--	Find AreaIDs where the total profits from leaves in 2012 are two times greater than that from beans.
SELECT * FROM
(SELECT FactCoffee.AreaID, ProdLine, sum(actprofit) as TotProfit
FROM FactCoffee
INNER JOIN ProdCoffee
ON FactCoffee.ProductID = ProdCoffee.ProductID
WHERE extract(year from factdate)=2012
GROUP BY FactCoffee.AREAID, ProdCoffee.ProdLine)
PIVOT
(
SUM(TotProfit)
FOR Prodline in ('Leaves' as Prod_Leaves, 'Beans' as Prod_Beans)
)
WHERE Prod_Leaves >= Prod_Beans * 2.0;
------------------------------------------------------------------------------------------------------------------------------------------------------

--PART B
--#1
--1.	Which are the top 5 area codes with declining profits and how 
--much did the profits decline for these 5 area codes?
SELECT * FROM (
SELECT X12.areaid,
  x12.P2012,
  X13.P2013,
  (X13.P2013 - X12.P2012) ProfitDecline
FROM
  (SELECT Areaid,
    SUM(actprofit) P2012
  FROM factcoffee
  WHERE extract(YEAR FROM factdate) = 2012
  GROUP BY areaid
  ) X12,
  (SELECT Areaid,
    SUM(actprofit) P2013
  FROM factcoffee
  WHERE extract(YEAR FROM factdate) = 2013
  GROUP BY areaid
  ) X13
WHERE x12.areaid = x13.areaid
ORDER BY ProfitDecline)
WHERE ROWNUM <=5;

--2.	Among the five  profit-declining area codes, are the profits consistently declining for all products? 
--If not, identify the products for which they had significantly higher profit decline.
SELECT * FROM
(
SELECT
  x12.ProdName,
  x12.P2012,
  x13.P2013,
  (x13.p2013 - X12.p2012) ProfitDecline
FROM
  (SELECT ProdName, 
    SUM(actprofit) P2012
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON Factcoffee.ProductID = ProdCoffee.ProductID
  WHERE extract(YEAR FROM factdate) = 2012
  AND Areaid IN (845, 508, 626, 712, 631)
  GROUP BY ProdName
  ) X12,
  (SELECT ProdName, 
    SUM(actprofit) P2013
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON Factcoffee.ProductID = ProdCoffee.ProductID
  WHERE extract(YEAR FROM factdate) = 2013
  AND Areaid IN (845, 508, 626, 712, 631)
  GROUP BY ProdName
  ) X13
WHERE x12.ProdName = x13.ProdName
ORDER BY ProfitDecline)
WHERE ROWNUM <=5;
------------------------------------------------------------------------------------------------------------------------------------------------------
--PART C
--1.	All the budgeted numbers are expected targets for 2012 and 2013. 
--Identify the top 5 states for the year 2012 that have substantially higher actual numbers relative to budgeted numbers for profits and sales.
--First we find states with (in this case b/c they're all negative) smallest difference between their actual prodits and budgeted profits
SELECT * FROM (
SELECT X12.Statename,
  x12.BP2012,
  X13.AP2012,
  (X13.AP2012 - X12.BP2012) ProfitDiff
FROM
  (SELECT Statename, 
    SUM(Budprofit) BP2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  GROUP BY Statename
  ) X12,
  (SELECT Statename, 
    SUM(Actprofit) AP2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  GROUP BY Statename
  ) X13
WHERE x12.Statename = x13.Statename
ORDER BY ProfitDiff DESC)
WHERE ROWNUM <=5;


--Now do the same for Sales
SELECT * FROM (
SELECT X12.Statename,
  x12.BS2012,
  X13.AS2012,
  (X13.AS2012 - X12.BS2012) SalesDiff
FROM
  (SELECT Statename, 
    SUM(BudSales) BS2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  GROUP BY Statename
  ) X12,
  (SELECT Statename, 
    SUM(Actsales) AS2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  GROUP BY Statename
  ) X13
WHERE x12.Statename = x13.Statename
ORDER BY SalesDiff DESC)
WHERE ROWNUM <=5;

--Psrt C
--2. 2.	Identify area codes within these 5 states that beat budgeted sales and profits significantly
--(You need to define what significant means here). 
--FIrst, Profits
SELECT * FROM (
SELECT X12.AreaID,
  x12.BP2012,
  X13.AP2012,
  (X13.AP2012 - X12.BP2012) ProfitDiff
FROM
  (SELECT FactCoffee.AreaID, 
    SUM(Budprofit) BP2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  AND StateName IN ('Iowa', 'Massachusetts', 'Louisiana', 'Connecticut', 'Florida')
  GROUP BY FactCoffee.AreaID
  ) X12,
  (SELECT FactCoffee.AreaID, 
    SUM(Actprofit) AP2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  AND StateName IN ('Iowa', 'Massachusetts', 'Louisiana', 'Connecticut', 'Florida')
  GROUP BY FactCoffee.AreaID
  ) X13
WHERE x12.AreaID = x13.AreaID
ORDER BY ProfitDiff DESC)
WHERE ROWNUM <=5;

--And now do the same for Sales
SELECT * FROM (
SELECT X12.AreaID,
  x12.BS2012,
  X13.AS2012,
  (X13.AS2012 - X12.BS2012) SalesDiff
FROM
  (SELECT FactCoffee.AreaID, 
    SUM(Budsales) BS2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  AND StateName IN ('Iowa', 'Nevada', 'New York', 'California', 'Oregon')
  GROUP BY FactCoffee.AreaID
  ) X12,
  (SELECT FactCoffee.AreaID, 
    SUM(Actsales) AS2012
  FROM factcoffee
  INNER JOIN Areacode
  ON Factcoffee.AreaID = Areacode.AreaID
  INNER JOIN States
  ON Areacode.stateid = States.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  AND StateName IN ('Iowa', 'Nevada', 'New York', 'California', 'Oregon')
  GROUP BY FactCoffee.AreaID
  ) X13
WHERE x12.AreaID = x13.AreaID
ORDER BY SalesDiff DESC)
WHERE ROWNUM <=15;
------------------------------------------------------------------------------------------------------------------------------------------------------
--Part D
--1.	In each market, which products have the greatest increase in profits? 
SELECT * FROM (
SELECT X12.ProdName,
  x12.P2012,
  X13.P2013,
  (X13.P2013 - X12.P2012) ProfitIncrease
FROM
  (SELECT ProdCoffee.ProdName,
    SUM(actprofit) P2012
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON factcoffee.ProductID = ProdCoffee.PRODUCTID
  INNER JOIN AreaCode
  ON AreaCode.AreaID = FactCoffee.AreaID
  INNER JOIN States
  ON States.StateID = AreaCode.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  AND States.StateMkt = 'West'
  GROUP BY ProdName
  ) X12,
  (SELECT ProdCoffee.ProdName,
    SUM(actprofit) P2013
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON factcoffee.ProductID = ProdCoffee.PRODUCTID
  INNER JOIN AreaCode
  ON AreaCode.AreaID = FactCoffee.AreaID
  INNER JOIN States
  ON States.StateID = AreaCode.StateID
  WHERE extract(YEAR FROM factdate) = 2013
  AND States.StateMkt = 'West'
  GROUP BY ProdName
  ) X13
WHERE x12.ProdName = x13.ProdName
ORDER BY ProfitIncrease DESC)
WHERE ROWNUM <=5;

--Part D
--2.	In each market, which product types have greatest increase in sales? 
SELECT * FROM (
SELECT X12.ProdType,
  x12.S2012,
  X13.S2013,
  (X13.S2013 - X12.S2012) SalesIncrease
FROM
  (SELECT ProdCoffee.ProdType,
    SUM(actsales) S2012
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON factcoffee.ProductID = ProdCoffee.PRODUCTID
  INNER JOIN AreaCode
  ON AreaCode.AreaID = FactCoffee.AreaID
  INNER JOIN States
  ON States.StateID = AreaCode.StateID
  WHERE extract(YEAR FROM factdate) = 2012
  AND States.StateMkt = 'West'
  GROUP BY ProdType
  ) X12,
  (SELECT ProdCoffee.ProdType,
    SUM(actsales) S2013
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON factcoffee.ProductID = ProdCoffee.PRODUCTID
  INNER JOIN AreaCode
  ON AreaCode.AreaID = FactCoffee.AreaID
  INNER JOIN States
  ON States.StateID = AreaCode.StateID
  WHERE extract(YEAR FROM factdate) = 2013
  AND States.StateMkt = 'West'
  GROUP BY ProdType
  ) X13
WHERE x12.ProdType = x13.ProdType
ORDER BY SalesIncrease DESC)
WHERE ROWNUM <=5;

--Part D
--3.	Have all products within the product types show similar behavior, 
--or some products within a product type have greatest increase in sales?

--Not worried about market anymore, just looking at the different Product Types
SELECT * FROM (
SELECT X12.ProdName,
  x12.S2012,
  X13.S2013,
  (X13.S2013 - X12.S2012) SalesIncrease
FROM
  (SELECT ProdCoffee.ProdName,
    SUM(actsales) S2012
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON factcoffee.ProductID = ProdCoffee.PRODUCTID
  WHERE extract(YEAR FROM factdate) = 2012
  AND ProdCoffee.ProdType = 'Tea'
  GROUP BY ProdName
  ) X12,
  (SELECT ProdCoffee.ProdName,
    SUM(actsales) S2013
  FROM factcoffee
  INNER JOIN ProdCoffee
  ON factcoffee.ProductID = ProdCoffee.PRODUCTID
  WHERE extract(YEAR FROM factdate) = 2013
  AND ProdCoffee.ProdType = 'Tea'
  GROUP BY ProdName
  ) X13
WHERE x12.ProdName = x13.ProdName
ORDER BY SalesIncrease DESC)
WHERE ROWNUM <=5;
-----------------------------------------------------------------------------------------------------------------------------------

--Part E
--1.Which top 5 states have the lowest market expenses as a percentage of their sales?  
SELECT States.StateName,ROUND((SUM(ActMarkCost)/SUM(ActSales))*100,2) MarkCostPercofSales
FROM FactCoffee
INNER JOIN Areacode
ON FactCoffee.AreaID = Areacode.AreaID
INNER JOIN States
ON States.StateID = Areacode.StateID
GROUP BY StateName
ORDER BY MarkCostPercofSales;

--Part E
--2.	Do the above 5 states also have the highest profits as a percentage of sales?
SELECT States.StateName,ROUND((SUM(ActProfit)/SUM(ActSales))*100,2) ProfPercofSales
FROM FactCoffee
INNER JOIN Areacode
ON FactCoffee.AreaID = Areacode.AreaID
INNER JOIN States
ON States.StateID = Areacode.StateID
GROUP BY StateName
ORDER BY ProfPercofSales DESC;

--Part E
--3.	Are there any particular product(s) within these markets with the least marketing expenses? 
SELECT ProdCoffee.ProdName, SUM(ActMarkCost) MarkExp
FROM FactCoffee
INNER JOIN ProdCoffee
ON FactCoffee.ProductID = ProdCoffee.ProductID
INNER JOIN Areacode
ON FactCoffee.AreaID = Areacode.AreaID
INNER JOIN States
ON States.StateID = Areacode.StateID
WHERE States.StateName = 'Colorado'
GROUP BY ProdName
ORDER BY MarkExp;
--------------------------------------------------------------------------------------------------------------------
--Part F
--1.	Which 5 states have the highest marketing expenses as a percentage of sales?
--    Are these marketing expenses justified? (Note: you need to think how you will justify high marketing expenses)?

SELECT States.StateName,ROUND((SUM(ActMarkCost)/SUM(ActSales))*100,2) MarkCostPercofSales
FROM FactCoffee
INNER JOIN Areacode
ON FactCoffee.AreaID = Areacode.AreaID
INNER JOIN States
ON States.StateID = Areacode.StateID
GROUP BY StateName
ORDER BY MarkCostPercofSales DESC;

--as percent of profits now
SELECT States.StateName,ROUND((SUM(ActMarkCost)/SUM(ActProfit))*100,2) MarkCostPercofProfit
FROM FactCoffee
INNER JOIN Areacode
ON FactCoffee.AreaID = Areacode.AreaID
INNER JOIN States
ON States.StateID = Areacode.StateID
GROUP BY StateName
ORDER BY MarkCostPercofProfit;

