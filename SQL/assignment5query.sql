-- ============================================================
--  ASSIGNMENT 5 — Error Handling, Transactions, Indexing & Optimization
--  Developer : Shashank Masih | Mentor: Shivam | Path 2
--  Database  : TrainingDB | Schema: shashank
--  Final SQL Assignment — database layer ready for .NET MVC
-- ============================================================

USE TrainingDB;
GO

-- ============================================================
-- SECTION 1: ERROR HANDLING — TRY...CATCH IN uspSaveAttribute
-- ============================================================

CREATE OR ALTER PROCEDURE shashank.uspSaveAttribute
    @AttributeId        INT            = NULL,
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
    SET XACT_ABORT ON;   -- auto-rollback on any error inside transaction

    SET @ResultAttributeId = -1;
    SET @ResultMessage     = '';

    -- ── Validation ────────────────────────────────────────────
    IF LTRIM(RTRIM(ISNULL(@AttributeName,''))) = ''
    BEGIN
        SET @ResultMessage = 'Validation Error: AttributeName cannot be empty.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM shashank.BusinessUnit WHERE BusinessUnitId = @BusinessUnitId)
    BEGIN
        SET @ResultMessage = 'Validation Error: BusinessUnitId ' + CAST(@BusinessUnitId AS VARCHAR) + ' does not exist.';
        RETURN;
    END;

    BEGIN TRY
        IF @AttributeId IS NULL
        BEGIN
            INSERT INTO shashank.Attribute
                (AttributeName, BusinessUnitId, CustomerLocationId, CompanyId,
                 IsActive, CreatedBy, CreatedOn)
            VALUES
                (LTRIM(RTRIM(@AttributeName)), @BusinessUnitId, @CustomerLocationId,
                 @CompanyId, @IsActive, @UpdatedBy, GETDATE());

            SET @ResultAttributeId = SCOPE_IDENTITY();
            SET @ResultMessage     = 'Insert Successful';
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM shashank.Attribute WHERE AttributeId = @AttributeId)
            BEGIN
                SET @ResultMessage = 'Validation Error: AttributeId not found.';
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
    END TRY
    BEGIN CATCH
        -- Capture full error context
        SET @ResultAttributeId = -1;
        SET @ResultMessage =
            'Error ' + CAST(ERROR_NUMBER() AS VARCHAR) +
            ' at Line '  + CAST(ERROR_LINE()    AS VARCHAR) +
            ' in '       + ISNULL(ERROR_PROCEDURE(), 'ad-hoc') +
            ': '         + ERROR_MESSAGE();

        -- If inside a transaction, roll it back
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH;
END;
GO

-- Trigger CATCH: try to insert duplicate (violates UQ_Attr_Name_BU)
DECLARE @Id INT, @Msg NVARCHAR(500);
EXEC shashank.uspSaveAttribute
    @AttributeName = 'Global Revenue Tracker',  -- already exists in BU 1
    @BusinessUnitId = 1, @CompanyId = 1, @UpdatedBy = 'test',
    @ResultAttributeId = @Id OUTPUT, @ResultMessage = @Msg OUTPUT;
SELECT @Id AS ErrorId, @Msg AS CapturedError;
-- Expected: Error 2627 (unique constraint violation) captured in @Msg
GO

-- ============================================================
-- SECTION 2: TRANSACTIONS
-- ============================================================

-- ── Task 2: uspTransferAttributes ────────────────────────────
-- Comment: Both UPDATEs MUST be in one transaction because:
-- If the server crashes between UPDATE 1 (AttributeName/BU changed)
-- and UPDATE 2 (CustomerLocationId nulled), data is inconsistent:
-- Attributes now belong to new BU but still reference old BU's locations.
-- FK relationships become orphaned or misleading.
-- A transaction guarantees ALL-or-NOTHING: both succeed or both are rolled back.

