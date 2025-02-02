create database OmniBiz

--Import the dataset

--check out the tables
select *
from OmniBiz..Sales


--CLEANING THE SALES TABLE

--Step 1: Removing the  "-"
select CustomerName, REPLACE(CustomerName, '-', ' ' )
from OmniBiz..Sales
where CustomerName like '%-%'

update OmniBiz..Sales
set CustomerName = REPLACE(CustomerName, '-', ' ' )
where CustomerName like '%-%'


--Step 2: Removing titles like Dr., Engr. etc and making a new column for them
select CustomerName, 
case
	when CustomerName like 'Pastor%' then 'Pastor' 
	when CustomerName like 'Chief%' then 'Chief' 
	when CustomerName like 'Engr%' then 'Engr' 
	when CustomerName like 'Mrs%' then 'Mrs' 
	when CustomerName like 'Mr%' then 'Mr' 
	when CustomerName like 'Ms%' then 'Ms'  
	else 'default'
	end Title
from OmniBiz..Sales
where CustomerName LIKE '%.%'

alter table OmniBiz..Sales
add Title nvarchar(max)

update OmniBiz..Sales
set Title = case
	when CustomerName like 'Pastor%' then 'Pastor' 
	when CustomerName like 'Chief%' then 'Chief' 
	when CustomerName like 'Engr%' then 'Engr' 
	when CustomerName like 'Mrs%' then 'Mrs' 
	when CustomerName like 'Mr%' then 'Mr' 
	when CustomerName like 'Ms%' then 'Ms'  
	else 'default' -- Make those without titles default
	end
--Removing the titles to make the Names more visible
select CustomerName, TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Mr.', ''), 'Mr', ''), 'Mrs', ''))
from OmniBiz..Sales
where CustomerName like 'Mr%'

select CustomerName, TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Engr.', ''), 'Engr', ''), 'Ms.', ''))
from OmniBiz..Sales
where CustomerName like 'Engr%' or CustomerName like 'Ms.%'

select CustomerName, TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Pastor.', ''), 'Pastor', ''), 'Chief', ''))
from OmniBiz..Sales
where CustomerName like 'Pastor%' or CustomerName like 'Chief%'

select CustomerName, TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Prof.', ''), 'Dr.', ''), 'Dr ', ''))
from OmniBiz..Sales
where CustomerName like 'Prof%' or CustomerName like 'Dr%'

update OmniBiz..Sales
set CustomerName = TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Mr. ', ' '), 'Mr ', ''), 'Mrs ', ''))
where CustomerName like 'Mr%'

update OmniBiz..Sales
set CustomerName = TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Engr.', ''), 'Engr', ''), 'Ms.', ''))
where CustomerName like 'Engr%' or CustomerName like 'Ms.%'

update OmniBiz..Sales
set CustomerName = TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Pastor.', ''), 'Pastor', ''), 'Chief', ''))
where CustomerName like 'Pastor%' or CustomerName like 'Chief%'

update OmniBiz..Sales
set CustomerName = TRIM(REPLACE(REPLACE(REPLACE(CustomerName, 'Prof.', ''), 'Dr.', ''), 'Dr ', ''))
where CustomerName like 'Prof%' or CustomerName like 'Dr%'


