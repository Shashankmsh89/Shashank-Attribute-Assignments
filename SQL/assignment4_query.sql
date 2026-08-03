-- ============================================================
--  ASSIGNMENT 4 — Stored Procedures, UDFs & Temp Tables
--  Developer : Shashank Masih | Mentor: Shivam | Path 2
--  Database  : TrainingDB | Schema: shashank
--  Builds on : Assignments 1–3
-- ============================================================

USE TrainingDB;
GO

-- ============================================================
-- SECTION 1: STORED PROCEDURES — CRUD
-- ============================================================

-- ── Task 1: uspGetAttributeList ───────────────────────────────
-- Comment: Nullable parameters instead of separate SPs because:
-- (1) One SP = one execution plan, one permission grant, one test
-- (2) Combinatorial explosion: 2 filters = 4 SPs, 3 filters = 8 SPs
-- (3) Callers pass NULL to opt out of a filter — simple and composable
-- (4) Maintenance: change sort logic in ONE place, not N SPs

CREATE OR ALTER PROCEDURE shashank.uspGetAttributeList
    @IsActiveFilter BIT          = NULL,   -- NULL=all, 1=active, 0=inactive
    @SearchTerm     NVARCHAR(100) = NULL    -- NULL=no filter
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 500
        a.AttributeId,
        a.AttributeName,
        bu.BusinessUnitName,
        ISNULL(cl.CustomerLocationName, 'No Location') AS CustomerLocationName,
        co.CompanyName,
        a.IsActive,
        a.CreatedOn,
        a.CreatedBy,
        a.UpdatedOn,
        a.UpdatedBy
    FROM shashank.Attribute        a
    JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
    LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
    JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId
    WHERE
        (@IsActiveFilter IS NULL OR a.IsActive = @IsActiveFilter)
        AND (
            @SearchTerm IS NULL
            OR a.AttributeName    LIKE '%' + @SearchTerm + '%'
            OR bu.BusinessUnitName LIKE '%' + @SearchTerm + '%'
        )
    ORDER BY a.AttributeName;
END;
GO

-- Test
EXEC shashank.uspGetAttributeList;
EXEC shashank.uspGetAttributeList @IsActiveFilter = 1;
EXEC shashank.uspGetAttributeList @SearchTerm = 'Global';
EXEC shashank.uspGetAttributeList @IsActiveFilter = 1, @SearchTerm = 'Trail';
GO

-- ── Task 2: uspGetAttributeById ───────────────────────────────
-- Comment: Return empty set instead of error because:
-- (1) "Not found" is a valid application state, not an exception
-- (2) Caller checks @@ROWCOUNT or row count in ADO.NET — simpler
-- (3) Raising an error forces try/catch in the app layer for a normal case
-- Raise an error when: ID format is invalid (e.g. -1), or caller MUST have a row

CREATE OR ALTER PROCEDURE shashank.uspGetAttributeById
    @AttributeId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AttributeId,
        a.AttributeName,
        a.BusinessUnitId,
        bu.BusinessUnitName,
        a.CustomerLocationId,
        ISNULL(cl.CustomerLocationName, 'No Location') AS CustomerLocationName,
        a.CompanyId,
        co.CompanyName,
        a.IsActive,
        a.CreatedOn,
        a.CreatedBy,
        a.UpdatedOn,
        a.UpdatedBy
    FROM shashank.Attribute        a
    JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
    LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
    JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId
    WHERE a.AttributeId = @AttributeId;
    -- Returns 0 rows if not found — caller checks @@ROWCOUNT
END;
GO

-- Test
EXEC shashank.uspGetAttributeById @AttributeId = 1;
EXEC shashank.uspGetAttributeById @AttributeId = 9999; -- empty result
GO

-- ── Task 3: uspSaveAttribute ──────────────────────────────────
-- Comment: Validate inside SP because:
-- (1) Constraints catch structural violations (PK, FK, UNIQUE)
-- (2) Constraints CANNOT catch: empty string ('' passes NOT NULL),
--     business rules (BU must be active), cross-table logic
-- (3) SP validation returns friendly messages; constraints return cryptic errors
-- (4) Single validation point — app, API, and batch callers all get same rules