CREATE OR ALTER PROCEDURE shashank.uspTransferAttributes
    @FromBusinessUnitId INT,
    @ToBusinessUnitId   INT,
    @ResultMessage      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ResultMessage = '';

    IF NOT EXISTS (SELECT 1 FROM shashank.BusinessUnit WHERE BusinessUnitId = @ToBusinessUnitId)
    BEGIN
        SET @ResultMessage = 'Error: Target BusinessUnitId ' + CAST(@ToBusinessUnitId AS VARCHAR) + ' does not exist.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: move all attributes to new BU
        UPDATE shashank.Attribute
        SET    BusinessUnitId = @ToBusinessUnitId,
               UpdatedOn      = GETDATE(),
               UpdatedBy      = 'TRANSFER'
        WHERE  BusinessUnitId = @FromBusinessUnitId;

        -- Step 2: null out locations (they are BU-specific)
        UPDATE shashank.Attribute
        SET    CustomerLocationId = NULL,
               UpdatedOn          = GETDATE(),
               UpdatedBy          = 'TRANSFER'
        WHERE  BusinessUnitId = @ToBusinessUnitId;

        COMMIT TRANSACTION;
        SET @ResultMessage = 'Transfer Successful: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' attributes moved.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ResultMessage = 'Transfer Failed: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ── Task 3: uspBulkUpdateAttributes (SAVEPOINT) ───────────────
-- Comment: SAVEPOINT vs full ROLLBACK:
-- ROLLBACK TRANSACTION (no name): undoes EVERYTHING, resets @@TRANCOUNT to 0
-- ROLLBACK TRANSACTION <savepoint>: undoes only back to that point,
--   @@TRANCOUNT unchanged — outer transaction still open and can COMMIT
-- Limitations of savepoints:
--   (1) Cannot COMMIT a savepoint — only the outer BEGIN TRANSACTION commits
--   (2) Don't survive distributed transactions (MS DTC)
--   (3) Not supported in all database engines (SQL Server yes, some others no)

CREATE OR ALTER PROCEDURE shashank.uspBulkUpdateAttributes
    @BU1 INT,
    @BU2 INT,
    @BU3 INT,
    @ResultMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ResultMessage = '';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: Update BU1
        SAVE TRANSACTION SP_BU1;
        UPDATE shashank.Attribute
        SET UpdatedBy = 'BULK_BU1', UpdatedOn = GETDATE()
        WHERE BusinessUnitId = @BU1;
        SET @ResultMessage += 'BU1 updated. ';

        -- Step 2: Update BU2 (may fail if BU2 has no attributes)
        SAVE TRANSACTION SP_BU2;
        IF NOT EXISTS (SELECT 1 FROM shashank.Attribute WHERE BusinessUnitId = @BU2)
        BEGIN
            -- Simulate failure: rollback only BU2's work
            ROLLBACK TRANSACTION SP_BU2;
            SET @ResultMessage += 'BU2 skipped (no attributes — rolled back to SP_BU2). ';
        END
        ELSE
        BEGIN
            UPDATE shashank.Attribute
            SET UpdatedBy = 'BULK_BU2', UpdatedOn = GETDATE()
            WHERE BusinessUnitId = @BU2;
            SET @ResultMessage += 'BU2 updated. ';
        END;

        -- Step 3: Update BU3 (always proceeds)
        SAVE TRANSACTION SP_BU3;
        UPDATE shashank.Attribute
        SET UpdatedBy = 'BULK_BU3', UpdatedOn = GETDATE()
        WHERE BusinessUnitId = @BU3;
        SET @ResultMessage += 'BU3 updated. ';

        COMMIT TRANSACTION;
        SET @ResultMessage += 'Transaction committed.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ResultMessage = 'Fatal error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- Test: BU1=1 (has attrs), BU2=9999 (no attrs—rolled back), BU3=3 (has attrs)
DECLARE @msg NVARCHAR(500);
EXEC shashank.uspBulkUpdateAttributes @BU1=1, @BU2=9999, @BU3=3, @ResultMessage=@msg OUTPUT;
SELECT @msg AS BulkResult;
GO