--Step 3: Removing the empty whitespaces
--Some names have more than one whitespace, checking for 2 or more spaces
select CustomerName
from OmniBiz..Sales
where CustomerName like '%  %'
--Creating a function to remove more than one whitespace
CREATE FUNCTION dbo.RemoveExtraSpaces 
(@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    SET @input = TRIM(@input);    -- Remove leading and trailing spaces
    WHILE CHARINDEX('  ', @input) > 0    -- Replace multiple spaces with a single space
    BEGIN
        SET @input = REPLACE(@input, '  ', ' ');
    END
    RETURN @input;
END;
GO
--Checking it out
with CTE as(
SELECT CustomerName OriginalName, dbo.RemoveExtraSpaces(CustomerName) AS CleanedName
FROM Sales
)
select CleanedName
from CTE
where CleanedName like '%  %'
--Update the changes
update OmniBiz..Sales
set CustomerName = dbo.RemoveExtraSpaces(CustomerName)


--Step 4: Removing the numbers present
--Checking for numbers
select CustomerName
from OmniBiz..Sales
where CustomerName LIKE '%[0-9]%'
--Creating a function to remove the numbers
CREATE FUNCTION dbo.RemoveNumbers 
(@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @output NVARCHAR(MAX) = '';
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@input);
    DECLARE @char NCHAR(1);

    WHILE @i <= @len
    BEGIN
        SET @char = SUBSTRING(@input, @i, 1);
        IF @char NOT LIKE '[0-9]'
        BEGIN
            SET @output = @output + @char;
        END
        SET @i = @i + 1;
    END

    RETURN @output;
END;
GO
--Checking it out
with RemoveNumberCTE as(
SELECT 
    CustomerName AS OriginalName,
    dbo.RemoveNumbers(CustomerName) AS CleanedName
FROM 
    Sales)
	select CleanedName
	from RemoveNumberCTE
	where CleanedName LIKE '%[0-9]%'
--Updating the changes
update OmniBiz..Sales
set CustomerName = dbo.RemoveNumbers(CustomerName)


--Step 5: Normalizing the Customer Names
--Selecting only the first and last names
select CustomerName, 
UPPER(LEFT(CustomerName, CHARINDEX(' ', CustomerName + ' ') - 1)) FirstName,
UPPER(REVERSE(LEFT(REVERSE(CustomerName), CHARINDEX(' ', REVERSE(CustomerName) + ' ') - 1))) LastName
from OmniBiz..Sales
where CustomerName like '%.%'
--Adding the first and last name columns
alter table Sales
add FirstName nvarchar(255),
	LastName nvarchar(255)
--Updating the added columns
update Sales
set FirstName = UPPER(LEFT(CustomerName, CHARINDEX(' ', CustomerName + ' ') - 1)),
	LastName = UPPER(REVERSE(LEFT(REVERSE(CustomerName), CHARINDEX(' ', REVERSE(CustomerName) + ' ') - 1)))


--Step 6: Checking for duplicates
SELECT FirstName, LastName, OrderDate, OrderNumber, ProductNumber, SalesEmployeeID, COUNT(*)
FROM Sales
GROUP BY FirstName, LastName, OrderDate, OrderNumber, ProductNumber, SalesEmployeeID
HAVING COUNT(*) > 1


--QUESTION 1:Describe the total sales amount and quantity sold for each product category in the Sales table, 
--along with the corresponding sales employee's first name, last name, and total sales commission earned. 
--Include only those product categories where the total sales amount exceeds 100,000.
--Assuming the employee gets a 5% commission per Sale
select first_name, c.ProductCategory , last_name, Quantity, TotalSold, TotalSold * 0.05 as Commission
from Sales a
join Employee b
on a.SalesEmployeeID = b.employee_id
join Category c
on a.ProductNumber = c.ProductNumber
where TotalSold > 100000

--QUESTION 2: Identify the top 3 employees based on the total amount of sales they've generated. 
--List their first name, last name, total sales amount, and commission percentage. 
--Exclude any employees who haven't made any sales.
--Calculating  commission for each Employee per Sale
select first_name, last_name, Quantity, TotalSold, TotalSold * 0.05 as Commission, 
sum(TotalSold *0.05) over (partition by first_name, Last_name) TotalCommission
from Sales a
join Employee b
on a.SalesEmployeeID = b.employee_id
where TotalSold > 100000
--Total Commisions for each employee
select first_name, last_name,  --TotalSold, Sum(TotalSold) TotalCompanySales,
sum(TotalSold ) TotalEmployeeSales, 
(sum(TotalSold)/(select sum(TotalSold) from Sales))*100 'Commission%'
from Sales a
join Employee b
on a.SalesEmployeeID = b.employee_id
where TotalSold > 0
group by first_name, last_name
order by [Commission%] desc

alter table Sales
add Commission float
--Adding the commisions
update Sales
set Commission = TotalSold *0.05

--QUESTION 3:Find the top 5 customers who have spent the most money on purchases. 
--List their customer names, email addresses, total amount spent, and the number of orders they've placed. 
--Include only customers who have placed at least 2 orders.
with BuyerCTE as(
select CustomerName, Email, 
Sum(TotalSold) TotalBought, count(orderNumber) NumOfOrders
from Sales
group by CustomerName, Email
)
select top 5 *
from BuyerCTE
where NumOfOrders > 1
order by TotalBought desc

--QUESTION 4: Analyze the distribution of sales orders across different order sources. 
--Calculate the percentage of total sales represented by each order source. 
--Display the order source, total sales amount, and the percentage of total sales for each source. 
--Exclude any order sources that contribute less than 5% to the total sales amount.
with OrderSourceCTE as(
select OrderSource, Sum(TotalSold) OrderSourceSales, 
(Sum(TotalSold)/(select Sum(TotalSold) from Sales))*100 'TotalSale%'
from Sales
group by OrderSource
)
select *
from OrderSourceCTE
where [TotalSale%] > 5

