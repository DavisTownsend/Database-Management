------Assignment 3 Queries-----------
--Part A------------------------------

--1.	Extract the total sales for each product for each month. 
--List all months (like January, February, etc) in the columns.
SELECT * FROM (
SELECT ProdName, FactDate, SUM(ActSales)
FROM ProdCoffee
INNER JOIN FactCoffee
ON ProdCoffee.ProductID = FactCoffee.ProductID
GROUP BY ProdName, FactDate)
Pivot (
SUM(ActSales)
FOR FactDate IN (2013 Min, 2013 Max))
;
select FactDate FROM FactCoffee;

SELECT * FROM (
SELECT P.prodname, S.statemkt, sum(F.actsales) sumsales
FROM prodcoffee P, factcoffee F, states S, areacode A
WHERE P.productid = F.productid AND S.stateid = A.stateid AND    A.areaid = F.areaid
GROUP BY P.prodname, S.statemkt)
Pivot (
    Sum(sumsales)
    FOR statemkt IN ('West', 'Central', 'East', 'South')
    );
----
--2.	In each state, identify the product with greatest sales for the year 2012.
SELECT * FROM (
SELECT factcoffee.productid prod,  prodname pname,  statename state,
    SUM(actsales) Sumsales,
    ROW_NUMBER() OVER (PARTITION BY statename ORDER BY SUM(ACTSALES) DESC) AS RANKID 
  FROM factcoffee,   prodcoffee,  states,  areacode
  WHERE factcoffee.productid     = prodcoffee.productid
  AND areacode.AREAID            = factcoffee.AREAID
  AND states.STATEID             = areacode.stateid
  AND extract(YEAR FROM factdate)=2012
  GROUP BY factcoffee.productid,  prodname, statename)
WHERE rankid = 1;

--i.	Identify the states where the best selling product remained the same in 2013 (compared to best selling product in 2012)
SELECT DISTINCT State FROM
(
SELECT * FROM (
SELECT factcoffee.productid prod,  prodname pname,  statename state,
    SUM(actsales) Sumsales,
    ROW_NUMBER() OVER (PARTITION BY statename ORDER BY SUM(ACTSALES) DESC) AS RANKID 
  FROM factcoffee,   prodcoffee,  states,  areacode
  WHERE factcoffee.productid     = prodcoffee.productid
  AND areacode.AREAID            = factcoffee.AREAID
  AND states.STATEID             = areacode.stateid
  AND extract(YEAR FROM factdate)=2012
  GROUP BY factcoffee.productid,  prodname, statename)
WHERE rankid = 1
MINUS
SELECT * FROM (
SELECT factcoffee.productid prod,  prodname pname,  statename state,
    SUM(actsales) Sumsales,
    ROW_NUMBER() OVER (PARTITION BY statename ORDER BY SUM(ACTSALES) DESC) AS RANKID 
  FROM factcoffee,   prodcoffee,  states,  areacode
  WHERE factcoffee.productid     = prodcoffee.productid
  AND areacode.AREAID            = factcoffee.AREAID
  AND states.STATEID             = areacode.stateid
  AND extract(YEAR FROM factdate)=2013
  GROUP BY factcoffee.productid,  prodname, statename)
WHERE rankid = 1
);
--ii.	Identify the states where the best selling product has changed. 
--iii.	Identify the products that were best in 2012 but not in 2013.

SELECT * FROM (
SELECT factcoffee.productid prod,  prodname pname,
    SUM(actsales) Sumsales,
    ROW_NUMBER() OVER (ORDER BY SUM(actsales) DESC) AS RANKID 
  FROM factcoffee,   prodcoffee
  WHERE factcoffee.productid     = prodcoffee.productid
  AND extract(YEAR FROM factdate)=2012
  GROUP BY factcoffee.productid,  prodname)
  WHERE RANKID IN (1, 2, 3, 4, 5)
  ORDER BY Sumsales DESC
;

SELECT * FROM (
SELECT factcoffee.productid prod,  prodname pname,
    SUM(actsales) Sumsales,
    ROW_NUMBER() OVER (ORDER BY SUM(actsales) DESC) AS RANKID 
  FROM factcoffee,   prodcoffee
  WHERE factcoffee.productid     = prodcoffee.productid
  AND extract(YEAR FROM factdate)=2013
  GROUP BY factcoffee.productid,  prodname)
  WHERE RANKID IN (1, 2, 3, 4, 5)
  ORDER BY Sumsales DESC