-- ── Task 4: ACID + Isolation Levels ──────────────────────────
/*
ACID EXPLANATION (with Attribute schema examples):

ATOMICITY — All or nothing.
  Example: uspTransferAttributes moves Attributes AND nulls LocationIds.
  If the second UPDATE fails, the first is rolled back. No partial state.

CONSISTENCY — Transaction takes DB from one valid state to another.
  Example: FK constraint ensures every Attribute.BusinessUnitId exists in BusinessUnit.
  A transaction violating this is rolled back — DB stays consistent.

ISOLATION — Concurrent transactions don't see each other's intermediate state.
  Example: Session A updating Attribute 1; Session B reading Attribute 1
  sees either the old value or the new value — never a half-written state.

DURABILITY — Committed transactions survive crashes.
  Example: After uspSaveAttribute commits, even if SQL Server crashes,
  the new Attribute is in the database when it restarts (write-ahead log).

ISOLATION LEVELS (run these in two SSMS windows):

── READ UNCOMMITTED (dirty read demo) ──
-- Session A:
BEGIN TRANSACTION;
UPDATE shashank.Attribute SET AttributeName = 'DIRTY VALUE' WHERE AttributeId = 1;
-- DO NOT COMMIT YET

-- Session B:
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT AttributeName FROM shashank.Attribute WHERE AttributeId = 1;
-- Returns 'DIRTY VALUE' even though A hasn't committed — DIRTY READ

-- Session A:
ROLLBACK;
-- Session B now reads old value if it runs again — dirty read caused a lie

── READ COMMITTED (SQL Server default) ──
-- Session A: Same UPDATE, don't commit
-- Session B:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT AttributeName FROM shashank.Attribute WHERE AttributeId = 1;
-- Session B BLOCKS until Session A commits or rolls back

── REPEATABLE READ ──
-- Session A:
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
SELECT AttributeName FROM shashank.Attribute WHERE AttributeId = 1; -- first read

-- Session B tries to UPDATE same row → BLOCKED until A commits
-- Session A reads again → same value as first read (no non-repeatable read)
COMMIT;

── SERIALIZABLE ──
-- Session A:
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
SELECT COUNT(*) FROM shashank.Attribute WHERE BusinessUnitId = 1; -- range lock acquired

-- Session B: INSERT INTO shashank.Attribute (BU=1...) → BLOCKED (range lock = phantom prevention)
-- Under REPEATABLE READ, Session B INSERT would succeed → phantom read possible
COMMIT;

── SNAPSHOT (row versioning) ──
-- Enable once per database:
ALTER DATABASE TrainingDB SET ALLOW_SNAPSHOT_ISOLATION ON;
-- Session B:
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
SELECT AttributeName FROM shashank.Attribute WHERE AttributeId = 1;
-- Reads last committed version from tempdb row-version store — no blocking, no dirty read
-- Cost: tempdb stores old row versions — more tempdb I/O under high update load
*/

