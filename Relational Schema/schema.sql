CREATE TABLE Customer (
    CustomerID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    AccountBalance DECIMAL(10, 2)
);

CREATE INDEX idx_customer_email ON Customer(Email);

CREATE TABLE Address (
    AddressID SERIAL PRIMARY KEY,
    ReferenceType VARCHAR(50) NOT NULL, -- 'Customer', 'StaffMember', 'Warehouse', 'Supplier'
    ReferenceID INTEGER NOT NULL,
    Street VARCHAR(255) NOT NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100),
    Zip VARCHAR(20) NOT NULL,
    Country VARCHAR(100) NOT NULL,
    AddressType VARCHAR(50) NOT NULL -- 'Billing', 'Shipping', 'Primary', etc.
   
);
-- Composite index for faster polymorphic lookups
CREATE INDEX idx_address_reference ON Address(ReferenceType, ReferenceID);

CREATE TABLE StaffMember (
    StaffID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL,
    JobTitle VARCHAR(100) NOT NULL
);

CREATE TABLE Warehouse (
    WarehouseID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Size DECIMAL(10, 2) NOT NULL CHECK (Size > 0)
    
);

CREATE TABLE Product (
    ProductID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Size VARCHAR(50),
    Brand VARCHAR(100),
    Price DECIMAL (10,2),
    Category VARCHAR(50),
    ImageURL VARCHAR(255)
);

-- Index on Product Name for faster searches
CREATE INDEX idx_product_name ON Product(Name);
-- Index on CategoryID for faster category filtering
CREATE INDEX idx_product_category ON Product(Category);

CREATE TABLE Stock (
    StockID SERIAL PRIMARY KEY,
    ProductID INTEGER NOT NULL REFERENCES Product(ProductID) ON DELETE CASCADE,
    WarehouseID INTEGER NOT NULL REFERENCES Warehouse(WarehouseID) ON DELETE RESTRICT,
    Quantity INTEGER NOT NULL CHECK (Quantity >= 0),
    
    -- Ensure we don't have duplicate product stocks in the same warehouse
    CONSTRAINT unique_product_warehouse UNIQUE(ProductID, WarehouseID)
);

-- Index on ProductID for faster stock lookups by product
CREATE INDEX idx_stock_product ON Stock(ProductID);
-- Index on WarehouseID for faster stock lookups by warehouse
CREATE INDEX idx_stock_warehouse ON Stock(WarehouseID);

CREATE TABLE CreditCard (
    CardID SERIAL PRIMARY KEY,
    CustomerID INTEGER NOT NULL REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CardNumber VARCHAR(19) NOT NULL, -- like XXXX-XXXX-XXXX-XXXX
    ExpiryDate DATE NOT NULL,
    CVV VARCHAR(3) NOT NULL,
    CardholderName VARCHAR(100) NOT NULL,
    AddressID INTEGER NOT NULL, -- Payment address
    
    -- Check for valid expiry date (must be in the future)
    CONSTRAINT valid_expiry_date CHECK (ExpiryDate > CURRENT_DATE),
    
    -- Foreign key constraint for payment address
    CONSTRAINT fk_credit_card_address FOREIGN KEY (AddressID) REFERENCES Address(AddressID)
   
);

CREATE TABLE Orders (
    OrderID SERIAL PRIMARY KEY,
    CustomerID INTEGER NOT NULL REFERENCES Customer(CustomerID) ON DELETE RESTRICT,
    CardID INTEGER NOT NULL REFERENCES CreditCard(CardID) ON DELETE RESTRICT,
    OrderDate TIMESTAMP NOT NULL,
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('issued', 'sent', 'received')) DEFAULT 'issued'
);

-- OrderItem Table (weak entity with composite primary key)
CREATE TABLE OrderItem (
    OrderID INTEGER NOT NULL REFERENCES Orders(OrderID) ON DELETE CASCADE,
    ProductID INTEGER NOT NULL REFERENCES Product(ProductID) ON DELETE RESTRICT,
    Quantity INTEGER NOT NULL CHECK (Quantity > 0),
    
    -- Composite primary key
    PRIMARY KEY (OrderID, ProductID)
);

-- DeliveryPlan Table (weak entity)
CREATE TABLE DeliveryPlan (
    DeliveryID SERIAL PRIMARY KEY,
    OrderID INTEGER NOT NULL REFERENCES Orders(OrderID) ON DELETE CASCADE,
    DeliveryType VARCHAR(20) NOT NULL,
    DeliveryPrice DECIMAL(10, 2) NOT NULL,
    ShipDate DATE,
    DeliveryDate DATE,
    
    -- Ensure one-to-one relationship with Orders
    CONSTRAINT unique_order_delivery UNIQUE(OrderID)
    
);

-- Supplier Table
CREATE TABLE Supplier (
    SupplierID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL
);

-- SupplierProduct Table (weak entity with composite primary key)
CREATE TABLE SupplierProduct (
    SupplierID INTEGER NOT NULL REFERENCES Supplier(SupplierID) ON DELETE CASCADE,
    ProductID INTEGER NOT NULL REFERENCES Product(ProductID) ON DELETE CASCADE,
    SupplierPrice DECIMAL(10, 2) NOT NULL CHECK (SupplierPrice >= 0),
    
    -- Composite primary key
    PRIMARY KEY (SupplierID, ProductID)
);

CREATE INDEX idx_supplierproduct_product ON SupplierProduct(ProductID);