;

--iv.	Identify the top two best selling products that are common to both 2012 and 2013.

-------------------------------------------------------------------------------
--3.	What fraction of the top selling states contributes to at least 50% of the total sales?
--    Do they also contribute to 50% of the profit share as well?
--    (Please note that you won’t likely get exact 50% when you do your analysis)

--Sales Run
With Cumsale as (SELECT Statename, SUM(actsales) Sumsales, Row_number() OVER (ORDER BY sum(actsales) DESC) Rowsales
FROM factcoffee
INNER JOIN Areacode ON Factcoffee.areaid = areacode.areaid
INNER JOIN States On areacode.stateid = states.stateid
GROUP BY Statename),

totalcount AS (
SELECT count(*) as totcount
FROM Cumsale),

totsales as (SELECT sum(sumsales) totsumsales FROM cumsale),

Cumtotsales as (SELECT rowsales, sum(sumsales) over (order by rowsales) Csales
                    FROM cumsale)

SELECT totcount, totsumsales, rowsales, csales, (rowsales/totcount) as statepercentageSales
FROM totalcount, totsales, cumtotsales
WHERE csales >= 0.5*totsumsales AND rownum =1;

--Profits Run
With Cumprofit as (SELECT Statename, SUM(actprofit) Sumprofit, Row_number() OVER (ORDER BY sum(actprofit) DESC) Rowprofit
FROM factcoffee
INNER JOIN Areacode ON Factcoffee.areaid = areacode.areaid
INNER JOIN States On areacode.stateid = states.stateid
GROUP BY Statename),

totalcount AS (
SELECT count(*) as totcount
FROM Cumprofit),

totprofit as (SELECT sum(sumprofit) totsumprofit FROM cumprofit),

Cumtotprofit as (SELECT rowprofit, sum(sumprofit) over (order by rowprofit) Cprofit
                    FROM cumprofit)

SELECT totcount, totsumprofit, rowprofit, cprofit, (rowprofit/totcount) as statepercentageProfit
FROM totalcount, totprofit, cumtotprofit
WHERE cprofit >= 0.5*totsumprofit AND rownum =1;

--------------------------------------------------------------------------------
--4.	Identify the area codes with greatest decline in profits from the year 2012 to 2013. 
--List the profits for 2012 and 2013 in the columns and display the percentage decline.
SELECT * FROM (
SELECT X12.areaid,
  x12.P2012,
  X13.P2013,
  ROUND(((X13.p2013 - X12.p2012)/x12.p2012)*100,2) ProfitDiffPercent

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
--have to remove these area codes due to how the answers come out given the
--multiplication of a negative number
AND x12.areaid NOT IN (818, 212, 914, 909)
ORDER BY ProfitDiffPercent)
WHERE ROWNUM <=5;

---------------------------------------------------------------------------
--5.	If you have to discontinue some product, which one would you suggest and why?
SELECT * FROM (
SELECT X12.prodname,
  x12.P2012,
  X13.P2013,
  ROUND(((X13.p2013 - X12.p2012)/x12.p2012)*100,2) ProfitDiffPercent

FROM
  (SELECT Prodname,
SUM(actprofit) P2012
FROM factcoffee
INNER JOIN ProdCoffee
ON ProdCoffee.ProductID = FactCoffee.ProductID
  WHERE extract(YEAR FROM factdate) = 2012
  GROUP BY ProdName
  ) X12,

  (SELECT Prodname,
SUM(actprofit) P2013
FROM factcoffee
INNER JOIN ProdCoffee
ON ProdCoffee.ProductID = FactCoffee.ProductID
  WHERE extract(YEAR FROM factdate) = 2013
  GROUP BY ProdName
  ) X13
WHERE x12.prodname = x13.prodname
ORDER BY ProfitDiffPercent)
WHERE ROWNUM <=5;

--
--6.	Where should the marketing expenses be increased and reduced? 
--I will look at which products have the highest and lowest percent of marketing expenses
--as a percentage of profit
-------------------------
SELECT ProdCoffee.ProdName,ROUND((SUM(ActMarkCost)/SUM(ActProfit))*100,2) MarkCostPercofProfit  
FROM FactCoffee  
INNER JOIN ProdCoffee 
ON FactCoffee.ProductID = ProdCoffee.ProductID  
GROUP BY ProdName  
ORDER BY MarkCostPercofProfit;  