-- ── Task 4: XACT_ABORT demo ───────────────────────────────────
CREATE OR ALTER PROCEDURE shashank.uspXactAbortDemo
    @UseXactAbort BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF @UseXactAbort = 1 SET XACT_ABORT ON ELSE SET XACT_ABORT OFF;

    BEGIN TRANSACTION;

    -- First INSERT (valid)
    INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
    VALUES ('XactAbort Test', 1, 1, 'XactTest');

    -- Second INSERT (violates FK — CompanyId 9999 doesn't exist)
    INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
    VALUES ('XactAbort Test 2', 1, 9999, 'XactTest');  -- FK violation

    -- With XACT_ABORT OFF: error is thrown but first INSERT may persist
    -- With XACT_ABORT ON: entire transaction rolled back automatically, no partial state
    COMMIT TRANSACTION;
END;
GO

-- Run with XACT_ABORT OFF
EXEC shashank.uspXactAbortDemo @UseXactAbort = 0;
SELECT * FROM shashank.Attribute WHERE CreatedBy = 'XactTest'; -- may show first row
DELETE FROM shashank.Attribute WHERE CreatedBy = 'XactTest';   -- cleanup

-- Run with XACT_ABORT ON
EXEC shashank.uspXactAbortDemo @UseXactAbort = 1;
SELECT * FROM shashank.Attribute WHERE CreatedBy = 'XactTest'; -- 0 rows — fully rolled back
GO

-- ============================================================
-- SECTION 3: DELIBERATE BUGS
-- ============================================================

-- ── Bug A: UPDATE without WHERE ──────────────────────────────
-- Demonstration (DO NOT RUN in production without a transaction):
BEGIN TRANSACTION;

-- BUG: This updates ALL rows
UPDATE shashank.Attribute SET IsActive = 0;
-- Result: all 22+ attributes now inactive — catastrophic

SELECT COUNT(*) AS AllDeactivated FROM shashank.Attribute WHERE IsActive = 0; -- all rows

ROLLBACK TRANSACTION; -- undo the damage
-- Prevention:
-- (1) Always wrap destructive ops in a transaction before running
-- (2) Use SET ROWCOUNT 1 during testing
-- (3) Run SELECT with same WHERE first to see affected rows
-- (4) Enable: SSMS → Tools → Options → Query Execution → Prevent saving changes that require re-creation
GO

-- ── Bug B: FK constraint violation in TRY...CATCH ─────────────
BEGIN TRY
    -- CompanyId 9999 doesn't exist — FK violation
    INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
    VALUES ('FK Violation Test', 1, 9999, 'BugTest');
    PRINT 'Insert succeeded';
END TRY
BEGIN CATCH
    PRINT 'Error captured!';
    PRINT 'Error Number: '    + CAST(ERROR_NUMBER()    AS VARCHAR);
    PRINT 'Error Severity: '  + CAST(ERROR_SEVERITY()  AS VARCHAR);
    PRINT 'Error State: '     + CAST(ERROR_STATE()     AS VARCHAR);
    PRINT 'Error Line: '      + CAST(ERROR_LINE()      AS VARCHAR);
    PRINT 'Error Message: '   + ERROR_MESSAGE();
    -- Expected: Error 547 — INSERT conflicted with FOREIGN KEY constraint
END CATCH;
GO

-- ============================================================
-- SECTION 4: INDEXING & EXECUTION PLANS
-- ============================================================

-- ── Task 6: Baseline query — NO indexes ──────────────────────
-- Run this, then press Ctrl+M to include actual execution plan
-- Expected plan without indexes: Table Scan or Clustered Index Scan

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT a.AttributeName, bu.BusinessUnitName
FROM   shashank.Attribute     a
JOIN   shashank.BusinessUnit  bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  a.AttributeName LIKE '%Global%';
-- Note the logical reads, scan count in STATISTICS IO output

SET STATISTICS IO  OFF;
SET STATISTICS TIME OFF;
GO

-- ── Task 7: Create indexes ────────────────────────────────────
-- Comment: Clustered index (on AttributeId PK) doesn't help LIKE '%Global%' because:
-- (1) Clustered index orders rows by AttributeId — no alphabetical order on name
-- (2) Leading wildcard (%) prevents range scan on AttributeName anyway
-- (3) Full-text indexing is better for LIKE '%...%' at scale

-- Non-clustered index on AttributeName
CREATE NONCLUSTERED INDEX IX_Attribute_AttributeName
ON shashank.Attribute (AttributeName);

-- Covering index: AttributeId as key, include AttributeName
CREATE NONCLUSTERED INDEX IX_Attribute_BusinessUnitId_Cover
ON shashank.Attribute (BusinessUnitId)
INCLUDE (AttributeName, IsActive, CreatedOn, CompanyId, CustomerLocationId);
-- A COVERING INDEX means the query engine can satisfy the query entirely
-- from the index without going back to the base table (no Key Lookup)

-- Composite index for filter queries
CREATE NONCLUSTERED INDEX IX_Attribute_BU_IsActive
ON shashank.Attribute (BusinessUnitId, IsActive);
GO

-- Re-run query after indexes — compare execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT a.AttributeName, bu.BusinessUnitName
FROM   shashank.Attribute     a
JOIN   shashank.BusinessUnit  bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  a.AttributeName LIKE '%Global%';
-- Note: IX_Attribute_AttributeName may be used for the LIKE
-- but leading % still forces a scan of the index (not a seek)
-- The covering index on BusinessUnitId avoids Key Lookup for the JOIN

SET STATISTICS IO  OFF;
SET STATISTICS TIME OFF;
GO

-- ── Task 8: Slow query vs SARGable rewrite ────────────────────
-- Comment: SARGable = Search ARGument ABLE
-- A predicate is SARGable if SQL Server can use an index SEEK on it
-- Non-SARGable predicates: functions on indexed columns (YEAR(col), UPPER(col))
-- Why: function call wraps the column — SQL Server can't use the index range
-- Equivalents without function:
--   YEAR(CreatedOn) = 2023  →  CreatedOn >= '2023-01-01' AND CreatedOn < '2024-01-01'

-- SLOW: function in WHERE — non-SARGable, forces index/table scan
SET STATISTICS IO ON;
SELECT a.AttributeName, bu.BusinessUnitName, a.CreatedOn
FROM   shashank.Attribute    a
JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  YEAR(a.CreatedOn) = 2023
AND    a.AttributeName LIKE '%Data%'
ORDER  BY a.CreatedOn DESC;

-- FAST: SARGable date range — allows index SEEK on CreatedOn
SELECT a.AttributeName, bu.BusinessUnitName, a.CreatedOn
FROM   shashank.Attribute    a
JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  a.CreatedOn >= '2023-01-01'
AND    a.CreatedOn  < '2024-01-01'
AND    a.AttributeName LIKE '%Data%'
ORDER  BY a.CreatedOn DESC;
SET STATISTICS IO OFF;
GO

-- ============================================================
-- SECTION 5: DYNAMIC SQL
-- ============================================================

-- Comment on SQL Injection:
-- First version: string concatenation lets attacker inject SQL
-- Input: @SearchValue = "'; DROP TABLE shashank.Attribute; --"
-- Result: SELECT * FROM ... WHERE col LIKE '%'; DROP TABLE ...; --%'
-- sp_executesql with @params PREVENTS value injection because values are
-- passed as parameters — SQL Server treats them as DATA not CODE
-- Limitation: table/column names CANNOT be parameterised in sp_executesql
-- They must come from a whitelist (IF @TableName NOT IN ('AllowedTable1'...) RAISERROR)

CREATE OR ALTER PROCEDURE shashank.uspDynamicSearch
    @TableName   NVARCHAR(100),
    @ColumnName  NVARCHAR(100),
    @SearchValue NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Whitelist validation for table and column names ───────
    -- (prevents injection via object names — sp_executesql can't parameterise these)
    IF @TableName NOT IN ('shashank.Attribute', 'shashank.BusinessUnit', 'shashank.Company')
    BEGIN
        RAISERROR('Unauthorised table name: %s', 16, 1, @TableName);
        RETURN;
    END;

    -- ── WRONG WAY: string concatenation (SQL injection risk) ──
    -- DECLARE @BadSQL NVARCHAR(MAX);
    -- SET @BadSQL = 'SELECT * FROM ' + @TableName + ' WHERE ' + @ColumnName + ' LIKE ''%' + @SearchValue + '%''';
    -- EXEC(@BadSQL);
    -- ^ Attacker can inject via @SearchValue or @ColumnName

    -- ── RIGHT WAY: sp_executesql with parameters ──────────────
    DECLARE @SafeSQL  NVARCHAR(MAX);
    DECLARE @Params   NVARCHAR(500);
    DECLARE @LikeVal  NVARCHAR(202) = '%' + @SearchValue + '%';

    -- Column name still needs sanitisation (can't be a parameter)
    -- Real production code: validate @ColumnName against sys.columns
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN   sys.objects o ON o.object_id = c.object_id
        WHERE  c.name = @ColumnName
    )
    BEGIN
        RAISERROR('Column not found: %s', 16, 1, @ColumnName);
        RETURN;
    END;

    SET @SafeSQL = N'SELECT * FROM ' + @TableName +
                   N' WHERE ' + QUOTENAME(@ColumnName) + N' LIKE @SearchParam';
    SET @Params  = N'@SearchParam NVARCHAR(202)';

    EXEC sp_executesql @SafeSQL, @Params, @SearchParam = @LikeVal;
END;
GO

-- Test safe version
EXEC shashank.uspDynamicSearch
    @TableName   = 'shashank.Attribute',
    @ColumnName  = 'AttributeName',
    @SearchValue = 'Global';

-- Test injection attempt (blocked by whitelist)
EXEC shashank.uspDynamicSearch
    @TableName   = 'sys.tables',   -- not in whitelist
    @ColumnName  = 'name',
    @SearchValue = 'Attribute';
GO

-- ============================================================
-- SECTION 6: WINDOW FUNCTIONS (Assignment 3 complete SQL)
-- ============================================================

-- ── Task 1a: ROW_NUMBER ────────────────────────────────────────
SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    ROW_NUMBER() OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn DESC
    ) AS RowNumInBU
FROM shashank.Attribute a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, RowNumInBU;

-- Most recent per BU using ROW_NUMBER in CTE
WITH Ranked AS (
    SELECT
        a.AttributeId, a.AttributeName, bu.BusinessUnitName, a.CreatedOn,
        ROW_NUMBER() OVER (PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn DESC) AS RN
    FROM shashank.Attribute a
    JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
)
SELECT * FROM Ranked WHERE RN = 1;
GO

-- ── Task 1b: RANK vs DENSE_RANK ───────────────────────────────
-- Comment: RANK vs DENSE_RANK matters when:
-- RANK: gap after ties (1,1,3 — position 2 is skipped)
-- DENSE_RANK: no gap (1,1,2) — use when you need "top N unique positions"
-- Real example: Top 3 salary bands — RANK would skip positions after ties,
-- DENSE_RANK gives consecutive band numbers.

-- Insert tie rows
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy, CreatedOn)
VALUES ('Tied Attribute X', 1, 1, 'TieTest', '2024-06-10'),
       ('Tied Attribute Y', 1, 1, 'TieTest', '2024-06-10');  -- same CreatedOn