CREATE OR ALTER PROCEDURE shashank.uspSaveAttribute
    @AttributeId        INT            = NULL,   -- NULL = INSERT, value = UPDATE
    @AttributeName      NVARCHAR(300),
    @BusinessUnitId     INT,
    @CustomerLocationId INT            = NULL,
    @CompanyId          INT,
    @IsActive           BIT            = 1,
    @UpdatedBy          NVARCHAR(100)  = 'SYSTEM',
    @ResultAttributeId  INT            OUTPUT,
    @ResultMessage      NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialise outputs
    SET @ResultAttributeId = -1;
    SET @ResultMessage     = '';

    -- ── Validation ────────────────────────────────────────────
    IF LTRIM(RTRIM(ISNULL(@AttributeName, ''))) = ''
    BEGIN
        SET @ResultMessage = 'Validation Error: AttributeName cannot be empty.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM shashank.BusinessUnit WHERE BusinessUnitId = @BusinessUnitId)
    BEGIN
        SET @ResultMessage = 'Validation Error: BusinessUnitId ' + CAST(@BusinessUnitId AS VARCHAR) + ' does not exist.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM shashank.Company WHERE CompanyId = @CompanyId)
    BEGIN
        SET @ResultMessage = 'Validation Error: CompanyId ' + CAST(@CompanyId AS VARCHAR) + ' does not exist.';
        RETURN;
    END;

    -- ── INSERT ────────────────────────────────────────────────
    IF @AttributeId IS NULL
    BEGIN
        -- Check uniqueness: AttributeName must be unique within BU
        IF EXISTS (
            SELECT 1 FROM shashank.Attribute
            WHERE  AttributeName    = LTRIM(RTRIM(@AttributeName))
            AND    BusinessUnitId   = @BusinessUnitId
        )
        BEGIN
            SET @ResultMessage = 'Validation Error: AttributeName already exists in this Business Unit.';
            RETURN;
        END;

        INSERT INTO shashank.Attribute
            (AttributeName, BusinessUnitId, CustomerLocationId, CompanyId,
             IsActive, CreatedBy, CreatedOn)
        VALUES
            (LTRIM(RTRIM(@AttributeName)), @BusinessUnitId, @CustomerLocationId,
             @CompanyId, @IsActive, @UpdatedBy, GETDATE());

        SET @ResultAttributeId = SCOPE_IDENTITY();
        SET @ResultMessage     = 'Insert Successful';
    END
    -- ── UPDATE ────────────────────────────────────────────────
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM shashank.Attribute WHERE AttributeId = @AttributeId)
        BEGIN
            SET @ResultMessage = 'Validation Error: AttributeId ' + CAST(@AttributeId AS VARCHAR) + ' not found.';
            RETURN;
        END;

        -- Uniqueness check excluding self
        IF EXISTS (
            SELECT 1 FROM shashank.Attribute
            WHERE  AttributeName  = LTRIM(RTRIM(@AttributeName))
            AND    BusinessUnitId = @BusinessUnitId
            AND    AttributeId   <> @AttributeId
        )
        BEGIN
            SET @ResultMessage = 'Validation Error: AttributeName already exists in this Business Unit.';
            RETURN;
        END;

        UPDATE shashank.Attribute
        SET
            AttributeName      = LTRIM(RTRIM(@AttributeName)),
            BusinessUnitId     = @BusinessUnitId,
            CustomerLocationId = @CustomerLocationId,
            CompanyId          = @CompanyId,
            IsActive           = @IsActive,
            UpdatedOn          = GETDATE(),
            UpdatedBy          = @UpdatedBy
        WHERE AttributeId = @AttributeId;

        SET @ResultAttributeId = @AttributeId;
        SET @ResultMessage     = 'Update Successful';
    END;
END;
GO

-- Test INSERT
DECLARE @Id INT, @Msg NVARCHAR(500);
EXEC shashank.uspSaveAttribute
    @AttributeName = 'Test New Attribute', @BusinessUnitId = 1,
    @CompanyId = 1, @UpdatedBy = 'shashank',
    @ResultAttributeId = @Id OUTPUT, @ResultMessage = @Msg OUTPUT;
SELECT @Id AS NewId, @Msg AS Message;

-- Test UPDATE
EXEC shashank.uspSaveAttribute
    @AttributeId = 1, @AttributeName = 'Global Revenue Tracker Updated',
    @BusinessUnitId = 1, @CompanyId = 1, @UpdatedBy = 'shashank',
    @ResultAttributeId = @Id OUTPUT, @ResultMessage = @Msg OUTPUT;
SELECT @Id AS UpdatedId, @Msg AS Message;

-- Test validation
EXEC shashank.uspSaveAttribute
    @AttributeName = '', @BusinessUnitId = 1, @CompanyId = 1, @UpdatedBy = 'shashank',
    @ResultAttributeId = @Id OUTPUT, @ResultMessage = @Msg OUTPUT;
SELECT @Id AS ErrorId, @Msg AS Message;
GO

