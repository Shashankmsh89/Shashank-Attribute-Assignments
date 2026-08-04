-- ============================================================
--  ASSIGNMENT 1 — Database Foundation
--  Developer : Shashank Masih | Mentor: Shivam | Path 2
-- ============================================================

USE TrainingDB;
GO

-- ============================================================
-- STEP 0: Clean slate — drop existing objects if any
-- ============================================================
IF OBJECT_ID('shashank.Attribute',        'U') IS NOT NULL DROP TABLE shashank.Attribute;
IF OBJECT_ID('shashank.CustomerLocation', 'U') IS NOT NULL DROP TABLE shashank.CustomerLocation;
IF OBJECT_ID('shashank.Company',          'U') IS NOT NULL DROP TABLE shashank.Company;
IF OBJECT_ID('shashank.BusinessUnit',     'U') IS NOT NULL DROP TABLE shashank.BusinessUnit;
GO

-- ============================================================
-- STEP 1: Create schema (safe — won't fail if already exists)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'shashank')
    EXEC('CREATE SCHEMA shashank');
GO

-- ============================================================
-- TASK 2: CREATE TABLES
-- ============================================================

-- TABLE: BusinessUnit
-- NVARCHAR(200) not MAX — MAX blocks indexing
-- BIT for boolean flags — smallest, clearest type
-- DATETIME2(0) not DATETIME — avoids 1753 date limit and rounding bugs
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

-- TABLE: CustomerLocation
-- FK to BusinessUnit — INT must match PK type exactly
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

-- TABLE: Company
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

-- TABLE: Attribute (central entity)
-- UpdatedOn/UpdatedBy are NULL — meaningful absence (never updated)
-- CustomerLocationId is NULL — attribute may not be location-specific
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

-- ============================================================
-- TASK 3: Constraint violation demos
-- Each insert below is INTENTIONAL — shows exact error message
-- ============================================================

-- 3a: Violate UNIQUE KEY (UQ_Attr_Name_BU)
-- Insert valid row first, then duplicate
INSERT INTO shashank.BusinessUnit (BusinessUnitName, CreatedBy) VALUES ('TestBU_Constraint', 'Admin');
INSERT INTO shashank.Company      (CompanyName,      CreatedBy) VALUES ('TestCo_Constraint', 'Admin');
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('DuplicateTest', 1, 1, 'Admin');
-- EXPECTED ERROR: Violation of UNIQUE KEY constraint 'UQ_Attr_Name_BU'
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('DuplicateTest', 1, 1, 'Admin');
GO

-- 3b: Violate FK constraint (FK_Attr_CustLoc) — CustLocId 9999 doesn't exist
-- EXPECTED ERROR: INSERT conflicted with FOREIGN KEY constraint
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CustomerLocationId, CompanyId, CreatedBy)
VALUES ('FKViolationTest', 1, 9999, 1, 'Admin');
GO

-- 3c: Violate CHECK constraint — future date not allowed
-- EXPECTED ERROR: INSERT conflicted with CHECK constraint 'CK_Attr_CreatedOn'
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy, CreatedOn)
VALUES ('CheckViolationTest', 1, 1, 'Admin', '2099-01-01');
GO

-- 3d: Violate NOT NULL on CreatedBy
-- EXPECTED ERROR: Cannot insert the value NULL into column 'CreatedBy'
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('NullViolationTest', 1, 1, NULL);
GO