--------------------------------------------------------------------------
--The overall sales per month could be seasonal.  That is, 
--you will find greater sales in some months than others and this may be consistent with 2012 and 2013. 
--Identify if there are seasonal trends. Plot month vs. sales for each year.

SELECT extract(Month from FactDate) Month, SUM(actsales)
FROM FactCoffee
WHERE extract(Year from FactDate) = 2012
GROUP BY extract(Month from FactDate)
ORDER BY Month
;

SELECT extract(Month from FactDate) Month, SUM(actsales)
FROM FactCoffee
WHERE extract(Year from FactDate) = 2013
GROUP BY extract(Month from FactDate)
ORDER BY Month
;
------------------------------------------------------------------
--Product 

SELECT ProdName, extract(Month from FactDate) Month, SUM(actsales)
FROM FactCoffee
INNER JOIN ProdCoffee
ON Prodcoffee.ProductID = FActCoffee.productID
WHERE extract(Year from FactDate) = 2012
GROUP BY ProdName, extract(Month from FactDate)
ORDER BY ProdName, Month
;

-----------------------------------------------------------------
--Product
SELECT StateName, ProdName, extract(Month from FactDate) Month, SUM(actsales)
FROM FactCoffee
INNER JOIN ProdCoffee
ON Prodcoffee.ProductID = FActCoffee.productID
INNER JOIN Areacode
ON Areacode.AreaID = FactCoffee.AreaID
INNER JOIN States
ON States.stateid = areacode.stateid
WHERE extract(Year from FactDate) = 2012
GROUP BY StateName, ProdName, extract(Month from FactDate)
ORDER BY StateName, ProdName, Month
;

-----------------------------------------------------------------------------
--8.	Insert a new column into Factcoffee table called Quarter. 
ALTER TABLE Factcoffee 
ADD 
(Quarter VARCHAR2(30));
--ALTER TABLE Factcoffee 
--drop column Quarter;

-- Now depending on the month, update the quarter number as Q1, Q2, Q3, or Q4 for each row. 
UPDATE Factcoffee
SET Quarter = 'Q1'
WHERE extract(Month from FactDate) IN (1, 2, 3);
UPDATE Factcoffee
SET Quarter = 'Q2'
WHERE extract(Month from FactDate) IN (4, 5, 6);
UPDATE Factcoffee
SET Quarter = 'Q3'
WHERE extract(Month from FactDate) IN (7, 8, 9);
UPDATE Factcoffee
SET Quarter = 'Q4'
WHERE extract(Month from FactDate) IN (10, 11, 12);

select * FROM Factcoffee;
--i.	Now find the total sales for years 2012 and 2013 for each quarter. Display quarter in columns.
SELECT * FROM
(
(SELECT extract(YEar FROM FactDate) Year, Quarter, SUM(Actsales) TotalSales
FROM FactCoffee
GROUP BY extract(YEar FROM FactDate), Quarter)
PIVOT
(SUM(TotalSales) FOR (Quarter) In ('Q1', 'Q2', 'Q3', 'Q4'))
)
;
--ii.	Which quarter has the greatest sales and profits? 
--From last problem we see that Q3 has greatest sales
SELECT * FROM
(
(SELECT extract(YEar FROM FactDate) Year, Quarter, SUM(Actprofit) TotalProfit
FROM FactCoffee
GROUP BY extract(YEar FROM FactDate), Quarter)
PIVOT
(SUM(TotalProfit) FOR (Quarter) In ('Q1', 'Q2', 'Q3', 'Q4'))
)
;
--Now for profits: We see that again Q3 has greatest profits