-- ── Task 4: uspDeleteAttribute (soft-delete) ──────────────────
-- Comment: Soft-delete vs hard-delete:
-- Soft-delete (IsActive=0): preserves history, supports restore, audit trail intact,
--   FKs remain valid, reports can show historical data. Con: data grows over time,
--   queries must filter IsActive to exclude "deleted" rows.
-- Hard-delete: reclaims storage, simpler queries. Con: history lost, FK cascades
--   can be dangerous, may violate audit/compliance requirements.
-- Production default: soft-delete for business data, hard-delete for temp/log tables.

CREATE OR ALTER PROCEDURE shashank.uspDeleteAttribute
    @AttributeId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM shashank.Attribute WHERE AttributeId = @AttributeId)
    BEGIN
        RETURN 0;  -- record not found
    END;

    UPDATE shashank.Attribute
    SET
        IsActive  = 0,
        UpdatedOn = GETDATE(),
        UpdatedBy = 'SYSTEM'
    WHERE AttributeId = @AttributeId;

    RETURN 1;  -- success
END;
GO

-- Test
DECLARE @rc INT;
EXEC @rc = shashank.uspDeleteAttribute @AttributeId = 22;
SELECT @rc AS ReturnValue;  -- 1 = found & soft-deleted

EXEC @rc = shashank.uspDeleteAttribute @AttributeId = 9999;
SELECT @rc AS ReturnValue;  -- 0 = not found
GO

-- ── Task 5: Dropdown SPs ──────────────────────────────────────
-- Comment: Separate SPs per dropdown because:
-- (1) Each returns a different schema — can't union them in one SP cleanly
-- (2) Security: caller gets only the data they need
-- (3) Caching: SQL Server can cache each plan independently
-- (4) One parameter to select which dropdown = giant CASE, harder to maintain
-- (5) Testing: each SP is independently testable

CREATE OR ALTER PROCEDURE shashank.uspGetBusinessUnits
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BusinessUnitId AS Id, BusinessUnitName AS Name
    FROM   shashank.BusinessUnit
    WHERE  IsActive = 1
    ORDER  BY BusinessUnitName;
END;
GO

CREATE OR ALTER PROCEDURE shashank.uspGetCustomerLocationsByBusinessUnit
    @BusinessUnitId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CustomerLocationId AS Id, CustomerLocationName AS Name
    FROM   shashank.CustomerLocation
    WHERE  BusinessUnitId = @BusinessUnitId
    AND    IsActive        = 1
    ORDER  BY CustomerLocationName;
END;
GO

CREATE OR ALTER PROCEDURE shashank.uspGetCompanies
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CompanyId AS Id, CompanyName AS Name
    FROM   shashank.Company
    WHERE  IsActive = 1
    ORDER  BY CompanyName;
END;
GO

-- Test
EXEC shashank.uspGetBusinessUnits;
EXEC shashank.uspGetCustomerLocationsByBusinessUnit @BusinessUnitId = 1;
EXEC shashank.uspGetCompanies;
GO

-- ============================================================
-- SECTION 2: REPORTING STORED PROCEDURES
-- ============================================================

