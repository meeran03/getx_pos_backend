CREATE TABLE [User]
(
    id INTEGER PRIMARY KEY,
    username varchar(50),
    email varchar(100) NOT NULL UNIQUE (email),
    password varchar(255),
    firstname varchar(50),
    lastname varchar(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)


CREATE TABLE Currency (
    id INTEGER PRIMARY KEY,
    country VARCHAR(100),
    currency VARCHAR(100),
    code VARCHAR(25),
    symbol VARCHAR(25),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE Permission
(
    id INTEGER PRIMARY KEY,
    name varchar(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)

CREATE TABLE Role
(
    id INTEGER PRIMARY KEY,
    name varchar(30),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)

CREATE TABLE RolePermission
(
    id INTEGER PRIMARY KEY,
    role_id INTEGER FOREIGN KEY REFERENCES Role(id),
    permission_id INTEGER FOREIGN KEY REFERENCES  Permission(id),
)



ALTER TABLE [User] ADD role_id INTEGER FOREIGN KEY REFERENCES Role(id) NOT NULL;


CREATE TABLE Category (
    id INT PRIMARY KEY,
    name varchar(50),
);

CREATE TABLE Contact (
    id INT PRIMARY KEY,
    name varchar(50),
    email varchar(50),
    phone varchar(50),
    address varchar(50),
    type varchar(8) NOT NULL CHECK (type IN ('customer', 'supplier' )),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE Unit (
    id INT PRIMARY KEY,
    name varchar(50),
);

CREATE TABLE TaxRate (
    id INT PRIMARY KEY,
    name varchar(50),
    rate decimal(10,2),
);

CREATE TABLE PRODUCT (
    id INT PRIMARY KEY,
    name varchar(50),
    description varchar(255),
    image varchar(255),
    category_id INT,
    unit_id INT,
    tax_id INT,
    sku varchar(50),
    type varchar(50) CHECK (type IN ('single', 'variable')),
    FOREIGN KEY (category_id) REFERENCES Category(id),
    FOREIGN KEY (unit_id) REFERENCES Unit(id),
    FOREIGN KEY (tax_id) REFERENCES TaxRate(id),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
);



CREATE TABLE ProductVariation (
    id INT PRIMARY KEY,
    product_id INT NOT NULL,
    name varchar(50),
    default_purchase_price INT,
    dpp_inc_tax INT,
    profit_percentage INT,
    default_sell_price INT,
    quantity INT NOT NULL CHECK (quantity > 0),
    dsp_inc_tax INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES PRODUCT(id),
);

CREATE TABLE Discount (
    id INT PRIMARY KEY,
    name varchar(50),
    percentage Decimal(10,2),
    active BIT DEFAULT 1,
);

CREATE TABLE [Transaction] (
    id INTEGER PRIMARY KEY,
    type VARCHAR(50) NOT NULL CHECK (type IN ('purchase', 'sell')),
    -- payment_status VARCHAR(50) NOT NULL CHECK (payment_status IN ('paid', 'due','partial')),
    contact_id INTEGER NOT NULL,
    invoice_no VARCHAR(50) NOT NULL,
    transaction_date DATETIME NOT NULL,
    total_before_tax DECIMAL(22, 4) NOT NULL,
    -- tax_id INTEGER NOT NULL,
    -- tax_amount DECIMAL(22, 4) NOT NULL,
    discount_id INTEGER FOREIGN KEY REFERENCES Discount(id),
    discount_amount DECIMAL(22, 4) NOT NULL,
    final_total DECIMAL(22, 4) NOT NULL,
    updated_at DATETIME NOT NULL,
	tax_id int,
    FOREIGN KEY (contact_id) REFERENCES Contact (id) ON DELETE CASCADE,
    FOREIGN KEY (tax_id) REFERENCES TaxRate (id) ON DELETE CASCADE,
);

CREATE TABLE PurchaseLines (
    id INTEGER PRIMARY KEY,
    transaction_id INTEGER NOT NULL FOREIGN KEY REFERENCES [Transaction](id),
    variation_id INTEGER FOREIGN KEY REFERENCES ProductVariation(id),
    quantity DECIMAL(22, 4),
    purchase_price DECIMAL(22, 4),
    purchase_price_inc_tax DECIMAL(22, 4) DEFAULT 0,
) 


CREATE TABLE SellLines (
    id INTEGER PRIMARY KEY,
    transaction_id INTEGER FOREIGN KEY REFERENCES [Transaction](id),
    product_id INTEGER FOREIGN KEY REFERENCES Product(id),
    variation_id INTEGER FOREIGN KEY REFERENCES ProductVariation(id),
    quantity DECIMAL(22, 4),
    sell_price DECIMAL(22, 4),
    sell_price_inc_tax DECIMAL(22, 4) DEFAULT 0,
    item_tax DECIMAL(22, 4),
    tax_id INTEGER FOREIGN KEY REFERENCES TaxRate(id),
);


-- subject to change */

--1
-- Get the best selling products
CREATE VIEW [dbo].[BestSellingProducts]
AS
    Select Top 5 p.name, SUM(sl.quantity) as total_quantity
    from [dbo].[PRODUCT] p
    inner join [dbo].[SellLines] sl on sl.product_id = p.id
    group by p.name
    order by total_quantity desc


--2
-- Get all the products that are out of stock
CREATE VIEW [dbo].[OutOfStockProducts]
AS
    Select * from [dbo].[PRODUCT] p
    inner join [dbo].[ProductVariation] pv on pv.product_id = p.id
    where pv.quantity <= 0


--3
-- check which type of user with its email
CREATE VIEW [dbo].[UserType]
AS
    Select u.email, u.role_id, r.name as role_name
    from [dbo].[User] u
    inner join [dbo].[Role] r on r.id = u.role_id


--4
-- Get the products with similar name or sku or category 
CREATE PROCEDURE [dbo].[GetSimilarProducts]
    @query varchar(50)
AS
BEGIN
    Select * from [dbo].[PRODUCT] p
    inner join Category c on c.id = p.category_id
    where p.name COLLATE UTF8_GENERAL_CI like '%' + @query + '%'
    where p.name COLLATE UTF8_GENERAL_CI like '%' + @query + '%'
    or c.name COLLATE UTF8_GENERAL_CI like '%' + @query + '%'
END


--5
-- Get all the customers with similar name or email or phone
CREATE PROCEDURE [dbo].[GetCustomers]
    @query varchar(50)
AS
BEGIN
    Select * from [dbo].[Contact] c
    where c.name like '%' + @query + '%'
    or c.email like '%' + @query + '%'
    or c.phone like '%' + @query + '%'
    and c.type = 'customer'
END


--6
-- Get all the suppliers with similar name or email or phone
CREATE PROCEDURE [dbo].[GetSuppliers]
    @query varchar(50)
AS
BEGIN
    Select * from [dbo].[Contact] c
    where c.name like '%' + @query + '%'
    or c.email like '%' + @query + '%'
    or c.phone like '%' + @query + '%'
    and c.type = 'supplier'
END


--7
-- Get all the products of a category
CREATE PROCEDURE [dbo].[GetProductsByCategory]
    @category_id int
AS
BEGIN
    Select * from [dbo].[PRODUCT] p
    where p.category_id = @category_id
END

--8
-- Get all the products of a supplier
CREATE PROCEDURE [dbo].[GetProductsBySupplier]
    @supplier_id int
AS
BEGIN
    Select p.name, t.transaction_date,pl.purchase_price,pl.quantity from [Transaction] t 
    inner Join Contact c on c.id = t.contact_id
    inner join [dbo].[PurchaseLines] pl on pl.transaction_id = t.id
    inner join [dbo].[ProductVariation] p on p.id = pl.variation_id
END

-- 9
-- Get top buyer customer
CREATE PROCEDURE [dbo].[GetTopBuyerCustomers]
AS
BEGIN
    Select Top 5 c.name, SUM(sl.quantity) as total_quantity
    from [dbo].[Contact] c
    inner join [dbo].[SellLines] sl on sl.contact_id = c.id
    group by c.name
    order by total_quantity desc
END


--10
-- Get all transactions between two dates
CREATE PROCEDURE [dbo].[GetTransactionsWithDate]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select * from [dbo].[Transaction] t
    where t.transaction_date between @start_date and @end_date
END

--11
-- Get all purchases by a supplier
CREATE PROCEDURE [dbo].[GetPurchasesBySupplier]
    @supplier_id int
AS
BEGIN
    Select * from [dbo].[Transaction] t
    where t.contact_id = @supplier_id
    and t.type = 'purchase'
END

--12
-- Get total sales between two dates
CREATE PROCEDURE [dbo].[GetTotalSales]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select SUM(t.final_total) as total_sales
    from [dbo].[Transaction] t
    where t.transaction_date between @start_date and @end_date
    and t.type = 'sell'
END

--13
-- get the profit on a specific transaction
CREATE PROCEDURE [dbo].[GetTransactionProfit]
    @transaction_id int
AS
BEGIN
    Select t.final_total - t.sub_total as profit
    from [dbo].[Transaction] t
    where t.id = @transaction_id
END

--14
-- Get all the transactions of a customer
CREATE PROCEDURE [dbo].[GetTransactionsByCustomer]
    @customer_id int
AS
BEGIN
    Select * from [dbo].[Transaction] t
    where t.contact_id = @customer_id
END

--15
-- get total tax collected between two dates
CREATE PROCEDURE [dbo].[GetTotalTaxCollected]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select SUM(t.tax_amount) as total_tax
    from [dbo].[Transaction] t
    where t.transaction_date between @start_date and @end_date
    and t.type = 'sell'
END

--16
-- get discounted amount between two dates
CREATE PROCEDURE [dbo].[GetTotalDiscount]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select SUM(t.discount_amount) as total_discount
    from [dbo].[Transaction] t
    where t.transaction_date between @start_date and @end_date
    and t.type = 'sell'
END


--17
-- get total quantity of a product sold between two dates
CREATE PROCEDURE [dbo].[GetTotalQuantitySold]
    @start_date DATETIME, @end_date DATETIME, @product_id int
AS
BEGIN
    Select SUM(sl.quantity) as total_quantity
    from [dbo].[Transaction] t
    inner join [dbo].[SellLines] sl on sl.transaction_id = t.id
    where t.transaction_date between @start_date and @end_date
    and sl.product_id = @product_id
END

--18
-- LOGIN a user with its email and password
CREATE PROCEDURE [dbo].[Login]
    @email varchar(50), @password varchar(50)
AS
BEGIN
    Select * from [dbo].[User] u
    where u.email = @email
    and u.password = @password
END


--19
-- register a new user
CREATE PROCEDURE [dbo].[Register]
    @name varchar(50), @email varchar(50), @password varchar(50), @role_id int
AS
BEGIN
    Insert into [dbo].[User] (name, email, password, role_id)
    values (@name, @email, @password, @role_id)
END

--20
-- change the password of a user
CREATE PROCEDURE [dbo].[ChangePassword]
    @user_id int, @password varchar(50)
AS
BEGIN
    Update [dbo].[User]
    set password = @password
    where id = @user_id
END

--21
-- get all the variable products
CREATE PROCEDURE [dbo].[GetVariableProducts]
AS
BEGIN
    Select * from [dbo].[Product] p
    where p.type = 'variable'
END

--22
-- get best performing variation of a product
CREATE PROCEDURE [dbo].[GetBestPerformingVariation]
    @product_id int
AS
BEGIN
    Select pv.id, pv.name, pv.product_id, pv.variation_id, pv.sub_sku, pv.price_inc_tax, pv.profit, pv.quantity, pv.alert_quantity
    from [dbo].[ProductVariation] pv
    where pv.product_id = @product_id
    order by pv.profit desc
END

--23
-- get all the products of a category
CREATE PROCEDURE [dbo].[GetProductsByCategory]
    @category_id int
AS
BEGIN
    Select * from [dbo].[Product] p
    where p.category_id = @category_id
END

--24
-- tax report
CREATE PROCEDURE [dbo].[GetTaxReport]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select t.name, SUM(t.tax_amount) as total_tax
    from [dbo].[Transaction] t
    where t.transaction_date between @start_date and @end_date
    and t.type = 'sell'
    group by t.name
END

--25
-- get sales by discount type
CREATE PROCEDURE [dbo].[GetSalesByDiscount]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select d.name, SUM(t.discount_amount) as total_discount
    from [dbo].[Transaction] t
    inner join [dbo].[Discount] d on d.id = t.discount_id
    where t.transaction_date between @start_date and @end_date
    and t.type = 'sell'
    group by d.name
END

--26
-- trigger to update stock quantity of a variation
CREATE TRIGGER [dbo].[UpdateProductVariationQuantity]
    ON [dbo].[Transaction]
    AFTER INSERT
AS
BEGIN
    DECLARE @product_variation_id int, @quantity int, @transaction_type varchar(50)
    SET @product_variation_id = (Select product_variation_id from inserted)
    SET @quantity = (Select SUM(quantity) from inserted)
    SET @transaction_type = (Select type from inserted)
    IF @transaction_type = 'sell'
    BEGIN
        UPDATE [dbo].[ProductVariation]
        set quantity = quantity - @quantity
        where id = @product_variation_id
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProductVariation]
        set quantity = quantity + @quantity
        where id = @product_variation_id
    END
END

-- only allow admin role to add or delete products
CREATE TRIGGER [dbo].[CheckProductRole]
    ON [dbo].[Product]
    AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @user_id int, @role_id int
    SET @user_id = (Select user_id from inserted)
    SET @role_id = (Select role_id from [dbo].[User] where id = @user_id)
    IF @role_id <> 1
    BEGIN
        RAISERROR('Only admin role can add or delete products', 16, 1)
        ROLLBACK TRANSACTION
    END
END

-- only allow admin to add or delete categories
CREATE TRIGGER [dbo].[CheckCategoryRole]
    ON [dbo].[Category]
    AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @user_id int, @role_id int
    SET @user_id = (Select user_id from inserted)
    SET @role_id = (Select role_id from [dbo].[User] where id = @user_id)
    IF @role_id <> 1
    BEGIN
        RAISERROR('Only admin role can add or delete categories', 16, 1)
        ROLLBACK TRANSACTION
    END
END

-- get best performing category based on no of sales
CREATE PROCEDURE [dbo].[GetBestPerformingCategory]
AS
BEGIN
    Select c.id, c.name as category_name, SUM(t.total_amount) as total_sales from [dbo].[Transaction] t
    inner join [dbo].[SellLines] sl on sl.transaction_id = t.id
    inner join [dbo].[ProductVariation] pv on pv.id = sl.product_variation_id
    inner join [dbo].[Product] p on p.id = pv.product_id
    inner join [dbo].[Category] c on c.id = p.category_id
    where t.type = 'sell'
    group by c.id, c.name
    order by total_sales desc
END

-- get last month sales
CREATE PROCEDURE [dbo].[GetLastMonthSales]
AS
BEGIN
    Select SUM(t.total_amount) as total_sales from [dbo].[Transaction] t
    where t.transaction_date between DATEADD(month, -1, GETDATE()) and GETDATE()
    and t.type = 'sell'
END

-- get current month sales
CREATE PROCEDURE [dbo].[GetCurrentMonthSales]
AS
BEGIN
    Select SUM(t.total_amount) as total_sales from [dbo].[Transaction] t
    where t.transaction_date between DATEADD(month, 0, GETDATE()) and GETDATE()
    and t.type = 'sell'
END

-- get current month profit
CREATE PROCEDURE [dbo].[GetCurrentMonthProfit]
AS
BEGIN
    Select SUM(t.profit) as total_profit from [dbo].[Transaction] t
    where t.transaction_date between DATEADD(month, 0, GETDATE()) and GETDATE()
    and t.type = 'sell'
END

-- get current year sales
CREATE PROCEDURE [dbo].[GetCurrentYearSales]
AS
BEGIN
    Select SUM(t.total_amount) as total_sales from [dbo].[Transaction] t
    where t.transaction_date between DATEADD(year, 0, GETDATE()) and GETDATE()
    and t.type = 'sell'
END

-- get current year profit
CREATE PROCEDURE [dbo].[GetCurrentYearProfit]
AS
BEGIN
    Select SUM( sl. t.profit) as total_profit from [dbo].[Transaction] t
    inner join [dbo].[SellLines] sl on sl.transaction_id = t.id
    where t.transaction_date between DATEADD(year, 0, GETDATE()) and GETDATE()
    and t.type = 'sell'
END
-- get recent products based on recent transactions dates and sales
CREATE PROCEDURE [dbo].[GetRecentProducts]
AS
BEGIN
    Select p.id,p.name,SUM(*) as total_sales from [dbo].[Product] p
    inner join [dbo].[SellLines] sl on sl.product_id = p.id
    inner join [dbo].[Transaction] t on t.id = sl.transaction_id
    where t.transaction_date between DATEADD(month, -1, GETDATE()) and GETDATE()
    and t.type = 'sell'
    group by p.id,p.name
    order by t.transaction_date desc
END


-- calculate average purchase price of a product variation using purchase lines
CREATE PROCEDURE [dbo].[GetAveragePurchasePrice]
    @product_variation_id int
AS
BEGIN
   
    inner join [dbo].[ProductVariation] pv on pv.id = p.product_variation_id
    where pv.id = @product_variation_id
END

-- a trigger that updates the default purchase price of a product variation whenver its entry
-- is added in a sellline
CREATE TRIGGER [dbo].[UpdateProductVariationPurchasePrice]
    ON [dbo].[PurchaseLines]
    AFTER INSERT
AS
BEGIN
    DECLARE @product_variation_id int, @purchase_price decimal(18,2)
    SET @product_variation_id = (Select variation_id from inserted)
    SET @purchase_price = (Select AVG(p.purchase_price) from [dbo].[PurchaseLines] p where p.variation_id = @product_variation_id)
    UPDATE [dbo].[ProductVariation]
    set default_purchase_price = @purchase_price
    where id = @product_variation_id
END


-- get best selling product variations
CREATE PROCEDURE [dbo].[GetBestSellingProductVariations]
AS
BEGIN
    Select TOP 50 pv.id, pv.product_id, pv.name, pv.default_purchase_price, pv.default_retail_price, pv.quantity, pv.alert_quantity, pv.image, pv.description, pv.barcode, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.default_sell_price, pv.sell_price_updated_at, pv.default_purchase_price, pv.purchase_price_updated_at, pv.stock_updated_at, pv.stock, pv.product_updated_at, pv.created_at, pv.updated_at, pv.deleted_at, pv.deleted_by, pv.created_by, pv.updated_by, pv.product_id, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.sell_price_updated_at, pv.purchase_price_updated_at, pv.stock_updated_at, pv.product_updated_at, pv.created_at, pv.updated_at, pv.deleted_at, pv.deleted_by, pv.created_by, pv.updated_by, pv.product_id, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.sell_price_updated_at, pv.purchase_price_updated_at, pv.stock_updated_at, pv.product_updated_at, pv.created_at, pv.updated_at, pv.deleted_at, pv.deleted_by, pv.created_by, pv.updated_by, pv.product_id, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.sell_price_updated_at, pv.purchase_price_updated_at, pv.stock_updated_at, pv
    from [dbo].[ProductVariation] pv
    inner join [dbo].[SellLines] sl on sl.product_variation_id = pv.id
    group by pv.id, pv.product_id, pv.name, pv.default_purchase_price, pv.default_retail_price, pv.quantity, pv.alert_quantity, pv.image, pv.description, pv.barcode, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.default_sell_price, pv.sell_price_updated_at, pv.default_purchase_price, pv.purchase_price_updated_at, pv.stock_updated_at, pv.stock, pv.product_updated_at, pv.created_at, pv.updated_at, pv.deleted_at, pv.deleted_by, pv.created_by, pv.updated_by, pv.product_id, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.sell_price_updated_at, pv.purchase_price_updated_at, pv.stock_updated_at, pv.product_updated_at, pv.created_at, pv.updated_at, pv.deleted_at, pv.deleted_by, pv.created_by, pv.updated_by, pv.product_id, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.sell_price_updated_at, pv.purchase_price_updated_at, pv.stock_updated_at, pv.product_updated_at, pv.created_at, pv.updated_at, pv.deleted_at, pv.deleted_by, pv.created_by, pv.updated_by, pv.product_id, pv.sub_category_id, pv.brand_id, pv.tax_id, pv.sell_price_updated_at, pv.purchase_price_updated_at, pv.stock_updated_at, pv.product
    order by SUM(sl.quantity) desc
END