USE TrainingDB;
GO

IF OBJECT_ID('shashank.Attribute',        'U') IS NOT NULL DROP TABLE shashank.Attribute;
IF OBJECT_ID('shashank.CustomerLocation', 'U') IS NOT NULL DROP TABLE shashank.CustomerLocation;
IF OBJECT_ID('shashank.Company',          'U') IS NOT NULL DROP TABLE shashank.Company;
IF OBJECT_ID('shashank.BusinessUnit',     'U') IS NOT NULL DROP TABLE shashank.BusinessUnit;
GO

CREATE TABLE shashank.BusinessUnit (
    BusinessUnitId   INT            NOT NULL IDENTITY(1,1),
    BusinessUnitName NVARCHAR(200)  NOT NULL,
    IsActive         BIT            NOT NULL CONSTRAINT DF_BU_IsActive  DEFAULT 1,
    CreatedOn        DATETIME2(0)   NOT NULL CONSTRAINT DF_BU_CreatedOn DEFAULT GETDATE(),
    CreatedBy        NVARCHAR(100)  NOT NULL,
    CONSTRAINT PK_BusinessUnit     PRIMARY KEY (BusinessUnitId),
    CONSTRAINT UQ_BusinessUnit_Name UNIQUE (BusinessUnitName),
    CONSTRAINT CK_BU_CreatedOn     CHECK (CreatedOn <= GETDATE())
);
GO

CREATE TABLE shashank.CustomerLocation (
    CustomerLocationId   INT           NOT NULL IDENTITY(1,1),
    CustomerLocationName NVARCHAR(300) NOT NULL,
    BusinessUnitId       INT           NOT NULL,
    IsActive             BIT           NOT NULL CONSTRAINT DF_CL_IsActive  DEFAULT 1,
    CreatedOn            DATETIME2(0)  NOT NULL CONSTRAINT DF_CL_CreatedOn DEFAULT GETDATE(),
    CreatedBy            NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_CustomerLocation PRIMARY KEY (CustomerLocationId),
    CONSTRAINT FK_CL_BusinessUnit  FOREIGN KEY (BusinessUnitId)
        REFERENCES shashank.BusinessUnit(BusinessUnitId),
    CONSTRAINT CK_CL_CreatedOn     CHECK (CreatedOn <= GETDATE())
);
GO

CREATE TABLE shashank.Company (
    CompanyId   INT           NOT NULL IDENTITY(1,1),
    CompanyName NVARCHAR(250) NOT NULL,
    IsActive    BIT           NOT NULL CONSTRAINT DF_Co_IsActive  DEFAULT 1,
    CreatedOn   DATETIME2(0)  NOT NULL CONSTRAINT DF_Co_CreatedOn DEFAULT GETDATE(),
    CreatedBy   NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Company    PRIMARY KEY (CompanyId),
    CONSTRAINT UQ_Company_Name UNIQUE (CompanyName),
    CONSTRAINT CK_Co_CreatedOn CHECK (CreatedOn <= GETDATE())
);
GO

CREATE TABLE shashank.Attribute (
    AttributeId        INT           NOT NULL IDENTITY(1,1),
    AttributeName      NVARCHAR(300) NOT NULL,
    BusinessUnitId     INT           NOT NULL,
    CustomerLocationId INT           NULL,
    CompanyId          INT           NOT NULL,
    IsActive           BIT           NOT NULL CONSTRAINT DF_Attr_IsActive  DEFAULT 1,
    CreatedOn          DATETIME2(0)  NOT NULL CONSTRAINT DF_Attr_CreatedOn DEFAULT GETDATE(),
    CreatedBy          NVARCHAR(100) NOT NULL,
    UpdatedOn          DATETIME2(0)  NULL,
    UpdatedBy          NVARCHAR(100) NULL,
    CONSTRAINT PK_Attribute         PRIMARY KEY (AttributeId),
    CONSTRAINT FK_Attr_BusinessUnit  FOREIGN KEY (BusinessUnitId)
        REFERENCES shashank.BusinessUnit(BusinessUnitId),
    CONSTRAINT FK_Attr_CustLoc       FOREIGN KEY (CustomerLocationId)
        REFERENCES shashank.CustomerLocation(CustomerLocationId),
    CONSTRAINT FK_Attr_Company       FOREIGN KEY (CompanyId)
        REFERENCES shashank.Company(CompanyId),
    CONSTRAINT UQ_Attr_Name_BU      UNIQUE (AttributeName, BusinessUnitId),
    CONSTRAINT CK_Attr_CreatedOn    CHECK (CreatedOn <= GETDATE())
);
GO