-- ── Task 6: uspGetBusinessUnitSummary ─────────────────────────
-- Comment: CASE in ORDER BY vs dynamic SQL:
-- CASE in ORDER BY is safe — no injection risk, execution plan is stable,
-- SQL Server handles it natively. Use dynamic SQL when: column names come
-- from user input (can't CASE on unknown columns), or when you need to
-- sort on 50+ possible columns (CASE would be unmaintainable).
-- Dynamic SQL is appropriate: complex search builders, generic reporting tools,
-- schema-driven queries. Always parameterise values; never concatenate table/column names
-- without whitelist validation.

CREATE OR ALTER PROCEDURE shashank.uspGetBusinessUnitSummary
    @SortBy NVARCHAR(20) = 'Name'   -- 'Name' | 'TotalAttributes' | 'RecentDate'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        bu.BusinessUnitName,
        COUNT(a.AttributeId)                                AS TotalAttributes,
        SUM(CASE WHEN a.IsActive = 1 THEN 1 ELSE 0 END)   AS ActiveCount,
        SUM(CASE WHEN a.IsActive = 0 THEN 1 ELSE 0 END)   AS InactiveCount,
        MAX(a.CreatedOn)                                    AS MostRecentDate,
        MIN(a.CreatedOn)                                    AS OldestDate
    FROM shashank.BusinessUnit bu
    LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
    GROUP BY bu.BusinessUnitName, bu.BusinessUnitId
    ORDER BY
        CASE WHEN @SortBy = 'Name'            THEN bu.BusinessUnitName   END ASC,
        CASE WHEN @SortBy = 'TotalAttributes' THEN COUNT(a.AttributeId)  END DESC,
        CASE WHEN @SortBy = 'RecentDate'      THEN MAX(a.CreatedOn)      END DESC;
END;
GO

-- Test
EXEC shashank.uspGetBusinessUnitSummary;
EXEC shashank.uspGetBusinessUnitSummary @SortBy = 'TotalAttributes';
EXEC shashank.uspGetBusinessUnitSummary @SortBy = 'RecentDate';
GO

-- ── Task 7: uspSearchAttributes (paginated) ───────────────────
-- Comment: Server-side pagination is critical because:
-- (1) Returning 50,000 rows to the app then slicing wastes network + memory
-- (2) SQL Server can use indexes to skip rows — O(log n) vs O(n) app-side
-- (3) .NET DataTable with 50k rows = slow render, high RAM, bad UX
-- Rule: NEVER return more rows than the page needs.

CREATE OR ALTER PROCEDURE shashank.uspSearchAttributes
    @SearchTerm  NVARCHAR(100) = NULL,
    @PageNumber  INT           = 1,
    @PageSize    INT           = 20,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get total count first (for pagination UI)
    SELECT @TotalCount = COUNT(*)
    FROM shashank.Attribute        a
    JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId = a.BusinessUnitId
    JOIN shashank.Company          co ON co.CompanyId      = a.CompanyId
    WHERE
        @SearchTerm IS NULL
        OR a.AttributeName    LIKE '%' + @SearchTerm + '%'
        OR bu.BusinessUnitName LIKE '%' + @SearchTerm + '%'
        OR co.CompanyName      LIKE '%' + @SearchTerm + '%';

    -- Return page
    SELECT
        a.AttributeId,
        a.AttributeName,
        bu.BusinessUnitName,
        co.CompanyName,
        a.IsActive,
        a.CreatedOn
    FROM shashank.Attribute        a
    JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId = a.BusinessUnitId
    JOIN shashank.Company          co ON co.CompanyId      = a.CompanyId
    WHERE
        @SearchTerm IS NULL
        OR a.AttributeName    LIKE '%' + @SearchTerm + '%'
        OR bu.BusinessUnitName LIKE '%' + @SearchTerm + '%'
        OR co.CompanyName      LIKE '%' + @SearchTerm + '%'
    ORDER BY a.AttributeName
    OFFSET  (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

-- Test
DECLARE @Total INT;
EXEC shashank.uspSearchAttributes @SearchTerm = 'Global', @PageNumber = 1, @PageSize = 5, @TotalCount = @Total OUTPUT;
SELECT @Total AS TotalMatchingRows;
GO

-- ============================================================
-- SECTION 3: WINDOW FUNCTIONS IN STORED PROCEDURES
-- ============================================================

-- ── Task 8: uspGetAttributeRankings ──────────────────────────
-- Comment: Without window functions, you'd need:
-- (1) Correlated subqueries per column (one subquery each for rank, LAG, running count)
-- (2) Multiple self-joins — O(n²) complexity
-- (3) Temp tables to stage intermediate results
-- Window functions compute all partitions in ONE pass through the data.
-- Performance: window functions use Sort + Segment + Sequence Project operators —
-- far cheaper than correlated subquery per row.

CREATE OR ALTER PROCEDURE shashank.uspGetAttributeRankings
    @BusinessUnitId INT = NULL   -- NULL = all BUs
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AttributeId,
        a.AttributeName,
        bu.BusinessUnitName,
        a.CreatedOn,

        -- RowNum within BU by CreatedOn DESC
        ROW_NUMBER() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn DESC
        ) AS RowNumInBU,

        -- Rank by AttributeName alphabetically within BU
        RANK() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.AttributeName ASC
        ) AS RankByName,

        -- Quartile across all results
        NTILE(4) OVER (
            ORDER BY a.CreatedOn
        ) AS Quartile,

        -- Previous attribute name in same BU (by CreatedOn)
        LAG(a.AttributeName) OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn
        ) AS PreviousAttributeName,

        -- Days since previous attribute in same BU
        DATEDIFF(DAY,
            LAG(a.CreatedOn) OVER (
                PARTITION BY a.BusinessUnitId
                ORDER BY     a.CreatedOn
            ),
            a.CreatedOn
        ) AS DaysSincePrevious,

        -- Running count within BU
        COUNT(*) OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningCountInBU

    FROM shashank.Attribute    a
    JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
    WHERE @BusinessUnitId IS NULL OR a.BusinessUnitId = @BusinessUnitId
    ORDER BY bu.BusinessUnitName, a.CreatedOn;