SELECT
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    ROW_NUMBER()  OVER (PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn) AS RowNum,
    RANK()        OVER (PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn) AS RankVal,
    DENSE_RANK()  OVER (PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn) AS DenseRankVal
FROM shashank.Attribute a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE a.BusinessUnitId = 1
ORDER BY a.CreatedOn;

DELETE FROM shashank.Attribute WHERE CreatedBy = 'TieTest';
GO

-- ── Task 1c: NTILE(4) ─────────────────────────────────────────
-- Comment: NTILE with uneven division — extra rows go to LOWER-numbered buckets.
-- 22 rows / 4 quartiles = 5 each with 2 extras → buckets 1 and 2 get 6 rows each.
-- Useful for: percentile analysis, A/B testing grouping, performance tiering.

SELECT
    a.AttributeName,
    a.CreatedOn,
    NTILE(4) OVER (ORDER BY a.CreatedOn) AS Quartile
FROM shashank.Attribute a
ORDER BY Quartile, a.CreatedOn;
GO

-- ── Task 1d: LAG and LEAD ──────────────────────────────────────
-- Comment: At first row, LAG returns NULL (no previous row).
-- At last row, LEAD returns NULL (no next row).
-- Handle with: ISNULL(LAG(col,1,default_val) OVER (...), 'First Record')
-- or COALESCE(LAG(col) OVER (...), 'N/A')