-------------------------------------------------------------------------------
--9.	CREATE a TABLE that captures for each state, product, and quarter combination, 
--    the following measures - the total sales, total profits, percentage margin, 
--    total marketing expenses, and rank order of sales for each quarter.  
--    You may use many different queries to INSERT or UPDATE using a single query or union of many different queries.  
SELECT StateName, ProdName, Quarter, SUM(actsales) TotSales
FROM FactCoffee
INNER JOIN ProdCoffee
ON Prodcoffee.ProductID = FActCoffee.productID
INNER JOIN Areacode
ON Areacode.AreaID = FactCoffee.AreaID
INNER JOIN States
ON States.stateid = areacode.stateid
WHERE extract(Year from FactDate) = 2012
GROUP BY StateName, ProdName, Quarter
ORDER BY StateName, ProdName, Quarter
;
----------------------------------------------------------------
DROP TABLE FactQuarter;
--create statement
CREATE Table FactQuarter (
StateName  varchar(15),
ProdName   varchar(20),
Quarter    varchar(5),
TotSales  number,
TotProfit  number,
PercMargin  number,
SalesRank    Number
);
SELECT * FROM FactQuarter;

--Begin inserting data in by filling out state, prod, and quarter columns
INSERT INTO FactQuarter (StateName, ProdName, Quarter, TotSales)
SELECT StateName, ProdName, Quarter, TotSales
FROM
(SELECT StateName, ProdName, Quarter, SUM(actsales) TotSales
FROM FactCoffee
INNER JOIN ProdCoffee
ON Prodcoffee.ProductID = FActCoffee.productID
INNER JOIN Areacode
ON Areacode.AreaID = FactCoffee.AreaID
INNER JOIN States
ON States.stateid = areacode.stateid
WHERE extract(Year from FactDate) = 2012
GROUP BY StateName, ProdName, Quarter
ORDER BY StateName, ProdName, Quarter
);
--Now insert Total Profit
INSERT INTO FactQuarter (TotProfit)
SELECT TotProfit
FROM
(
SELECT StateName, ProdName, Quarter, SUM(actProfit) TotProfit
FROM FactCoffee
INNER JOIN ProdCoffee
ON Prodcoffee.ProductID = FActCoffee.productID
INNER JOIN Areacode
ON Areacode.AreaID = FactCoffee.AreaID
INNER JOIN States
ON States.stateid = areacode.stateid
WHERE extract(Year from FactDate) = 2012
GROUP BY StateName, ProdName, Quarter
ORDER BY StateName, ProdName, Quarter
) prof
WHERE prof.StateName = FactQuarter.STATENAME
AND prof.ProdName = FactQuarter.ProdNAme
AND prof.Quarter = FactQuarter.Quarter
;
select * from FactQuarter;

--------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--PART B

--1.	Rank managers based on the sales generated.
  
SELECT * FROM (
SELECT Managers.RegManager, SUM(OrdSales) TotalSales,
ROW_NUMBER() OVER (Order BY SUM(Ordsales) DESC) AS RANKID
FROM Managers
INNER JOIN Customers
ON Managers.RegID = Customers.CustReg
INNER JOIN OrderDet
ON Customers.CustID = OrderDet.CustID
GROUP BY RegManager);

--
--2.	Find the products that had the worst average shipping times.
SELECT ProdName, AVG(OrdShipDate - OrdDate) AVGSHipTIme,
ROW_NUMBER() OVER(ORDER BY (AVG(OrdShipDate - OrdDate)) DESC) AS RANKID
FROM Products
INNER JOIN OrderDet
ON Products.ProdID = OrderDet.ProdID
GROUP BY ProdName
;

--3.	What fraction of the revenues is generated from the top 10% of the customers?

With Cumsale as (SELECT Customers.CustID, SUM(OrdSales) Sumsales, Row_number() OVER (ORDER BY sum(OrdSales) DESC) Rowsales
FROM Customers
INNER JOIN OrderDET
ON Customers.CustID = ORderDet.CustID
GROUP BY Customers.CustID),

totalcount AS (
SELECT count(*) as totcount
FROM Cumsale),

totsales as (SELECT sum(sumsales) totsumsales FROM cumsale),

Cumtotsales as (SELECT rowsales, sum(sumsales) over (order by rowsales) Csales
                    FROM cumsale)

SELECT totcount, totsumsales, rowsales, csales, rowsales/totcount
FROM totalcount, totsales, cumtotsales
WHERE csales >= 0.9*totsumsales AND rownum =1;