END;
GO

-- Test
EXEC shashank.uspGetAttributeRankings;
EXEC shashank.uspGetAttributeRankings @BusinessUnitId = 1;
GO

-- ============================================================
-- SECTION 4: USER-DEFINED FUNCTIONS
-- ============================================================

-- ── Task 9: fnGetAttributeAge (Scalar UDF) ────────────────────
-- Comment: Scalar UDF vs Inline TVF:
-- Scalar UDF: returns ONE value, called in SELECT/WHERE/ORDER BY.
--   Con: SQL Server calls it once per row — cannot be parallelised before SQL 2019.
--   SQL 2019+ has scalar UDF inlining (auto-converts to inline expression if possible).
-- Inline TVF: returns a TABLE, defined as a single SELECT — SQL Server treats it
--   like a parameterised view, can be parallelised, can use indexes.
-- Rule: prefer Inline TVF when possible. Use scalar UDF only for simple computations
--   that cannot be expressed as a single table-returning SELECT.

CREATE OR ALTER FUNCTION shashank.fnGetAttributeAge
    (@CreatedOn DATETIME2)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Days    INT = DATEDIFF(DAY,  @CreatedOn, GETDATE());
    DECLARE @Months  INT = DATEDIFF(MONTH,@CreatedOn, GETDATE());
    DECLARE @Years   INT = DATEDIFF(YEAR, @CreatedOn, GETDATE());
    DECLARE @Result  NVARCHAR(50);

    SET @Result =
        CASE
            WHEN @Days   < 1    THEN '< 1 day'
            WHEN @Days   < 30   THEN CAST(@Days  AS NVARCHAR) + ' days'
            WHEN @Months < 12   THEN CAST(@Months AS NVARCHAR) + ' months'
            ELSE
                CAST(@Years AS NVARCHAR) + ' year' + CASE WHEN @Years > 1 THEN 's ' ELSE ' ' END
                + CAST(@Months - (@Years * 12) AS NVARCHAR) + ' months'
        END;

    RETURN @Result;
END;
GO

-- Use in SELECT
SELECT
    AttributeName,
    CreatedOn,
    shashank.fnGetAttributeAge(CreatedOn) AS AttributeAge
FROM shashank.Attribute
ORDER BY CreatedOn;
GO

-- ── Task 10: fnGetAttributesByCompany (Inline TVF) ────────────
-- Comment: CROSS APPLY vs OUTER APPLY:
-- CROSS APPLY = like INNER JOIN — only rows where TVF returns at least 1 row
-- OUTER APPLY = like LEFT JOIN  — includes rows even when TVF returns 0 rows (NULLs for TVF columns)
--
-- Function vs View:
-- View = no parameters, same result for all callers
-- Function = parameterised, returns different rows per input — like a "row-filtered view"

CREATE OR ALTER FUNCTION shashank.fnGetAttributesByCompany
    (@CompanyId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        a.AttributeId,
        a.AttributeName,
        bu.BusinessUnitName,
        ISNULL(cl.CustomerLocationName, 'No Location') AS LocationName,
        a.IsActive,
        a.CreatedOn
    FROM shashank.Attribute        a
    JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
    LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
    WHERE a.CompanyId = @CompanyId
);
GO

-- Use with CROSS APPLY
SELECT
    co.CompanyName,
    fa.AttributeName,
    fa.BusinessUnitName,
    fa.LocationName,
    fa.IsActive
FROM shashank.Company co
CROSS APPLY shashank.fnGetAttributesByCompany(co.CompanyId) fa
ORDER BY co.CompanyName, fa.AttributeName;

-- Use with OUTER APPLY (shows companies with 0 attributes too)
SELECT
    co.CompanyName,
    fa.AttributeName,
    fa.BusinessUnitName
FROM shashank.Company co
OUTER APPLY shashank.fnGetAttributesByCompany(co.CompanyId) fa
ORDER BY co.CompanyName;
GO

-- ── Task 11: fnGetBusinessUnitReport (Multi-Statement TVF) ────
-- Comment: Inline TVF vs Multi-Statement TVF (MSTVF):
-- Inline TVF = single SELECT — SQL Server can look inside, use statistics, parallelise
-- MSTVF = BEGIN...END block — SQL Server treats it as a BLACK BOX.
--   Fixed row estimate: SQL Server assumes 1 row (pre-2014) or 100 rows (2014+)
--   regardless of actual output. This means bad join plans downstream.
-- When MSTVF is justified:
-- (1) Logic requires multiple statements (INSERT then UPDATE in body)
-- (2) You need a local temp table or variable table with indexes inside the function
-- (3) Complex conditional logic that genuinely can't be expressed as one SELECT
-- Rewrite as inline TVF whenever possible — let the optimizer see inside.