-- Clean up constraint test rows and reseed identity
DELETE FROM shashank.Attribute    WHERE AttributeName = 'DuplicateTest';
DELETE FROM shashank.Company      WHERE CompanyName   = 'TestCo_Constraint';
DELETE FROM shashank.BusinessUnit WHERE BusinessUnitName = 'TestBU_Constraint';
DBCC CHECKIDENT ('shashank.BusinessUnit',     RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('shashank.Company',          RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('shashank.Attribute',        RESEED, 0) WITH NO_INFOMSGS;
GO

-- ============================================================
-- TASK 4: DATA POPULATION
-- Diverse data: mix active/inactive, multiple creators,
-- dates spread over 2 years — catches bugs uniform data misses
-- ============================================================

-- 5 Business Units
INSERT INTO shashank.BusinessUnit (BusinessUnitName, IsActive, CreatedBy, CreatedOn) VALUES
('Finance',         1, 'Admin',    '2023-01-10'),
('Human Resources', 1, 'Admin',    '2023-02-15'),
('IT Operations',   1, 'shashank', '2023-03-20'),
('Marketing',       0, 'Admin',    '2023-04-05'),
('Legal',           0, 'john.doe', '2023-05-01');
GO

-- 10 Customer Locations (BU 5 / Legal gets ZERO locations intentionally)
INSERT INTO shashank.CustomerLocation (CustomerLocationName, BusinessUnitId, IsActive, CreatedBy, CreatedOn) VALUES
('Finance - Mumbai HQ',        1, 1, 'Admin',    '2023-01-15'),  -- ID 1
('Finance - Delhi Branch',     1, 1, 'Admin',    '2023-02-01'),  -- ID 2
('Finance - Hyderabad Office', 1, 0, 'Admin',    '2023-03-10'),  -- ID 3
('HR - Bangalore',             2, 1, 'Admin',    '2023-03-20'),  -- ID 4
('HR - Chennai',               2, 1, 'john.doe', '2023-04-01'),  -- ID 5
('IT Ops - Data Center A',     3, 1, 'shashank', '2023-05-10'),  -- ID 6
('IT Ops - Data Center B',     3, 1, 'shashank', '2023-06-15'),  -- ID 7
('IT Ops - Remote Office',     3, 0, 'shashank', '2023-07-01'),  -- ID 8
('Marketing - Pune',           4, 1, 'Admin',    '2023-08-01'),  -- ID 9
('Marketing - Kolkata',        4, 1, 'Admin',    '2023-09-01');  -- ID 10
GO

-- 5 Companies
INSERT INTO shashank.Company (CompanyName, IsActive, CreatedBy, CreatedOn) VALUES
('GlobalTech Solutions', 1, 'Admin',    '2023-01-05'),  -- ID 1
('DataBridge Pvt Ltd',   1, 'Admin',    '2023-02-10'),  -- ID 2
('Nexus Enterprises',    1, 'shashank', '2023-03-15'),  -- ID 3
('BlueCore Systems',     0, 'john.doe', '2023-04-20'),  -- ID 4
('Vertex Analytics',     1, 'Admin',    '2023-05-25');  -- ID 5
GO

-- 20 Attributes — diverse BUs, locations, companies, dates, creators
-- CustLoc IDs used: 1-8 only (9,10 = Marketing which has no attributes yet)
-- CustLoc IDs 9 and 10 will be deleted in Task 6 (zero attributes)
INSERT INTO shashank.Attribute
    (AttributeName, BusinessUnitId, CustomerLocationId, CompanyId,
     IsActive, CreatedBy, CreatedOn, UpdatedOn, UpdatedBy)
VALUES
-- Finance BU (BU 1) — refs CustLoc 1,2,3
('Global Revenue Tracker',    1, 1, 1, 1, 'Admin',    '2023-02-01', NULL,         NULL),
('Budget Allocation Rule',    1, 2, 2, 1, 'Admin',    '2023-04-10', '2023-08-01', 'Admin'),
('Expense Approval Limit',    1, 3, 1, 0, 'Admin',    '2023-06-15', NULL,         NULL),
('Tax Compliance Flag',       1, 1, 3, 1, 'john.doe', '2023-08-20', '2024-01-10', 'john.doe'),
('Audit Trail Enabled',       1, 2, 5, 1, 'Admin',    '2024-01-05', NULL,         NULL),
-- HR BU (BU 2) — refs CustLoc 4,5
('Headcount Limit',           2, 4, 2, 1, 'Admin',    '2023-03-01', NULL,         NULL),
('Leave Accrual Policy',      2, 5, 3, 1, 'john.doe', '2023-05-20', '2023-11-01', 'Admin'),
('Performance Rating Scale',  2, 4, 1, 0, 'Admin',    '2023-07-10', NULL,         NULL),
('Employee Data Encryption',  2, 5, 4, 1, 'Admin',    '2023-09-15', '2024-03-01', 'shashank'),
('Onboarding Checklist Flag', 2, NULL, 2, 1, 'shashank','2024-02-01', NULL,       NULL),
-- IT Ops BU (BU 3) — refs CustLoc 6,7,8
('Server Uptime Threshold',   3, 6, 3, 1, 'shashank', '2023-04-01', '2024-05-01', 'shashank'),
('Backup Retention Days',     3, 7, 5, 1, 'shashank', '2023-06-10', NULL,         NULL),
('Global Network Bandwidth',  3, 6, 1, 1, 'Admin',    '2023-08-05', '2024-02-20', 'Admin'),
('Patch Cycle Frequency',     3, 8, 2, 0, 'shashank', '2023-10-01', NULL,         NULL),
('Incident Response SLA',     3, 7, 3, 1, 'shashank', '2024-01-20', '2024-06-10', 'shashank'),
-- Marketing BU (BU 4) — NO CustLoc refs (locations 9,10 have ZERO attributes → deleted in Task 6)
('Campaign Budget Cap',       4, NULL, 4, 1, 'Admin',    '2023-05-15', NULL,       NULL),
('Social Media Approval',     4, NULL, 5, 0, 'john.doe', '2023-07-20', '2023-12-01','Admin'),
('Lead Scoring Algorithm',    4, NULL, 2, 1, 'Admin',    '2023-09-10', NULL,       NULL),
-- Legal BU (BU 5) — no locations exist for this BU
('Contract Review Period',    5, NULL, 1, 1, 'john.doe', '2023-11-01', '2024-04-01','john.doe'),
('Data Retention Compliance', 5, NULL, 3, 1, 'Admin',    '2024-03-15', NULL,       NULL);
GO

-- ============================================================
-- TASK 5: UPDATE — deactivate all Attributes for BU 4 (Marketing)
-- WARNING: Without WHERE clause ALL rows would be deactivated — no error thrown!
-- Always preview with SELECT using same WHERE before UPDATE in production.
-- Wrap in transaction so you can ROLLBACK if row count looks wrong.
-- ============================================================

-- Preview first
SELECT AttributeId, AttributeName, IsActive
FROM   shashank.Attribute
WHERE  BusinessUnitId = 4;

-- Update
UPDATE shashank.Attribute
SET    IsActive = 0
WHERE  BusinessUnitId = 4;

-- Verify: only BU 4 rows changed
SELECT AttributeId, AttributeName, BusinessUnitId, IsActive
FROM   shashank.Attribute
ORDER  BY BusinessUnitId;
GO

-- ============================================================
-- TASK 6: DELETE — remove Customer Locations with zero Attributes
-- Locations 9 (Marketing - Pune) and 10 (Marketing - Kolkata) have
-- zero attributes since Marketing attributes all use NULL CustLocId.
-- DELETE vs TRUNCATE vs DROP:
--   DELETE   = removes specific rows, WHERE-filterable, logged, can rollback
--   TRUNCATE = removes ALL rows, no WHERE, resets identity, faster but irreversible
--   DROP     = removes the entire TABLE structure permanently
-- ============================================================

-- Preview before delete
SELECT cl.CustomerLocationId, cl.CustomerLocationName
FROM   shashank.CustomerLocation cl
WHERE  NOT EXISTS (
    SELECT 1 FROM shashank.Attribute a
    WHERE  a.CustomerLocationId = cl.CustomerLocationId
);

-- Execute
DELETE FROM shashank.CustomerLocation
WHERE NOT EXISTS (
    SELECT 1 FROM shashank.Attribute a
    WHERE  a.CustomerLocationId = shashank.CustomerLocation.CustomerLocationId
);
GO

-- ============================================================
-- TASK 7: MERGE — upsert Companies from staging
-- Why MERGE: handles INSERT + UPDATE atomically in one statement.
-- Pitfall 1 (Halloween Problem): SQL may process same row twice — use carefully.
-- Pitfall 2: Statement before MERGE must end with semicolon.
-- Pitfall 3: Multiple source rows matching one target = non-deterministic update.
-- ============================================================
DECLARE @CompanyStaging TABLE (CompanyName NVARCHAR(250), IsActive BIT);
INSERT INTO @CompanyStaging VALUES
('GlobalTech Solutions', 0),   -- EXISTS → UPDATE (flip to inactive)
('BlueCore Systems',     1),   -- EXISTS → UPDATE (flip to active)
('Quantum Data Labs',    1),   -- NEW → INSERT
('Apex Cloud Services',  1),   -- NEW → INSERT
('Horizon AI Corp',      1);   -- NEW → INSERT

DECLARE @MergeAudit TABLE (Action NVARCHAR(10), CompanyId INT, CompanyName NVARCHAR(250));

;MERGE INTO shashank.Company AS Target
USING @CompanyStaging AS Source
ON    Target.CompanyName = Source.CompanyName
WHEN MATCHED THEN
    UPDATE SET Target.IsActive = Source.IsActive
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CompanyName, IsActive, CreatedBy, CreatedOn)
    VALUES (Source.CompanyName, Source.IsActive, 'MergeProcess', GETDATE())
OUTPUT $action, inserted.CompanyId, inserted.CompanyName
INTO   @MergeAudit(Action, CompanyId, CompanyName);

SELECT Action, CompanyId, CompanyName FROM @MergeAudit ORDER BY Action;
GO

-- ============================================================
-- TASK 8: FILTERING & LOGICAL OPERATORS
-- ============================================================

-- 8a: BETWEEN — created between two dates
SELECT AttributeId, AttributeName, CreatedOn
FROM   shashank.Attribute
WHERE  CreatedOn BETWEEN '2023-06-01' AND '2024-01-31'
ORDER  BY CreatedOn;
GO

-- 8b: IN — specific BusinessUnitIds
SELECT AttributeId, AttributeName, BusinessUnitId
FROM   shashank.Attribute
WHERE  BusinessUnitId IN (1, 2, 3);
GO

-- 8c: NOT IN vs NOT EXISTS vs LEFT JOIN+IS NULL
-- NOT IN: Can silently return 0 rows if list contains NULL!
SELECT AttributeId, AttributeName FROM shashank.Attribute
WHERE  BusinessUnitId NOT IN (1, 2, 3);

-- NOT EXISTS: NULL-safe alternative
SELECT a.AttributeId, a.AttributeName FROM shashank.Attribute a
WHERE  NOT EXISTS (
    SELECT 1 FROM (VALUES (1),(2),(3)) AS x(Id) WHERE x.Id = a.BusinessUnitId);

-- LEFT JOIN + IS NULL: also NULL-safe
SELECT a.AttributeId, a.AttributeName FROM shashank.Attribute a
LEFT   JOIN (VALUES (1),(2),(3)) AS x(Id) ON x.Id = a.BusinessUnitId
WHERE  x.Id IS NULL;
-- Comment: NOT IN with NULLs — if ANY value in the list is NULL, NOT IN returns
-- zero rows because NULL comparisons yield UNKNOWN, not FALSE.
GO

-- 8d: LIKE wildcards
SELECT AttributeName FROM shashank.Attribute WHERE AttributeName LIKE 'A%';       -- starts with A
SELECT AttributeName FROM shashank.Attribute WHERE AttributeName LIKE '%ing';      -- ends with ing
SELECT AttributeName FROM shashank.Attribute WHERE AttributeName LIKE '%data%';    -- contains data (case-insensitive)
SELECT AttributeName FROM shashank.Attribute WHERE AttributeName LIKE '__o__';     -- 5 chars, 3rd = o
GO

-- 8e: AND / OR / NOT with parentheses
SELECT AttributeId, AttributeName, BusinessUnitId, IsActive, CreatedBy
FROM   shashank.Attribute
WHERE  (BusinessUnitId IN (1, 2) AND IsActive = 1)
AND    CreatedBy <> 'Admin';
-- Comment: Without parentheses AND/OR precedence can give wrong results silently.
-- "A AND B OR C" = "A AND (B OR C)" in SQL — always use () to be explicit.
GO

-- ============================================================
-- TASK 9: PAGING
-- ============================================================

-- TOP 10 most recent
SELECT TOP 10 AttributeId, AttributeName, CreatedOn
FROM   shashank.Attribute
ORDER  BY CreatedOn DESC;

-- Insert tie rows to demo WITH TIES
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy, CreatedOn)
VALUES ('Tie Test Alpha', 1, 1, 'Admin', '2024-06-10'),
       ('Tie Test Beta',  2, 1, 'Admin', '2024-06-10');

