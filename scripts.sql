WITH orders AS (
    SELECT
        DATE(OrderDate) AS OrderDate,
        salesorders.SalesOrderID AS SalesOrderId,
        salesorders.CustomerID AS CustomerId,
        salesorders.SalesPersonID AS SalesPersonId,
        salesorders.TerritoryID AS TerritoryId,
        salesordersdetails.productid AS ProductId,
        CASE
            WHEN salesorders.SalesPersonID IS NULL THEN 'Online'
            ELSE 'Offline'
        END AS OnlineFlag,
        ROUND(SUM(TotalDue), 2) AS TotalDue,
        SUM(salesordersdetails.unitprice) AS UnitPrice,
        SUM(salesordersdetails.orderqty) AS Quantity,
        SUM(salesordersdetails.linetotal) AS LineTotal
    FROM `tc-da-1.adwentureworks_db.salesorderheader` AS salesorders
    JOIN `tc-da-1.adwentureworks_db.salesorderdetail` AS salesordersdetails
        ON salesorders.SalesOrderID = salesordersdetails.SalesOrderID
    WHERE DATE(OrderDate) < '2004-06-30'  -- Filter for orders before June 30, 2004
    GROUP BY OrderDate, salesorders.SalesOrderID, salesorders.CustomerID,
             salesorders.SalesPersonID, salesorders.TerritoryID, salesordersdetails.productid
),

products AS (
    SELECT
        Product.ProductID AS ProductId,
        Product_category.name AS ProductCategory,
        product_subcategory.name AS ProductSubcategory,
        Product.StandardCost AS StandardCost,
        Product.ListPrice AS ListPrice
    FROM `tc-da-1.adwentureworks_db.product` AS Product
    LEFT JOIN `tc-da-1.adwentureworks_db.productsubcategory` AS product_subcategory
        ON Product.productsubcategoryid = product_subcategory.productsubcategoryid
    LEFT JOIN `tc-da-1.adwentureworks_db.productcategory` AS Product_category
        ON product_subcategory.productcategoryid = Product_category.productcategoryid
),

salespersons AS (
    SELECT
        salesperson.SalesPersonID AS SalespersonsId,
        CONCAT(contact.Firstname, ' ', contact.LastName) AS SalespersonsName
    FROM `tc-da-1.adwentureworks_db.salesperson` AS salesperson
    JOIN `tc-da-1.adwentureworks_db.employee` AS employee
        ON salesperson.SalesPersonID = employee.EmployeeId
    JOIN `tc-da-1.adwentureworks_db.contact` AS contact
        ON employee.ContactID = contact.ContactId
),

territories AS (
    SELECT
        TerritoryID AS TerritoryId,
        CountryRegionCode
    FROM `tc-da-1.adwentureworks_db.salesterritory`
)

-- Main query to retrieve required fields
SELECT
    orders.OrderDate,
    orders.SalesOrderId,
    orders.OnlineFlag,
    ROUND(MAX(orders.TotalDue), 2) AS TotalDue,
    MAX(salespersons.SalespersonsName) AS SalespersonsName,
    MAX(territories.CountryRegionCode) AS CountryRegionCode,
    ANY_VALUE(products.ProductCategory) AS ProductCategory,
    ANY_VALUE(products.ProductSubcategory) AS ProductSubcategory,
    MAX(orders.LineTotal) AS LineTotal,
    MAX(orders.Quantity) AS Quantity,
    MAX(orders.UnitPrice) AS UnitPrice,
    MAX(products.StandardCost) AS StandardCost,
    MAX(products.ListPrice) AS ListPrice
FROM orders
LEFT JOIN products ON orders.ProductId = products.ProductId
LEFT JOIN salespersons ON orders.SalesPersonId = salespersons.SalespersonsId
LEFT JOIN territories ON orders.TerritoryId = territories.TerritoryId
GROUP BY orders.OrderDate, orders.SalesOrderId, orders.OnlineFlag;