CREATE OR ALTER FUNCTION shashank.fnGetBusinessUnitReport
    (@BusinessUnitId INT)
RETURNS @Result TABLE (
    AttributeId   INT,
    AttributeName NVARCHAR(300),
    AgeCategory   NVARCHAR(20),
    DaysOld       INT,
    CompanyName   NVARCHAR(250),
    LocationName  NVARCHAR(300),
    Status        NVARCHAR(10)
)
AS
BEGIN
    -- Step 1: Insert base data
    INSERT INTO @Result (AttributeId, AttributeName, AgeCategory, DaysOld,
                         CompanyName, LocationName, Status)
    SELECT
        a.AttributeId,
        a.AttributeName,
        ''                                               AS AgeCategory,
        DATEDIFF(DAY, a.CreatedOn, GETDATE())           AS DaysOld,
        co.CompanyName,
        ISNULL(cl.CustomerLocationName, 'No Location')  AS LocationName,
        ''                                               AS Status
    FROM shashank.Attribute        a
    JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId
    LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
    WHERE a.BusinessUnitId = @BusinessUnitId;

    -- Step 2: Update AgeCategory based on DaysOld
    UPDATE @Result
    SET AgeCategory =
        CASE
            WHEN DaysOld <  90  THEN 'New'
            WHEN DaysOld <  180 THEN 'Recent'
            WHEN DaysOld <  365 THEN 'Established'
            ELSE                     'Old'
        END;

    -- Step 3: Update Status based on IsActive (re-join to source)
    UPDATE r
    SET    r.Status = CASE WHEN a.IsActive = 1 THEN 'Active' ELSE 'Inactive' END
    FROM   @Result r
    JOIN   shashank.Attribute a ON a.AttributeId = r.AttributeId;

    RETURN;
END;
GO

-- Test
SELECT * FROM shashank.fnGetBusinessUnitReport(1);
SELECT * FROM shashank.fnGetBusinessUnitReport(3);
GO

-- ============================================================
-- SECTION 5: TEMPORARY TABLES & TABLE VARIABLES
-- ============================================================

-- ── Task 12: #temp vs @table variable ────────────────────────
-- Comment: #temp table vs @table variable:
-- #temp:        stored in tempdb, visible in sub-calls (same session),
--               can have indexes, statistics, survives across statement batches
--               in same session, better for large datasets
-- @table var:   memory-scoped (may spill to tempdb), visible ONLY in current batch,
--               no statistics (1 row estimate), no explicit indexes (except PK),
--               better for small result sets or when you need automatic cleanup
-- ##global:     stored in tempdb, visible to ALL sessions until creator disconnects —
--               use only for cross-session sharing, extremely rare in app code

-- Version 1: #temp table
IF OBJECT_ID('tempdb..#AttrAgeTemp') IS NOT NULL DROP TABLE #AttrAgeTemp;

CREATE TABLE #AttrAgeTemp (
    AttributeId     INT,
    AttributeName   NVARCHAR(300),
    BusinessUnitName NVARCHAR(200),
    AgeCategory     NVARCHAR(20)
);

INSERT INTO #AttrAgeTemp
SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    CASE
        WHEN DATEDIFF(MONTH, a.CreatedOn, GETDATE()) <  3  THEN 'New'
        WHEN DATEDIFF(MONTH, a.CreatedOn, GETDATE()) <  6  THEN 'Recent'
        WHEN DATEDIFF(MONTH, a.CreatedOn, GETDATE()) < 12  THEN 'Established'
        ELSE                                                     'Old'
    END AS AgeCategory
FROM shashank.Attribute a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId;

-- Summary query
SELECT AgeCategory, COUNT(*) AS AttrCount
FROM   #AttrAgeTemp
GROUP  BY AgeCategory
ORDER  BY AttrCount DESC;

DROP TABLE #AttrAgeTemp;
GO

-- Version 2: @table variable
DECLARE @AttrAge TABLE (
    AttributeId      INT,
    AttributeName    NVARCHAR(300),
    BusinessUnitName NVARCHAR(200),
    AgeCategory      NVARCHAR(20)
);