-- TOP 5 WITH TIES — may return more than 5 when last value ties
SELECT TOP 5 WITH TIES AttributeId, AttributeName, CreatedOn
FROM   shashank.Attribute ORDER BY CreatedOn DESC;

-- OFFSET-FETCH: page 2 (rows 11-20)
SELECT AttributeId, AttributeName, CreatedOn
FROM   shashank.Attribute
ORDER  BY AttributeName
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- Parameterised pagination
DECLARE @PageNumber INT = 2, @PageSize INT = 5;
SELECT AttributeId, AttributeName
FROM   shashank.Attribute
ORDER  BY AttributeName
OFFSET (@PageNumber - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
-- Comment: TOP = fixed rows from start, no concept of pages.
-- OFFSET-FETCH = true pagination, skip N then return M. Always use for page 2+.
GO

-- ============================================================
-- TASK 10: AGGREGATE FUNCTIONS
-- ============================================================

-- Total attributes per BU
SELECT   bu.BusinessUnitName, COUNT(a.AttributeId) AS TotalAttributes
FROM     shashank.BusinessUnit bu
LEFT     JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP    BY bu.BusinessUnitName ORDER BY TotalAttributes DESC;

-- Average attributes per Company via CTE
WITH AttrPerCo AS (
    SELECT CompanyId, COUNT(AttributeId) AS Cnt
    FROM   shashank.Attribute GROUP BY CompanyId
)
SELECT AVG(CAST(Cnt AS DECIMAL(10,2))) AS AvgPerCompany FROM AttrPerCo;

-- BUs with MORE than 3 active attributes
SELECT   bu.BusinessUnitName, COUNT(a.AttributeId) AS ActiveCount
FROM     shashank.BusinessUnit bu
JOIN     shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
WHERE    a.IsActive = 1
GROUP    BY bu.BusinessUnitName
HAVING   COUNT(a.AttributeId) > 3;
-- Comment: WHERE filters rows before GROUP BY. HAVING filters groups after.
-- Aggregate functions (COUNT, SUM) cannot be used in WHERE — only in HAVING.

-- Company with MAX and MIN attribute count
WITH CoCounts AS (
    SELECT co.CompanyName, COUNT(a.AttributeId) AS Cnt
    FROM   shashank.Company co
    LEFT   JOIN shashank.Attribute a ON a.CompanyId = co.CompanyId
    GROUP  BY co.CompanyName
)
SELECT CompanyName, Cnt,
       CASE WHEN Cnt = (SELECT MAX(Cnt) FROM CoCounts) THEN 'MAX'
            WHEN Cnt = (SELECT MIN(Cnt) FROM CoCounts) THEN 'MIN' END AS Rank
FROM   CoCounts
WHERE  Cnt = (SELECT MAX(Cnt) FROM CoCounts)
    OR Cnt = (SELECT MIN(Cnt) FROM CoCounts);
GO

-- ============================================================
-- TASK 11: STRING FUNCTIONS
-- ============================================================
SELECT AttributeName, CHARINDEX('Global', AttributeName) AS Position
FROM   shashank.Attribute WHERE CHARINDEX('Global', AttributeName) > 0;

SELECT AttributeName, UPPER(AttributeName) AS UpperName,
       SUBSTRING(AttributeName, 1, 10) AS First10
FROM   shashank.Attribute;

SELECT BusinessUnitName, REPLACE(BusinessUnitName, ' ', '-') AS Hyphenated
FROM   shashank.BusinessUnit;

SELECT AttributeName, LEN(AttributeName) AS NameLen
FROM   shashank.Attribute WHERE LEN(AttributeName) > 20 ORDER BY NameLen DESC;
GO

-- ============================================================
-- TASK 12: DATE FUNCTIONS
-- ============================================================
-- Last 6 months
SELECT AttributeId, AttributeName, CreatedOn
FROM   shashank.Attribute
WHERE  CreatedOn >= DATEADD(MONTH, -6, GETDATE());

-- Days since created
SELECT AttributeName, DATEDIFF(DAY, CreatedOn, GETDATE()) AS DaysSinceCreated
FROM   shashank.Attribute ORDER BY DaysSinceCreated DESC;

-- Formatted date: dd-MMM-yyyy
SELECT AttributeName,
       FORMAT(CreatedOn, 'dd-MMM-yyyy')    AS FormattedFORMAT,
       CONVERT(VARCHAR(11), CreatedOn, 106) AS FormattedCONVERT
FROM   shashank.Attribute;
-- Comment: FORMAT is flexible but slow (CLR call per row) — use for display/reporting.
-- CONVERT is fast native T-SQL — use in high-volume production queries.

-- Count per month
SELECT YEAR(CreatedOn) AS Yr, MONTH(CreatedOn) AS Mo,
       DATENAME(MONTH, CreatedOn) AS MonthName, COUNT(*) AS Count
FROM   shashank.Attribute
GROUP  BY YEAR(CreatedOn), MONTH(CreatedOn), DATENAME(MONTH, CreatedOn)
ORDER  BY Yr, Mo;
GO

-- ============================================================
-- TASK 13: CASE EXPRESSIONS
-- ============================================================
SELECT AttributeId, AttributeName, CreatedOn, UpdatedOn, UpdatedBy,
    CASE IsActive WHEN 1 THEN 'Active' ELSE 'Inactive' END AS Status,
    CASE
        WHEN DATEDIFF(MONTH, CreatedOn, GETDATE()) <  3 THEN 'New'
        WHEN DATEDIFF(MONTH, CreatedOn, GETDATE()) <  6 THEN 'Recent'
        WHEN DATEDIFF(MONTH, CreatedOn, GETDATE()) < 12 THEN 'Established'
        ELSE 'Old'
    END AS AgeCategory,
    CASE
        WHEN UpdatedOn IS NOT NULL AND UpdatedBy IS NOT NULL THEN 'Complete'
        ELSE 'Needs Update'
    END AS DataCompleteness
FROM shashank.Attribute ORDER BY AttributeId;
GO

-- ============================================================
-- TASK 14: PIVOT
-- Rows = BU, Columns = Active/Inactive, Values = COUNT
-- Equivalent with CASE+GROUP BY — more readable, no hard-coded column names
-- ============================================================
SELECT BusinessUnitName,
       ISNULL([1], 0) AS ActiveCount,
       ISNULL([0], 0) AS InactiveCount
FROM (
    SELECT bu.BusinessUnitName, a.IsActive, a.AttributeId
    FROM   shashank.BusinessUnit bu
    LEFT   JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
) AS Src
PIVOT (COUNT(AttributeId) FOR IsActive IN ([1],[0])) AS Pvt
ORDER BY BusinessUnitName;
GO

-- ============================================================
-- TASK 15: UNPIVOT
-- Reshape wide (Active/Inactive columns) back to tall (rows)
-- Useful for: feeding chart tools, import pipelines, PowerBI
-- ============================================================
WITH PivotSrc AS (
    SELECT BusinessUnitName,
           ISNULL([1], 0) AS ActiveCount,
           ISNULL([0], 0) AS InactiveCount
    FROM (
        SELECT bu.BusinessUnitName, a.IsActive, a.AttributeId
        FROM   shashank.BusinessUnit bu
        LEFT   JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
    ) AS Src
    PIVOT (COUNT(AttributeId) FOR IsActive IN ([1],[0])) AS Pvt
)
SELECT BusinessUnitName, StatusType, StatusValue
FROM   PivotSrc
UNPIVOT (StatusValue FOR StatusType IN (ActiveCount, InactiveCount)) AS Unpvt
ORDER  BY BusinessUnitName;
GO

-- ============================================================
-- TASK 16: CROSS APPLY with VALUES
-- More flexible than UNPIVOT — can compute derived rows (Total)
-- UNPIVOT only rotates existing columns; CROSS APPLY can add new ones
-- ============================================================
WITH BUSummary AS (
    SELECT bu.BusinessUnitName,
           SUM(CASE WHEN a.IsActive = 1 THEN 1 ELSE 0 END) AS ActiveCount,
           SUM(CASE WHEN a.IsActive = 0 THEN 1 ELSE 0 END) AS InactiveCount
    FROM   shashank.BusinessUnit bu
    LEFT   JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
    GROUP  BY bu.BusinessUnitName
)
SELECT b.BusinessUnitName, x.StatusType, x.StatusValue
FROM   BUSummary b
CROSS  APPLY (VALUES
    ('Active',   b.ActiveCount),
    ('Inactive', b.InactiveCount),
    ('Total',    b.ActiveCount + b.InactiveCount)
) AS x(StatusType, StatusValue)
ORDER  BY b.BusinessUnitName, x.StatusType;
GO

-- ============================================================
-- END OF ASSIGNMENT 1
-- All tables and data preserved for Assignment 2
-- ============================================================