--4.	List the number of orders, number of returns, total sales and any other metric for each year.
--    List the years or measures in the columns.
--finds number of orders and total sales per year
SELECT extract(Year FROM ORdDate) Year, COUNT(Orderdet.OrderID) NumOrders, SUM(Orderdet.OrdSales) TotSales
FROM ORderDet
INNER JOIN Orders
ON Orderdet.OrderID = Orders.OrderID
GROUP BY extract(Year FROM ORdDate)
ORDER BY Year;

--THis finds returned orders by year
SELECT Year, SUM(Ord)as TotORd
FROM
(
SELECT extract(Year FROM OrderDet.OrdDate) Year, Orders.OrderID, COUNT(Orders.OrderID) Ord
FROM Orders
INNER JOIN ORderDet
ON OrderDet.ORderID = Orders.ORderID
WHERE Status = 'Returned'
GROUP BY extract(Year FROM OrderDet.OrdDate), Orders.OrderID
)
GROUP BY Year;

--------------------------------------------------------------------------------
--5.	For each city and product combination, list the total sales and rank order in each city by total sales. 
SELECT ProdName, CustCity, SUM(OrdSales) TotSales, Row_number() OVER (PARTITION BY CustCIty ORDER BY sum(OrdSales) DESC) AS RANKID
FROM Products
INNER JOIN ORderDet
ON OrderDet.PRodID = Products.ProdID
INNER JOIN Customers
ON OrderDet.CustID = Customers.CustID
GROUP BY ProdNAme, CustCity;

--------------------------------------------------------------------------------
--6.	Which are the top 5 customers for each of the years?
--    which customers brought in the most Revenues
SELECT (Customer) FROM
(
SELECT extract(Year from OrdDate) Year, CustName Customer, SUM(OrdSales) TotSales, 
ROW_number() OVER(PARTITION BY extract(Year from OrdDate) Order By sum(OrdSales) DESC) AS RANKID
FROM OrderDet
INNER JOIN Customers
ON Orderdet.custid = customers.custid
GROUP BY extract(Year from OrdDate), CustName
)
WHERE RANKID IN (1, 2, 3, 4, 5);

--------------------------------------------------------------------------------
--7.	Find the number of orders in each subcategory in states Michigan and Washington. 
--    List Washington and Michigan in different columns.
SELECT * FROM
(
SELECT ProdSubCat, Customers.CustState, COUNT(OrderDet.OrderID) NumOrders
FROM Products
INNER JOIN OrderDet
ON Products.ProdID = OrderDet.ProdID
INNER JOIN Customers
ON Customers.CustID = OrderDet.CustID
WHERE Customers.CustState In ('Michigan', 'Washington')
GROUP BY ProdSubCat, CustState
)
PIVOT
(SUM(NumOrders) FOR CustState IN ('Michigan', 'Washington'))
;
----------------------------------------------------------------------------------
--8.	Find total orders in each quarter.

--first I'll add a quarter column to OrderDet table
ALTER TABLE OrderDet
ADD 
(Quarter VARCHAR2(30));
--ALTER TABLE Factcoffee 
--drop column Quarter;

-- Now depending on the month, update the quarter number as Q1, Q2, Q3, or Q4 for each row. 
UPDATE OrderDet
SET Quarter = 'Q1'
WHERE extract(Month from OrdDate) IN (1, 2, 3);
UPDATE OrderDet
SET Quarter = 'Q2'
WHERE extract(Month from OrdDate) IN (4, 5, 6);
UPDATE OrderDet
SET Quarter = 'Q3'
WHERE extract(Month from OrdDate) IN (7, 8, 9);
UPDATE OrderDet
SET Quarter = 'Q4'
WHERE extract(Month from OrdDate) IN (10, 11, 12);

SELECT * FROM OrderDet;
--Now find total orders per quarter
SELECT Quarter, COUNT(OrderID) totOrders
FROM ORderDET
GROUP BY Quarter
ORDER BY QUARTER
;
---------------------------------------------------------------------------------
--9.	For each quarter and customer segment, find the total sales. 
--    Display data for quarters in column.	
SELECT * FROM
(SELECT Custseg, Quarter, SUM(OrdSales) TotSales
FROM Customers
INNER JOIN ORderDet
On ORderdet.CustID = Customers.CustID
GROUP BY CUstSeg, Quarter
ORDER BY TotSales DESC)
PIVOT
(SUM(TotSales) FOR Quarter In ('Q1', 'Q2', 'Q3', 'Q4'))
;