INSERT INTO @AttrAge
SELECT
    a.AttributeId, a.AttributeName, bu.BusinessUnitName,
    CASE
        WHEN DATEDIFF(MONTH, a.CreatedOn, GETDATE()) <  3  THEN 'New'
        WHEN DATEDIFF(MONTH, a.CreatedOn, GETDATE()) <  6  THEN 'Recent'
        WHEN DATEDIFF(MONTH, a.CreatedOn, GETDATE()) < 12  THEN 'Established'
        ELSE                                                     'Old'
    END
FROM shashank.Attribute a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId;

SELECT AgeCategory, COUNT(*) AS AttrCount
FROM   @AttrAge
GROUP  BY AgeCategory
ORDER  BY AttrCount DESC;
GO

-- ============================================================
-- SECTION 6: CURSORS — SET-BASED vs ROW-BY-ROW
-- ============================================================

-- ── Task 13a: Cursor version (understand then AVOID) ──────────
-- Comment on cursors:
-- Slow because: (1) per-row context switch between storage engine and query processor
--               (2) each FETCH acquires locks individually — higher lock contention
--               (3) transaction log is written row-by-row — massive log growth
--               (4) no batch-level optimisation possible
-- LOCAL FAST_FORWARD: read-only, forward-only cursor — fastest possible cursor variant
--   (no bookmarks, no scrolling, minimal locking)
-- Legitimate cursor uses:
--   (1) Calling a SP per row (sp_send_dbmail, etc.)
--   (2) Administrative scripts: backup each database in a loop
--   (3) Sequential dependencies: row N depends on result of row N-1
-- SET-BASED should always be your FIRST and LAST resort.

CREATE OR ALTER PROCEDURE shashank.uspMarkStaleAttributes_Cursor
AS
BEGIN
    SET NOCOUNT ON;
    SET STATISTICS TIME ON;
    SET STATISTICS IO ON;

    DECLARE @AttrId    INT;
    DECLARE @CreatedOn DATETIME2;
    DECLARE @UpdatedOn DATETIME2;

    DECLARE stale_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT AttributeId, CreatedOn, UpdatedOn
        FROM   shashank.Attribute
        WHERE  IsActive = 1;

    OPEN stale_cursor;
    FETCH NEXT FROM stale_cursor INTO @AttrId, @CreatedOn, @UpdatedOn;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check: older than 1 year AND never updated
        IF DATEDIFF(YEAR, @CreatedOn, GETDATE()) >= 1
           AND @UpdatedOn IS NULL
        BEGIN
            UPDATE shashank.Attribute
            SET    IsActive  = 0,
                   UpdatedBy = 'SYSTEM_STALE',
                   UpdatedOn = GETDATE()
            WHERE  AttributeId = @AttrId;
        END;

        FETCH NEXT FROM stale_cursor INTO @AttrId, @CreatedOn, @UpdatedOn;
    END;

    CLOSE stale_cursor;
    DEALLOCATE stale_cursor;

    SET STATISTICS IO  OFF;
    SET STATISTICS TIME OFF;
END;
GO

-- ── Task 13b: Set-based version (the RIGHT way) ──────────────
CREATE OR ALTER PROCEDURE shashank.uspMarkStaleAttributes_SetBased
AS
BEGIN
    SET NOCOUNT ON;
    SET STATISTICS TIME ON;
    SET STATISTICS IO ON;

    -- One single UPDATE — SQL Server plans and optimises the whole operation
    UPDATE shashank.Attribute
    SET
        IsActive  = 0,
        UpdatedBy = 'SYSTEM_STALE',
        UpdatedOn = GETDATE()
    WHERE
        IsActive   = 1
        AND DATEDIFF(YEAR, CreatedOn, GETDATE()) >= 1
        AND UpdatedOn IS NULL;

    SET STATISTICS IO  OFF;
    SET STATISTICS TIME OFF;
END;
GO

-- ============================================================
-- SECTION 7: TRIGGERS
-- ============================================================

-- ── Task 14: Audit table + triggers ──────────────────────────
-- Comment on INSERTED/DELETED pseudo-tables:
-- INSERTED: virtual table holding NEW values — available in INSERT and UPDATE triggers
-- DELETED:  virtual table holding OLD values — available in DELETE and UPDATE triggers
-- UPDATE trigger: both INSERTED (new) and DELETED (old) exist simultaneously
-- AFTER trigger: fires AFTER the DML completes, can see final state
-- INSTEAD OF trigger: fires IN PLACE OF the DML — original statement is cancelled
-- Production risks: (1) cascading triggers (trigger A fires trigger B fires A — infinite loop)
--   (2) hidden business logic — developer reads SP but misses trigger side-effect
--   (3) performance: trigger runs in same transaction as DML, holds locks longer
--   (4) batch operations: trigger fires ONCE per statement, not once per row

