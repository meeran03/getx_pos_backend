USE [Getx]
GO
/****** Object:  Table [dbo].[PRODUCT]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PRODUCT](
	[id] [int] NOT NULL,
	[name] [varchar](50) NULL,
	[description] [varchar](255) NULL,
	[image] [varchar](255) NULL,
	[category_id] [int] NULL,
	[unit_id] [int] NULL,
	[type] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[updated_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SellLines]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SellLines](
	[id] [int] NOT NULL,
	[transaction_id] [int] NULL,
	[product_id] [int] NULL,
	[variation_id] [int] NULL,
	[quantity] [decimal](22, 4) NULL,
	[sell_price] [decimal](22, 4) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[BestSellingProducts]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[BestSellingProducts]
AS
    Select Top 5 p.name, SUM(sl.quantity) as total_quantity
    from [dbo].[PRODUCT] p
    inner join [dbo].[SellLines] sl on sl.product_id = p.id
    group by p.name
    order by total_quantity desc
GO
/****** Object:  Table [dbo].[ProductVariation]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductVariation](
	[id] [int] NOT NULL,
	[product_id] [int] NOT NULL,
	[name] [varchar](50) NULL,
	[default_purchase_price] [int] NULL,
	[default_sell_price] [int] NULL,
	[quantity] [int] NOT NULL,
	[created_at] [datetime] NULL,
	[updated_at] [datetime] NULL,
	[sku] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[OutOfStockProducts]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[OutOfStockProducts]
AS
    Select p.* from [dbo].[PRODUCT] p
    inner join [dbo].[ProductVariation] pv on pv.product_id = p.id
    where pv.quantity <= 0
GO
/****** Object:  Table [dbo].[Contact]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Contact](
	[id] [int] NOT NULL,
	[name] [varchar](50) NULL,
	[email] [varchar](50) NULL,
	[phone] [varchar](50) NULL,
	[address] [varchar](50) NULL,
	[type] [varchar](8) NOT NULL,
	[created_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Transaction]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transaction](
	[id] [int] NOT NULL,
	[type] [varchar](50) NOT NULL,
	[contact_id] [int] NOT NULL,
	[invoice_no] [varchar](50) NOT NULL,
	[transaction_date] [datetime] NOT NULL,
	[discount_id] [int] NULL,
	[discount_amount] [int] NULL,
	[final_total] [decimal](22, 4) NOT NULL,
	[updated_at] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[GetTopBuyerCustomers]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[GetTopBuyerCustomers]
AS
    Select Top 5 c.name,c.id, SUM(sl.quantity) as total_quantity
    from [dbo].[Contact] c
	inner join [Transaction] t
	on t.contact_id =c.id
    inner join [dbo].[SellLines] sl
	on sl.transaction_id = t.id
	where c.type = 'customer'
    group by c.name,c.id
    order by total_quantity desc
GO
/****** Object:  View [dbo].[GetBestPerformingProducts]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[GetBestPerformingProducts]
AS
    Select TOP 5 p.id,p.name, SUM(sl.quantity) as total_quantity
    from [dbo].[Product] p
    inner join ProductVariation pv on pv.product_id = p.id
    inner join [dbo].[SellLines] sl on sl.variation_id = pv.id
    group by p.name,p.id
    order by total_quantity desc
GO
/****** Object:  View [dbo].[GetCurrentMonthSales]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[GetCurrentMonthSales]
AS
    Select SUM(t.final_total) as total_sales,Count(*) as total_sales_count from [dbo].[Transaction] t
    where t.transaction_date >= datefromparts(year(getdate()), month(getdate()), 1)
    and t.type = 'sell'
GO
/****** Object:  View [dbo].[PreviousMonthSales]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[PreviousMonthSales]
AS
    Select SUM(t.final_total) as total_sales,Count(*) as total_sales_count from [dbo].[Transaction] t
    where t.transaction_date >= dateadd(month, -1, datefromparts(year(getdate()), month(getdate()), 1))
    and t.transaction_date < datefromparts(year(getdate()), month(getdate()), 1)
    and t.type = 'sell'
GO
/****** Object:  View [dbo].[CurrentMonthCustomers]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[CurrentMonthCustomers]
AS
	Select Count(*) as customer_count from Contact c where c.type = 'customer'
	and c.created_at >= datefromparts(year(getdate()), month(getdate()), 1)
GO
/****** Object:  View [dbo].[PreviousMonthCustomers]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[PreviousMonthCustomers]
AS
	Select Count(*) as customer_count from Contact c where c.type = 'customer'
	and c.created_at >= dateadd(month, -1, datefromparts(year(getdate()), month(getdate()), 1))
    and c.created_at < datefromparts(year(getdate()), month(getdate()), 1)
GO
/****** Object:  Table [dbo].[Category]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Category](
	[id] [int] NOT NULL,
	[name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Currency]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Currency](
	[id] [int] NOT NULL,
	[country] [varchar](100) NULL,
	[currency] [varchar](100) NULL,
	[code] [varchar](25) NULL,
	[symbol] [varchar](25) NULL,
	[created_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Discount]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Discount](
	[id] [int] NOT NULL,
	[name] [varchar](50) NULL,
	[percentage] [decimal](10, 2) NULL,
	[active] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Permission]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Permission](
	[id] [int] NOT NULL,
	[name] [varchar](50) NULL,
	[created_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PurchaseLines]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PurchaseLines](
	[id] [int] NOT NULL,
	[transaction_id] [int] NOT NULL,
	[variation_id] [int] NULL,
	[quantity] [decimal](22, 4) NULL,
	[purchase_price] [decimal](22, 4) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role](
	[id] [int] NOT NULL,
	[name] [varchar](30) NULL,
	[created_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RolePermission]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RolePermission](
	[id] [int] NOT NULL,
	[role_id] [int] NULL,
	[permission_id] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Unit]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Unit](
	[id] [int] NOT NULL,
	[name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[User]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[User](
	[id] [int] NOT NULL,
	[username] [varchar](50) NULL,
	[email] [varchar](100) NOT NULL,
	[password] [varchar](255) NULL,
	[firstname] [varchar](50) NULL,
	[lastname] [varchar](50) NULL,
	[created_at] [datetime] NULL,
	[role_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [dbo].[Category] ([id], [name]) VALUES (1, N'Kids Wear')
INSERT [dbo].[Category] ([id], [name]) VALUES (2, N'Lentils')
GO
INSERT [dbo].[Contact] ([id], [name], [email], [phone], [address], [type], [created_at]) VALUES (1, N'Walk In Customer', N'', N'', N'', N'customer', CAST(N'2022-05-29T03:15:26.070' AS DateTime))
INSERT [dbo].[Contact] ([id], [name], [email], [phone], [address], [type], [created_at]) VALUES (2, N'Cloudagri', N'cloud.agri@mail.com', N'03005122287', N'Model Town, Lahore', N'supplier', CAST(N'2022-05-28T05:00:36.533' AS DateTime))
INSERT [dbo].[Contact] ([id], [name], [email], [phone], [address], [type], [created_at]) VALUES (3, N'SUBHAN ENTERPRISES', N'subhanmachinery@gmail.com', N'03044791344', N'Johar Town', N'customer', CAST(N'2022-05-26T19:41:25.467' AS DateTime))
INSERT [dbo].[Contact] ([id], [name], [email], [phone], [address], [type], [created_at]) VALUES (4, N'Abdullah Industries', N'abd@gmail.com', N'03000000000', N'Samanabad', N'supplier', CAST(N'2022-05-30T13:34:12.200' AS DateTime))
GO
INSERT [dbo].[Discount] ([id], [name], [percentage], [active]) VALUES (1, N'Special Summer', CAST(40.00 AS Decimal(10, 2)), 1)
INSERT [dbo].[Discount] ([id], [name], [percentage], [active]) VALUES (2, N'New Arrival', CAST(50.00 AS Decimal(10, 2)), 1)
GO
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (1, N'product.add', CAST(N'2022-05-26T21:54:20.560' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (2, N'product.delete', CAST(N'2022-05-26T21:54:29.143' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (3, N'product.edit', CAST(N'2022-05-26T21:54:38.363' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (4, N'user.add', CAST(N'2022-05-26T21:54:46.287' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (5, N'user.edit', CAST(N'2022-05-26T21:54:53.877' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (6, N'sale.add', CAST(N'2022-05-26T21:55:09.187' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (7, N'sale.delete', CAST(N'2022-05-26T21:55:18.353' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (8, N'sale.edit', CAST(N'2022-05-26T21:55:23.620' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (9, N'supplier.add', CAST(N'2022-05-26T21:55:31.520' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (10, N'supplier.edit', CAST(N'2022-05-26T21:55:38.557' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (11, N'supplier.delete', CAST(N'2022-05-26T21:55:46.207' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (12, N'customer.add', CAST(N'2022-05-26T21:55:56.033' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (13, N'customer.delete', CAST(N'2022-05-26T21:56:00.690' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (14, N'customer.edit', CAST(N'2022-05-26T21:56:05.533' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (15, N'unit.add', CAST(N'2022-05-26T21:56:44.647' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (16, N'unit.delete', CAST(N'2022-05-26T21:56:51.203' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (17, N'unit.update', CAST(N'2022-05-26T21:56:56.710' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (18, N'currency.add', CAST(N'2022-05-26T21:57:03.017' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (19, N'currency.delete', CAST(N'2022-05-26T21:57:09.357' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (20, N'currency.edit', CAST(N'2022-05-26T21:57:14.433' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (21, N'po.add', CAST(N'2022-05-26T21:57:47.660' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (22, N'po.delete', CAST(N'2022-05-26T21:57:52.147' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (23, N'po.edit', CAST(N'2022-05-26T21:57:56.140' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (24, N'so.add', CAST(N'2022-05-26T21:58:04.770' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (25, N'so.delete', CAST(N'2022-05-26T21:58:09.990' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (26, N'so.edit', CAST(N'2022-05-26T21:58:16.557' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (27, N'category.add', CAST(N'2022-05-26T21:58:51.127' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (28, N'category.delete', CAST(N'2022-05-26T21:58:57.907' AS DateTime))
INSERT [dbo].[Permission] ([id], [name], [created_at]) VALUES (29, N'category.edit', CAST(N'2022-05-26T21:59:10.257' AS DateTime))
GO
INSERT [dbo].[PRODUCT] ([id], [name], [description], [image], [category_id], [unit_id], [type], [created_at], [updated_at]) VALUES (1, N'Agro Fertilizer', N'This is great Fertilizer', N'628af7e5-2fc4-4530-bc99-f7e6e988a5e1-1653701713041.jpeg', 2, 1, N'variable', CAST(N'2022-05-28T06:35:13.073' AS DateTime), CAST(N'2022-05-28T06:35:13.073' AS DateTime))
INSERT [dbo].[PRODUCT] ([id], [name], [description], [image], [category_id], [unit_id], [type], [created_at], [updated_at]) VALUES (2, N'Dal Maash', N'This is Daal', N'8e6d3113-9fae-4ff3-8013-44c97505003b-1653899499008.jpeg', 2, 1, N'single', CAST(N'2022-05-30T13:31:39.070' AS DateTime), CAST(N'2022-05-30T13:31:39.070' AS DateTime))
GO
INSERT [dbo].[ProductVariation] ([id], [product_id], [name], [default_purchase_price], [default_sell_price], [quantity], [created_at], [updated_at], [sku]) VALUES (1, 1, N'AGRO-1', 1000, 1024, 0, CAST(N'2022-05-28T01:35:13.077' AS DateTime), CAST(N'2022-05-28T01:35:13.077' AS DateTime), N'GETX-A_1')
INSERT [dbo].[ProductVariation] ([id], [product_id], [name], [default_purchase_price], [default_sell_price], [quantity], [created_at], [updated_at], [sku]) VALUES (2, 1, N'AGRO-2', 1050, 1124, 1992, CAST(N'2022-05-28T07:12:23.833' AS DateTime), CAST(N'2022-05-28T07:12:23.833' AS DateTime), N'GETX-A_2')
INSERT [dbo].[ProductVariation] ([id], [product_id], [name], [default_purchase_price], [default_sell_price], [quantity], [created_at], [updated_at], [sku]) VALUES (3, 2, N'Maash-1', 90, 100, 985, CAST(N'2022-05-30T08:31:39.077' AS DateTime), CAST(N'2022-05-30T08:31:39.077' AS DateTime), N'GETX_MAASH_1')
GO
INSERT [dbo].[PurchaseLines] ([id], [transaction_id], [variation_id], [quantity], [purchase_price]) VALUES (1, 1, 1, CAST(10.0000 AS Decimal(22, 4)), CAST(1000.0000 AS Decimal(22, 4)))
INSERT [dbo].[PurchaseLines] ([id], [transaction_id], [variation_id], [quantity], [purchase_price]) VALUES (2, 7, 2, CAST(1000.0000 AS Decimal(22, 4)), CAST(1100.0000 AS Decimal(22, 4)))
INSERT [dbo].[PurchaseLines] ([id], [transaction_id], [variation_id], [quantity], [purchase_price]) VALUES (3, 9, 2, CAST(1000.0000 AS Decimal(22, 4)), CAST(1000.0000 AS Decimal(22, 4)))
INSERT [dbo].[PurchaseLines] ([id], [transaction_id], [variation_id], [quantity], [purchase_price]) VALUES (4, 10, 3, CAST(1000.0000 AS Decimal(22, 4)), CAST(90.0000 AS Decimal(22, 4)))
GO
INSERT [dbo].[Role] ([id], [name], [created_at]) VALUES (1, N'Admin', CAST(N'2022-04-18T10:48:33.450' AS DateTime))
INSERT [dbo].[Role] ([id], [name], [created_at]) VALUES (2, N'Cashier', CAST(N'2022-04-18T10:57:53.563' AS DateTime))
INSERT [dbo].[Role] ([id], [name], [created_at]) VALUES (3, N'Salesman', CAST(N'2022-05-27T05:06:47.000' AS DateTime))
GO
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (1, 3, 1)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (2, 3, 2)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (3, 3, 4)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (4, 3, 3)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (5, 2, 24)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (6, 2, 25)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (7, 2, 26)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (8, 1, 1)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (9, 1, 2)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (10, 1, 3)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (11, 1, 4)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (12, 1, 29)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (13, 1, 28)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (14, 1, 27)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (15, 1, 26)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (16, 1, 25)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (17, 1, 24)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (18, 1, 23)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (19, 1, 22)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (20, 1, 21)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (21, 1, 20)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (22, 1, 19)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (23, 1, 18)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (24, 1, 17)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (25, 1, 16)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (26, 1, 15)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (27, 1, 14)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (28, 1, 13)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (29, 1, 12)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (30, 1, 11)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (31, 1, 10)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (32, 1, 9)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (33, 1, 8)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (34, 1, 7)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (35, 1, 6)
INSERT [dbo].[RolePermission] ([id], [role_id], [permission_id]) VALUES (36, 1, 5)
GO
INSERT [dbo].[SellLines] ([id], [transaction_id], [product_id], [variation_id], [quantity], [sell_price]) VALUES (1, 2, 1, 1, CAST(4.0000 AS Decimal(22, 4)), CAST(1024.0000 AS Decimal(22, 4)))
INSERT [dbo].[SellLines] ([id], [transaction_id], [product_id], [variation_id], [quantity], [sell_price]) VALUES (2, 3, 1, 1, CAST(2.0000 AS Decimal(22, 4)), CAST(1024.0000 AS Decimal(22, 4)))
INSERT [dbo].[SellLines] ([id], [transaction_id], [product_id], [variation_id], [quantity], [sell_price]) VALUES (3, 4, 1, 1, CAST(1.0000 AS Decimal(22, 4)), CAST(1024.0000 AS Decimal(22, 4)))
INSERT [dbo].[SellLines] ([id], [transaction_id], [product_id], [variation_id], [quantity], [sell_price]) VALUES (4, 5, 1, 1, CAST(2.0000 AS Decimal(22, 4)), CAST(1024.0000 AS Decimal(22, 4)))
INSERT [dbo].[SellLines] ([id], [transaction_id], [product_id], [variation_id], [quantity], [sell_price]) VALUES (5, 6, 1, 1, CAST(1.0000 AS Decimal(22, 4)), CAST(1024.0000 AS Decimal(22, 4)))
INSERT [dbo].[SellLines] ([id], [transaction_id], [product_id], [variation_id], [quantity], [sell_price]) VALUES (6, 8, 1, 2, CAST(8.0000 AS Decimal(22, 4)), CAST(1124.0000 AS Decimal(22, 4)))
INSERT [dbo].[SellLines] ([id], [transaction_id], [product_id], [variation_id], [quantity], [sell_price]) VALUES (7, 11, 2, 3, CAST(15.0000 AS Decimal(22, 4)), CAST(100.0000 AS Decimal(22, 4)))
GO
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (1, N'purchase', 2, N'PO-1', CAST(N'2022-05-29T11:53:19.973' AS DateTime), NULL, NULL, CAST(10000.0000 AS Decimal(22, 4)), CAST(N'2022-05-29T16:53:19.993' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (2, N'sell', 1, N'INV-SELL-1', CAST(N'2022-05-29T11:53:34.183' AS DateTime), NULL, NULL, CAST(4096.0000 AS Decimal(22, 4)), CAST(N'2022-05-29T16:53:34.190' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (3, N'sell', 3, N'INV-SELL-3', CAST(N'2022-05-29T11:54:56.137' AS DateTime), NULL, NULL, CAST(2048.0000 AS Decimal(22, 4)), CAST(N'2022-05-29T16:54:56.170' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (4, N'sell', 1, N'INV-SELL-4', CAST(N'2022-05-29T12:10:06.133' AS DateTime), NULL, NULL, CAST(1024.0000 AS Decimal(22, 4)), CAST(N'2022-05-29T17:10:06.143' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (5, N'sell', 1, N'INV-SELL-5', CAST(N'2022-05-29T12:12:43.263' AS DateTime), NULL, NULL, CAST(2048.0000 AS Decimal(22, 4)), CAST(N'2022-05-29T17:12:43.270' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (6, N'sell', 3, N'INV-SELL-6', CAST(N'2022-05-30T08:23:09.257' AS DateTime), 1, 409, CAST(614.4000 AS Decimal(22, 4)), CAST(N'2022-05-30T13:23:09.267' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (7, N'purchase', 2, N'PO-120', CAST(N'2022-05-30T08:24:49.390' AS DateTime), NULL, NULL, CAST(1100000.0000 AS Decimal(22, 4)), CAST(N'2022-05-30T13:24:49.400' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (8, N'sell', 1, N'INV-SELL-7', CAST(N'2022-05-30T08:25:54.303' AS DateTime), 1, 3596, CAST(5395.2000 AS Decimal(22, 4)), CAST(N'2022-05-30T13:25:54.327' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (9, N'purchase', 2, N'PO-121', CAST(N'2022-05-30T08:27:19.060' AS DateTime), NULL, NULL, CAST(1000000.0000 AS Decimal(22, 4)), CAST(N'2022-05-30T13:27:19.077' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (10, N'purchase', 4, N'PO-122', CAST(N'2022-05-30T08:35:22.283' AS DateTime), NULL, NULL, CAST(90000.0000 AS Decimal(22, 4)), CAST(N'2022-05-30T13:35:22.297' AS DateTime))
INSERT [dbo].[Transaction] ([id], [type], [contact_id], [invoice_no], [transaction_date], [discount_id], [discount_amount], [final_total], [updated_at]) VALUES (11, N'sell', 1, N'INV-SELL-9', CAST(N'2022-05-30T08:36:42.937' AS DateTime), 2, 750, CAST(750.0000 AS Decimal(22, 4)), CAST(N'2022-05-30T13:36:42.943' AS DateTime))
GO
INSERT [dbo].[Unit] ([id], [name]) VALUES (1, N'KG')
INSERT [dbo].[Unit] ([id], [name]) VALUES (2, N'Pound')
INSERT [dbo].[Unit] ([id], [name]) VALUES (3, N'Meters')
GO
INSERT [dbo].[User] ([id], [username], [email], [password], [firstname], [lastname], [created_at], [role_id]) VALUES (1, N'meeran03', N'muhammadmeeran2003@gmail.com', N'$2a$10$1DS/9ItJ2PPEIyhyF2LSh.mIh3ze03EYBXYGQHlkalaTXzntiOuWi', N'Meeran', N'Malik', CAST(N'2022-04-18T11:47:37.317' AS DateTime), 1)
INSERT [dbo].[User] ([id], [username], [email], [password], [firstname], [lastname], [created_at], [role_id]) VALUES (2, N'ayaan123', N'ayaan@gmail.com', N'$2a$10$4fqknmlK66/uKBM8GEnAZeoTeMXtyE5kdxWloMnGJLNM33wPhIK2i', N'Ayaan', N'Malik', CAST(N'2022-05-29T19:55:25.773' AS DateTime), 2)
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__User__AB6E6164308F51DC]    Script Date: 30/05/2022 2:42:46 pm ******/
ALTER TABLE [dbo].[User] ADD UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Contact] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Currency] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[Discount] ADD  DEFAULT ((1)) FOR [active]
GO
ALTER TABLE [dbo].[Permission] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[PRODUCT] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[PRODUCT] ADD  DEFAULT (getdate()) FOR [updated_at]
GO
ALTER TABLE [dbo].[ProductVariation] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[ProductVariation] ADD  DEFAULT (getdate()) FOR [updated_at]
GO
ALTER TABLE [dbo].[Role] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[User] ADD  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[PRODUCT]  WITH CHECK ADD FOREIGN KEY([category_id])
REFERENCES [dbo].[Category] ([id])
GO
ALTER TABLE [dbo].[PRODUCT]  WITH CHECK ADD FOREIGN KEY([unit_id])
REFERENCES [dbo].[Unit] ([id])
GO
ALTER TABLE [dbo].[ProductVariation]  WITH CHECK ADD FOREIGN KEY([product_id])
REFERENCES [dbo].[PRODUCT] ([id])
GO
ALTER TABLE [dbo].[PurchaseLines]  WITH CHECK ADD FOREIGN KEY([transaction_id])
REFERENCES [dbo].[Transaction] ([id])
GO
ALTER TABLE [dbo].[PurchaseLines]  WITH CHECK ADD FOREIGN KEY([variation_id])
REFERENCES [dbo].[ProductVariation] ([id])
GO
ALTER TABLE [dbo].[RolePermission]  WITH CHECK ADD FOREIGN KEY([permission_id])
REFERENCES [dbo].[Permission] ([id])
GO
ALTER TABLE [dbo].[RolePermission]  WITH CHECK ADD  CONSTRAINT [FK__RolePermi__role___30F848ED] FOREIGN KEY([role_id])
REFERENCES [dbo].[Role] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RolePermission] CHECK CONSTRAINT [FK__RolePermi__role___30F848ED]
GO
ALTER TABLE [dbo].[SellLines]  WITH CHECK ADD FOREIGN KEY([product_id])
REFERENCES [dbo].[PRODUCT] ([id])
GO
ALTER TABLE [dbo].[SellLines]  WITH CHECK ADD FOREIGN KEY([transaction_id])
REFERENCES [dbo].[Transaction] ([id])
GO
ALTER TABLE [dbo].[SellLines]  WITH CHECK ADD FOREIGN KEY([variation_id])
REFERENCES [dbo].[ProductVariation] ([id])
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD FOREIGN KEY([contact_id])
REFERENCES [dbo].[Contact] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD FOREIGN KEY([discount_id])
REFERENCES [dbo].[Discount] ([id])
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD FOREIGN KEY([role_id])
REFERENCES [dbo].[Role] ([id])
GO
ALTER TABLE [dbo].[Contact]  WITH CHECK ADD CHECK  (([type]='supplier' OR [type]='customer'))
GO
ALTER TABLE [dbo].[PRODUCT]  WITH CHECK ADD CHECK  (([type]='variable' OR [type]='single'))
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD CHECK  (([type]='sell' OR [type]='purchase'))
GO
/****** Object:  StoredProcedure [dbo].[GetBestSellingProductVariations]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetBestSellingProductVariations]
AS
BEGIN
	Select p.*,pp.image as image from ProductVariation p 
	inner join PRODUCT pp on pp.id = p.product_id
	where p.id in (
		Select TOP 50 pv.id
		from [dbo].[ProductVariation] pv
		inner join [dbo].[SellLines] sl on sl.variation_id = pv.id
		group by pv.id
		order by SUM(sl.quantity) desc
	)
END
GO
/****** Object:  StoredProcedure [dbo].[GetCurrentYearSales]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- get current year sales in money
CREATE PROCEDURE [dbo].[GetCurrentYearSales]
AS
BEGIN
    Select SUM(t.final_total) as total_sales from [dbo].[Transaction] t
    where t.transaction_date between DATEADD(year, 0, GETDATE()) and GETDATE()
    and t.type = 'sell'
END
GO
/****** Object:  StoredProcedure [dbo].[GetCustomers]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCustomers]
    @query varchar(50)
AS
BEGIN
    Select * from [dbo].[Contact] c
    where c.type = 'customer'
	and (LOWER(c.name) like '%' + @query + '%'
    or LOWER(c.email) like '%' + @query + '%'
    or LOWER(c.phone) like '%' + @query + '%' )
END
GO
/****** Object:  StoredProcedure [dbo].[GetProductsByCategory]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Get all the products of a category
CREATE PROCEDURE [dbo].[GetProductsByCategory]
    @category_id int
AS
BEGIN
    Select * from [dbo].[PRODUCT] p
    where p.category_id = @category_id
END
GO
/****** Object:  StoredProcedure [dbo].[GetProductsBySupplier]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetProductsBySupplier]
    @supplier_id int
AS
BEGIN
    Select p.name, t.transaction_date,pl.purchase_price,pl.quantity from [Transaction] t 
    inner Join Contact c on c.id = t.contact_id
    inner join [dbo].[PurchaseLines] pl on pl.transaction_id = t.id
    inner join [dbo].[ProductVariation] p on p.id = pl.variation_id
END
GO
/****** Object:  StoredProcedure [dbo].[GetPurchaseTransactionsWithDate]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPurchaseTransactionsWithDate]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select t.*,c.name as contact_name from [dbo].[Transaction] t
	inner join Contact c on t.contact_id = c.id
    where t.transaction_date between @start_date and @end_date
	and t.type = 'purchase'
END
GO
/****** Object:  StoredProcedure [dbo].[GetRecentProducts]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetRecentProducts]
AS
BEGIN
    Select p.id,p.name,Count(*) as total_sales from [dbo].[Product] p
    inner join [dbo].[SellLines] sl on sl.product_id = p.id
    inner join [dbo].[Transaction] t on t.id = sl.transaction_id
    where t.transaction_date between DATEADD(month, -1, GETDATE()) and GETDATE()
    and t.type = 'sell'
    group by p.id,p.name
END
GO
/****** Object:  StoredProcedure [dbo].[GetSellTransactionsWithDate]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetSellTransactionsWithDate]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select t.*,c.name as contact_name from [dbo].[Transaction] t
	inner join Contact c on t.contact_id = c.id
    where t.transaction_date between @start_date and @end_date
	and t.type = 'sell'
END
GO
/****** Object:  StoredProcedure [dbo].[GetSimilarProducts]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetSimilarProducts]
    @query varchar(50)
AS
BEGIN
    Select * from [dbo].[PRODUCT] p
    inner join Category c on c.id = p.category_id
    where LOWER(p.name) like '%' + @query + '%' 
    or LOWER(c.name) like '%' + @query + '%'
END
GO
/****** Object:  StoredProcedure [dbo].[GetSuppliers]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetSuppliers]
    @query varchar(50)
AS
BEGIN
    Select * from [dbo].[Contact] c
    where c.type = 'supplier'
	and (LOWER(c.name) like '%' + @query + '%'
    or LOWER(c.email) like '%' + @query + '%'
    or LOWER(c.phone) like '%' + @query + '%' )
END
GO
/****** Object:  StoredProcedure [dbo].[GetTransactionsWithDate]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetTransactionsWithDate]
    @start_date DATETIME, @end_date DATETIME
AS
BEGIN
    Select t.*,c.name as contact_name from [dbo].[Transaction] t
	inner join Contact c on t.contact_id = c.id
    where t.transaction_date between @start_date and @end_date
END
GO
/****** Object:  StoredProcedure [dbo].[SEARCHVARIATIONS]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SEARCHVARIATIONS]
    @query varchar(50)
AS
BEGIN
	Select pv.*,c.name as category,p.image as image from ProductVariation pv
	inner join Category c
	on c.id = pv.product_id
	inner join PRODUCT p
	on p.id=pv.product_id
	where LOWER(pv.name) like '%' + @query + '%'
	or 
	LOWER(c.name) like '%' + @query + '%'
END
GO
/****** Object:  Trigger [dbo].[UpdateProductVariationPurchasePrice]    Script Date: 30/05/2022 2:42:46 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [dbo].[PurchaseLines] ENABLE TRIGGER [UpdateProductVariationPurchasePrice]
GO