SELECT
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    LAG(a.AttributeName,  1, 'FIRST IN BU') OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn
    ) AS PreviousAttributeName,
    LEAD(a.AttributeName, 1, 'LAST IN BU')  OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn
    ) AS NextAttributeName
FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

-- ── Task 2: Analytical queries ────────────────────────────────
-- Comment: ROWS BETWEEN vs RANGE BETWEEN:
-- ROWS: physical rows in the window frame (offset by row count)
-- RANGE: logical range (all rows with same ORDER BY value included together)
-- Difference matters when ORDER BY has ties:
-- ROWS BETWEEN 1 PRECEDING AND CURRENT ROW: always exactly 2 rows
-- RANGE BETWEEN 1 PRECEDING AND CURRENT ROW: may include many rows if values tie
-- Use ROWS for moving averages; use RANGE for "up to today" cumulative totals.

-- Running count within BU
SELECT
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    COUNT(*) OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningCountInBU,
    -- Running percentage of BU total
    CAST(
        COUNT(*) OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS DECIMAL(10,2)
    ) /
    COUNT(*) OVER (PARTITION BY a.BusinessUnitId) * 100 AS RunningPctOfBU
FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

-- Moving average (3-month window)
WITH MonthlyAgg AS (
    SELECT
        YEAR(CreatedOn)  AS Yr,
        MONTH(CreatedOn) AS Mo,
        COUNT(*)         AS AttrCount
    FROM shashank.Attribute
    GROUP BY YEAR(CreatedOn), MONTH(CreatedOn)
)
SELECT
    Yr, Mo, AttrCount,
    AVG(CAST(AttrCount AS DECIMAL(10,2))) OVER (
        ORDER BY Yr, Mo
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3Month
FROM MonthlyAgg
ORDER BY Yr, Mo;
GO

-- Days since previous attribute in same BU
SELECT
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    LAG(a.CreatedOn) OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn
    ) AS PrevCreatedOn,
    DATEDIFF(DAY,
        LAG(a.CreatedOn) OVER (PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn),
        a.CreatedOn
    ) AS DaysSincePrevious
FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

-- ── Task 3: ROW_NUMBER + PIVOT — top 3 per BU ─────────────────
-- Comment: ROW_NUMBER + PIVOT is common because:
-- Pure PIVOT can't limit rows per group — it aggregates ALL rows
-- ROW_NUMBER first labels rows (1,2,3) per partition,
-- then PIVOT spreads numbered rows into columns.
-- Alternative: conditional aggregation with CASE WHEN RN=1...

WITH TopN AS (
    SELECT
        bu.BusinessUnitName,
        a.AttributeName,
        ROW_NUMBER() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn DESC
        ) AS RN
    FROM shashank.Attribute    a
    JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
)
SELECT
    BusinessUnitName,
    [1] AS MostRecent_1,
    [2] AS MostRecent_2,
    [3] AS MostRecent_3
FROM TopN
WHERE RN <= 3
PIVOT (
    MAX(AttributeName)
    FOR RN IN ([1],[2],[3])
) AS Pvt
ORDER BY BusinessUnitName;
GO

DESKTOP-3T4LC6O WIFI