-- Create audit table
IF OBJECT_ID('shashank.AttributeAudit','U') IS NULL
CREATE TABLE shashank.AttributeAudit (
    AuditId          INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_AttrAudit PRIMARY KEY,
    AttributeId      INT            NOT NULL,
    Action           NVARCHAR(10)   NOT NULL,  -- INSERT | UPDATE | DELETE
    OldAttributeName NVARCHAR(300)  NULL,
    NewAttributeName NVARCHAR(300)  NULL,
    OldIsActive      BIT            NULL,
    NewIsActive      BIT            NULL,
    ChangedBy        NVARCHAR(100)  NULL,
    ChangedOn        DATETIME2(0)   NOT NULL DEFAULT GETDATE()
);
GO

-- AFTER INSERT trigger
CREATE OR ALTER TRIGGER shashank.trgAttribute_AfterInsert
ON shashank.Attribute
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO shashank.AttributeAudit
        (AttributeId, Action, NewAttributeName, NewIsActive, ChangedBy, ChangedOn)
    SELECT
        i.AttributeId, 'INSERT', i.AttributeName, i.IsActive, i.CreatedBy, GETDATE()
    FROM INSERTED i;
END;
GO

-- AFTER UPDATE trigger
CREATE OR ALTER TRIGGER shashank.trgAttribute_AfterUpdate
ON shashank.Attribute
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Only log when AttributeName or IsActive actually changed
    INSERT INTO shashank.AttributeAudit
        (AttributeId, Action, OldAttributeName, NewAttributeName,
         OldIsActive, NewIsActive, ChangedBy, ChangedOn)
    SELECT
        i.AttributeId, 'UPDATE',
        d.AttributeName, i.AttributeName,
        d.IsActive,      i.IsActive,
        i.UpdatedBy,     GETDATE()
    FROM INSERTED i
    JOIN DELETED  d ON d.AttributeId = i.AttributeId
    WHERE i.AttributeName <> d.AttributeName   -- name changed
       OR i.IsActive      <> d.IsActive;        -- status changed
    -- If only CreatedOn or other fields changed, no row is inserted into audit
END;
GO

-- AFTER DELETE trigger
CREATE OR ALTER TRIGGER shashank.trgAttribute_AfterDelete
ON shashank.Attribute
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO shashank.AttributeAudit
        (AttributeId, Action, OldAttributeName, OldIsActive, ChangedBy, ChangedOn)
    SELECT
        d.AttributeId, 'DELETE', d.AttributeName, d.IsActive, d.UpdatedBy, GETDATE()
    FROM DELETED d;
END;
GO

-- View for INSTEAD OF trigger
CREATE OR ALTER VIEW shashank.vw_ActiveAttributes AS
    SELECT * FROM shashank.Attribute WHERE IsActive = 1;
GO

-- INSTEAD OF DELETE on view
CREATE OR ALTER TRIGGER shashank.trgActiveAttr_InsteadOfDelete
ON shashank.vw_ActiveAttributes
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Don't physically delete — soft-delete on underlying table
    UPDATE shashank.Attribute
    SET    IsActive  = 0,
           UpdatedOn = GETDATE(),
           UpdatedBy = 'SYSTEM_VIEW_DELETE'
    WHERE  AttributeId IN (SELECT AttributeId FROM DELETED);
END;
GO

-- ── Test all triggers ─────────────────────────────────────────
-- INSERT test
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('Trigger Test Attribute', 1, 1, 'TriggerTest');

-- UPDATE test: change name (should log)
UPDATE shashank.Attribute
SET AttributeName = 'Trigger Test Attribute RENAMED', UpdatedBy = 'TriggerTest'
WHERE AttributeName = 'Trigger Test Attribute';

-- UPDATE test: change only CreatedOn (should NOT log)
UPDATE shashank.Attribute
SET CreatedOn = GETDATE(), UpdatedBy = 'TriggerTest'
WHERE AttributeName = 'Trigger Test Attribute RENAMED';

-- DELETE via view (INSTEAD OF — soft delete)
DELETE FROM shashank.vw_ActiveAttributes
WHERE  AttributeName = 'Trigger Test Attribute RENAMED';

-- Hard DELETE to test AFTER DELETE trigger
DELETE FROM shashank.Attribute
WHERE  AttributeName = 'Trigger Test Attribute RENAMED';

-- Check audit log
SELECT * FROM shashank.AttributeAudit ORDER BY ChangedOn DESC;
GO

-- ============================================================
-- END OF ASSIGNMENT 4
-- All SPs, functions, triggers carry into Assignment 5
-- ============================================================
