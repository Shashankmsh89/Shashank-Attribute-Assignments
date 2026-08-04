-- ============================================================
--  ASSIGNMENT 2 — Advanced Queries
--  Developer : Shashank Masih | Mentor: Shivam | Path 2
--  Database  : TrainingDB | Schema: shashank
--  Builds on : Assignment 1 tables and data
-- ============================================================

USE TrainingDB;
GO

-- ============================================================
-- SECTION 1: ADVANCED AGGREGATION & GROUP BY
-- ============================================================

-- ── Task 1a: Multi-level GROUP BY ────────────────────────────

-- Level 1: Count by BU + IsActive
SELECT
    bu.BusinessUnitName,
    a.IsActive,
    COUNT(a.AttributeId) AS AttributeCount
FROM shashank.BusinessUnit bu
LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitName, a.IsActive
ORDER BY bu.BusinessUnitName, a.IsActive DESC;
GO

-- Level 2: Active vs Inactive SIDE BY SIDE per BU (PIVOT style with CASE)
SELECT
    bu.BusinessUnitName,
    SUM(CASE WHEN a.IsActive = 1 THEN 1 ELSE 0 END) AS ActiveCount,
    SUM(CASE WHEN a.IsActive = 0 THEN 1 ELSE 0 END) AS InactiveCount,
    COUNT(a.AttributeId)                              AS TotalCount
FROM shashank.BusinessUnit bu
LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitName
ORDER BY bu.BusinessUnitName;
GO

-- Level 3: Add CompanyName as third grouping level
SELECT
    bu.BusinessUnitName,
    co.CompanyName,
    a.IsActive,
    COUNT(a.AttributeId) AS AttributeCount
FROM shashank.Attribute a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
JOIN shashank.Company      co ON co.CompanyId      = a.CompanyId
GROUP BY bu.BusinessUnitName, co.CompanyName, a.IsActive
ORDER BY bu.BusinessUnitName, co.CompanyName, a.IsActive DESC;
GO

-- ── Task 1b: WITH ROLLUP ──────────────────────────────────────
-- Comment: NULL rows in ROLLUP mean:
--   - NULL in IsActive column = subtotal for that BU (all active + inactive combined)
--   - NULL in both BusinessUnitName AND IsActive = GRAND TOTAL row
-- To distinguish ROLLUP-generated NULL from real NULL:
--   Use GROUPING(column) → returns 1 if NULL was introduced by ROLLUP, 0 if real NULL
--   Or use GROUPING_ID(bu, isActive) for a bitmask of which columns are ROLLUP nulls

SELECT
    CASE GROUPING(bu.BusinessUnitName)
         WHEN 1 THEN '** GRAND TOTAL **'
         ELSE bu.BusinessUnitName
    END AS BusinessUnitName,
    CASE GROUPING(a.IsActive)
         WHEN 1 THEN NULL   -- subtotal row — no specific status
         ELSE a.IsActive
    END AS IsActive,
    COUNT(a.AttributeId)        AS AttributeCount,
    GROUPING(bu.BusinessUnitName) AS IsRollupBU,
    GROUPING(a.IsActive)          AS IsRollupStatus
FROM shashank.BusinessUnit bu
LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitName, a.IsActive WITH ROLLUP
ORDER BY bu.BusinessUnitName, a.IsActive;
GO

-- ── Task 1c: WITH CUBE ────────────────────────────────────────
-- Comment: CUBE vs ROLLUP:
--   ROLLUP produces subtotals along ONE hierarchy (A→B→GrandTotal).
--   CUBE produces ALL possible combinations of subtotals for ALL columns
--   (BU only, Status only, BU+Status, GrandTotal) — 2^N combinations for N columns.
--   Use ROLLUP when data has a natural hierarchy (Year>Month>Day).
--   Use CUBE when you need every cross-dimensional subtotal (like OLAP/BI reports).

SELECT
    ISNULL(bu.BusinessUnitName, '** ALL BUs **') AS BusinessUnitName,
    CASE
        WHEN GROUPING(a.IsActive) = 1 THEN 'ALL'
        WHEN a.IsActive = 1           THEN 'Active'
        ELSE                               'Inactive'
    END AS StatusLabel,
    COUNT(a.AttributeId)           AS AttributeCount,
    GROUPING(bu.BusinessUnitName)  AS IsCubeAllBUs,
    GROUPING(a.IsActive)           AS IsCubeAllStatus
FROM shashank.BusinessUnit bu
LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitName, a.IsActive WITH CUBE
ORDER BY bu.BusinessUnitName, a.IsActive;
GO

-- ── Task 1d: GROUPING SETS ────────────────────────────────────
-- Produces exactly the groupings you specify — no extras like CUBE

SELECT
    CASE GROUPING(bu.BusinessUnitName)
         WHEN 0 THEN bu.BusinessUnitName ELSE NULL END AS BusinessUnitName,
    CASE GROUPING(co.CompanyName)
         WHEN 0 THEN co.CompanyName ELSE NULL END      AS CompanyName,
    COUNT(a.AttributeId)                               AS AttributeCount,
    CASE
        WHEN GROUPING(bu.BusinessUnitName) = 0 AND GROUPING(co.CompanyName) = 1
             THEN 'By BU'
        WHEN GROUPING(bu.BusinessUnitName) = 1 AND GROUPING(co.CompanyName) = 0
             THEN 'By Company'
        WHEN GROUPING(bu.BusinessUnitName) = 1 AND GROUPING(co.CompanyName) = 1
             THEN 'Grand Total'
        ELSE      'By BU + Company'
    END AS GroupingLabel
FROM shashank.Attribute a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
JOIN shashank.Company      co ON co.CompanyId      = a.CompanyId
GROUP BY GROUPING SETS (
    (bu.BusinessUnitName),   -- (a) total per BU
    (co.CompanyName),        -- (b) total per Company
    ()                       -- (c) grand total
)
ORDER BY GroupingLabel, BusinessUnitName, CompanyName;
GO

-- ── Task 1e: Filtered aggregation with HAVING + subquery ──────
--
-- Comment — SQL Execution Order (logical, not physical):
-- 1. FROM / JOIN   — identify source tables and join them
-- 2. WHERE         — filter individual rows (no aggregates allowed here)
-- 3. GROUP BY      — group filtered rows
-- 4. HAVING        — filter groups (aggregates allowed)
-- 5. SELECT        — compute output columns and expressions
-- 6. ORDER BY      — sort final result
-- 7. TOP/OFFSET    — limit rows returned
--
-- This order matters because:
-- - You cannot use a column alias from SELECT in a WHERE clause (alias doesn't exist yet)
-- - You cannot filter on COUNT() in WHERE — only in HAVING (GROUP BY hasn't happened yet)
-- - ORDER BY can reference SELECT aliases because it executes last

SELECT
    bu.BusinessUnitName,
    COUNT(CASE WHEN a.IsActive = 1 THEN 1 END) AS ActiveCount
FROM shashank.BusinessUnit bu
JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitName, bu.BusinessUnitId
HAVING
    COUNT(CASE WHEN a.IsActive = 1 THEN 1 END) > 2
    AND bu.BusinessUnitId IN (
        -- Subquery: BUs with at least one Attribute created in last 3 months
        SELECT DISTINCT BusinessUnitId
        FROM   shashank.Attribute
        WHERE  CreatedOn >= DATEADD(MONTH, -36, GETDATE()) -- using 36 months as data is historical
    )
ORDER BY ActiveCount DESC;
GO

-- ============================================================
-- SECTION 2: PIVOT & UNPIVOT
-- ============================================================

-- ── Task 2a: Cross-tab PIVOT — BU rows × Company columns ─────
-- Comment: PIVOT internally groups by all non-pivot, non-aggregate columns,
-- then spreads distinct values of the pivot column as new column headers.
-- CASE + GROUP BY equivalent:
--   SELECT BUName,
--          SUM(CASE WHEN co = 'GlobalTech' THEN 1 ELSE 0 END) AS [GlobalTech], ...
--   GROUP BY BUName
-- PIVOT is more concise but requires hard-coding column values.
-- CASE + GROUP BY is more flexible for dynamic values.

SELECT BusinessUnitName,
       ISNULL([GlobalTech Solutions], 0) AS [GlobalTech Solutions],
       ISNULL([DataBridge Pvt Ltd],   0) AS [DataBridge Pvt Ltd],
       ISNULL([Nexus Enterprises],    0) AS [Nexus Enterprises],
       ISNULL([BlueCore Systems],     0) AS [BlueCore Systems],
       ISNULL([Vertex Analytics],     0) AS [Vertex Analytics]
FROM (
    SELECT bu.BusinessUnitName, co.CompanyName, a.AttributeId
    FROM   shashank.Attribute a
    JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
    JOIN   shashank.Company      co ON co.CompanyId      = a.CompanyId
) AS Src
PIVOT (
    COUNT(AttributeId)
    FOR CompanyName IN (
        [GlobalTech Solutions],[DataBridge Pvt Ltd],[Nexus Enterprises],
        [BlueCore Systems],[Vertex Analytics]
    )
) AS Pvt
ORDER BY BusinessUnitName;
GO

-- ── Task 2b: Monthly summary PIVOT — BU rows × Month columns ──
SELECT BusinessUnitName,
       ISNULL([Jan],0) AS Jan, ISNULL([Feb],0) AS Feb,
       ISNULL([Mar],0) AS Mar, ISNULL([Apr],0) AS Apr,
       ISNULL([May],0) AS May, ISNULL([Jun],0) AS Jun,
       ISNULL([Jul],0) AS Jul, ISNULL([Aug],0) AS Aug,
       ISNULL([Sep],0) AS Sep, ISNULL([Oct],0) AS Oct,
       ISNULL([Nov],0) AS Nov, ISNULL([Dec],0) AS Dec
FROM (
    SELECT bu.BusinessUnitName,
           LEFT(DATENAME(MONTH, a.CreatedOn), 3) AS MonthAbbr,
           a.AttributeId
    FROM   shashank.Attribute a
    JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
) AS Src
PIVOT (
    COUNT(AttributeId)
    FOR MonthAbbr IN ([Jan],[Feb],[Mar],[Apr],[May],[Jun],
                      [Jul],[Aug],[Sep],[Oct],[Nov],[Dec])
) AS Pvt
ORDER BY BusinessUnitName;
GO

-- ── Task 2c: Status PIVOT — Active vs Inactive per BU ─────────
SELECT BusinessUnitName,
       ISNULL([1], 0) AS ActiveCount,
       ISNULL([0], 0) AS InactiveCount
FROM (
    SELECT bu.BusinessUnitName, a.IsActive, a.AttributeId
    FROM   shashank.Attribute a
    JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
) AS Src
PIVOT (
    COUNT(AttributeId)
    FOR IsActive IN ([1],[0])
) AS Pvt
ORDER BY BusinessUnitName;
GO

-- ── Task 3: UNPIVOT ───────────────────────────────────────────
-- Comment: UNPIVOT is useful when:
-- - Legacy systems export wide tables (one column per month/status)
-- - Reporting tools (PowerBI, SSRS) need tall/narrow format
-- - You need to import wide Excel data into a narrow normalized table

WITH StatusWide AS (
    SELECT BusinessUnitName,
           CAST(ISNULL([1], 0) AS INT) AS ActiveCount,
           CAST(ISNULL([0], 0) AS INT) AS InactiveCount
    FROM (
        SELECT bu.BusinessUnitName, a.IsActive, a.AttributeId
        FROM   shashank.Attribute a
        JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
    ) AS Src
    PIVOT (COUNT(AttributeId) FOR IsActive IN ([1],[0])) AS Pvt
)
SELECT BusinessUnitName, StatusType, StatusValue
FROM   StatusWide
UNPIVOT (
    StatusValue FOR StatusType IN (ActiveCount, InactiveCount)
) AS Upvt
ORDER BY BusinessUnitName, StatusType;
GO

-- Rewrite using CROSS APPLY with VALUES
-- Comment: CROSS APPLY is more flexible — can add computed rows (Total),
-- works without requiring all columns to share the same type,
-- and is easier to extend than UNPIVOT syntax.

WITH StatusWide AS (
    SELECT bu.BusinessUnitName,
           SUM(CASE WHEN a.IsActive = 1 THEN 1 ELSE 0 END) AS ActiveCount,
           SUM(CASE WHEN a.IsActive = 0 THEN 1 ELSE 0 END) AS InactiveCount
    FROM   shashank.Attribute a
    JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
    GROUP  BY bu.BusinessUnitName
)
SELECT s.BusinessUnitName, x.StatusType, x.StatusValue
FROM   StatusWide s
CROSS  APPLY (VALUES
    ('ActiveCount',   s.ActiveCount),
    ('InactiveCount', s.InactiveCount),
    ('TotalCount',    s.ActiveCount + s.InactiveCount)
) AS x(StatusType, StatusValue)
ORDER BY s.BusinessUnitName, x.StatusType;
GO

-- ============================================================
-- SECTION 3: JOINS
-- ============================================================

-- ── Task 4a: INNER JOIN ───────────────────────────────────────
SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    cl.CustomerLocationName,
    co.CompanyName,
    a.IsActive,
    a.CreatedOn
FROM shashank.Attribute        a
JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId
ORDER BY bu.BusinessUnitName, a.AttributeName;
GO

-- ── Task 4b: LEFT JOIN — All BUs including those with 0 attrs ──
SELECT
    bu.BusinessUnitName,
    COUNT(a.AttributeId) AS AttributeCount
FROM shashank.BusinessUnit bu
LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitName
ORDER BY AttributeCount DESC;
GO

-- ── Task 4c: RIGHT JOIN (same result, different table order) ───
-- Comment: RIGHT JOIN = swap table positions and use LEFT JOIN.
-- LEFT JOIN is universally preferred because:
-- (1) It reads naturally left-to-right (start from main table)
-- (2) Mixing LEFT and RIGHT in one query is confusing to read
-- Most teams/linters enforce LEFT JOIN only as a convention.

SELECT
    bu.BusinessUnitName,
    COUNT(a.AttributeId) AS AttributeCount
FROM shashank.Attribute a
RIGHT JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
GROUP BY bu.BusinessUnitName
ORDER BY AttributeCount DESC;
GO

-- ── Task 4d: FULL OUTER JOIN ──────────────────────────────────
-- Comment: FULL OUTER JOIN real-world use:
-- Data reconciliation — compare two systems to find rows in A not in B
-- and rows in B not in A in a single query.
-- E.g., compare HR system employees vs Payroll system employees.

SELECT
    bu.BusinessUnitName,
    co.CompanyName,
    COUNT(a.AttributeId) AS LinkCount
FROM      shashank.BusinessUnit bu
FULL OUTER JOIN shashank.Attribute a  ON a.BusinessUnitId = bu.BusinessUnitId
FULL OUTER JOIN shashank.Company   co ON co.CompanyId     = a.CompanyId
GROUP BY bu.BusinessUnitName, co.CompanyName
ORDER BY bu.BusinessUnitName, co.CompanyName;
GO

-- ── Task 4e: CROSS JOIN — all BU × Company combinations ───────
-- Comment: Useful for generating test data, creating a complete matrix
-- for a report (show 0s not just present combinations), or building
-- calendars. DANGEROUS on large tables: 1000 rows × 1000 rows = 1M result rows.

SELECT
    bu.BusinessUnitName,
    co.CompanyName,
    bu.BusinessUnitId,
    co.CompanyId
FROM shashank.BusinessUnit bu
CROSS JOIN shashank.Company co
ORDER BY bu.BusinessUnitName, co.CompanyName;
GO

-- ── Task 4f: Self-Join — same BU, different Companies ─────────
SELECT
    a1.AttributeName AS Attribute1,
    a2.AttributeName AS Attribute2,
    bu.BusinessUnitName,
    a1.CompanyId AS Company1Id,
    a2.CompanyId AS Company2Id
FROM shashank.Attribute a1
JOIN shashank.Attribute a2
    ON  a1.BusinessUnitId = a2.BusinessUnitId   -- same BU
    AND a1.CompanyId     <> a2.CompanyId         -- different companies
    AND a1.AttributeId    < a2.AttributeId       -- avoid duplicates (A,B) and (B,A)
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a1.BusinessUnitId
ORDER BY bu.BusinessUnitName;
GO

-- ── Task 5: Same query 3 ways ─────────────────────────────────
-- Comment comparing approaches:
-- JOINs:               Most readable, best optimizer support, preferred for production
-- Correlated subqueries: Runs once per row — O(n) — avoid on large datasets
-- CTE:                 Same performance as JOINs but better readability for complex logic
-- Rule: Use JOINs for multi-table reads. Use CTEs to name intermediate steps.
-- Avoid correlated subqueries in SELECT for more than a few thousand rows.

-- Version 1: JOINs
SELECT
    a.AttributeName,
    bu.BusinessUnitName,
    ISNULL(cl.CustomerLocationName, 'No Location') AS LocationName,
    co.CompanyName
FROM shashank.Attribute        a
JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId;
GO

-- Version 2: Correlated subqueries in SELECT
SELECT
    a.AttributeName,
    (SELECT bu.BusinessUnitName FROM shashank.BusinessUnit bu
     WHERE  bu.BusinessUnitId = a.BusinessUnitId)         AS BusinessUnitName,
    ISNULL(
     (SELECT cl.CustomerLocationName FROM shashank.CustomerLocation cl
      WHERE  cl.CustomerLocationId = a.CustomerLocationId), 'No Location') AS LocationName,
    (SELECT co.CompanyName FROM shashank.Company co
     WHERE  co.CompanyId = a.CompanyId)                   AS CompanyName
FROM shashank.Attribute a;
GO

-- Version 3: CTE
WITH AttrDetail AS (
    SELECT
        a.AttributeName,
        bu.BusinessUnitName,
        ISNULL(cl.CustomerLocationName, 'No Location') AS LocationName,
        co.CompanyName
    FROM shashank.Attribute        a
    JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
    LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
    JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId
)
SELECT * FROM AttrDetail;
GO

-- ============================================================
-- SECTION 4: SUBQUERIES, CTEs & VIEWS
-- ============================================================

-- ── Task 6a: Subquery in WHERE — BU with most Attributes ──────
SELECT a.AttributeId, a.AttributeName, a.BusinessUnitId
FROM   shashank.Attribute a
WHERE  a.BusinessUnitId = (
    SELECT TOP 1 BusinessUnitId
    FROM   shashank.Attribute
    GROUP  BY BusinessUnitId
    ORDER  BY COUNT(*) DESC
);
GO

-- ── Task 6b: EXISTS — BUs with at least one "Admin" Attribute ──
SELECT bu.BusinessUnitId, bu.BusinessUnitName
FROM   shashank.BusinessUnit bu
WHERE  EXISTS (
    SELECT 1 FROM shashank.Attribute a
    WHERE  a.BusinessUnitId = bu.BusinessUnitId
    AND    a.CreatedBy = 'Admin'
);
GO

-- ── Task 6c: NOT EXISTS — BUs with NO Attributes ──────────────
-- Version 1: NOT EXISTS
SELECT bu.BusinessUnitId, bu.BusinessUnitName
FROM   shashank.BusinessUnit bu
WHERE  NOT EXISTS (
    SELECT 1 FROM shashank.Attribute a
    WHERE  a.BusinessUnitId = bu.BusinessUnitId
);

-- Version 2: LEFT JOIN + IS NULL (equivalent, often same plan)
SELECT bu.BusinessUnitId, bu.BusinessUnitName
FROM   shashank.BusinessUnit bu
LEFT   JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
WHERE  a.AttributeId IS NULL;
-- Comment: NOT EXISTS is usually preferred because:
-- (1) Intent is clearer — "where nothing exists"
-- (2) Handles NULLs correctly in all edge cases
-- (3) Optimizer generates same or better plan than LEFT JOIN + IS NULL
GO

-- ── Task 6d: Correlated subquery — most recent Attribute per BU
SELECT
    bu.BusinessUnitName,
    (SELECT TOP 1 a.AttributeName
     FROM   shashank.Attribute a
     WHERE  a.BusinessUnitId = bu.BusinessUnitId
     ORDER  BY a.CreatedOn DESC) AS MostRecentAttributeName,
    (SELECT TOP 1 a.CreatedOn
     FROM   shashank.Attribute a
     WHERE  a.BusinessUnitId = bu.BusinessUnitId
     ORDER  BY a.CreatedOn DESC) AS MostRecentCreatedOn
FROM shashank.BusinessUnit bu
ORDER BY bu.BusinessUnitName;
GO

-- ── Task 7: CTE Examples ──────────────────────────────────────
-- Comment: CTE vs derived table:
--   CTE: named, defined at top, readable, can be referenced multiple times in the query
--   Derived table: inline subquery in FROM, unnamed (unless aliased), harder to read when nested
--   Neither is materialised by default — both are expanded inline by the optimizer
--   TEMP TABLE: physically stored in tempdb, reusable across batches, can be indexed
-- CTEs CANNOT reference themselves unless they are recursive (WITH RECURSIVE member)

-- Task 7a + 7b: ROW_NUMBER to rank, then select top 2 per BU
WITH RankedAttrs AS (
    SELECT
        a.AttributeId,
        a.AttributeName,
        a.BusinessUnitId,
        bu.BusinessUnitName,
        a.CreatedOn,
        ROW_NUMBER() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn DESC
        ) AS RowNum
    FROM shashank.Attribute a
    JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
)
SELECT AttributeId, AttributeName, BusinessUnitName, CreatedOn, RowNum
FROM   RankedAttrs
WHERE  RowNum <= 2
ORDER  BY BusinessUnitName, RowNum;
GO

-- Task 7c: Running total of Attributes per month
WITH MonthlyCount AS (
    SELECT
        YEAR(CreatedOn)  AS Yr,
        MONTH(CreatedOn) AS Mo,
        COUNT(*)         AS AttrThisMonth
    FROM shashank.Attribute
    GROUP BY YEAR(CreatedOn), MONTH(CreatedOn)
)
SELECT
    Yr, Mo, AttrThisMonth,
    SUM(AttrThisMonth) OVER (
        ORDER BY Yr, Mo
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM MonthlyCount
ORDER BY Yr, Mo;
GO

-- Task 7d: Multiple CTEs joined together
WITH cteBUStats AS (
    SELECT BusinessUnitId, COUNT(*) AS BUAttrCount
    FROM   shashank.Attribute
    GROUP  BY BusinessUnitId
),
cteCompanyStats AS (
    SELECT CompanyId, COUNT(*) AS CoAttrCount
    FROM   shashank.Attribute
    GROUP  BY CompanyId
)
SELECT
    bu.BusinessUnitName,
    b.BUAttrCount,
    co.CompanyName,
    c.CoAttrCount
FROM cteBUStats b
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = b.BusinessUnitId
CROSS JOIN cteCompanyStats c
JOIN shashank.Company      co ON co.CompanyId      = c.CompanyId
ORDER BY bu.BusinessUnitName, co.CompanyName;
GO

-- ── Task 8: Recursive CTEs ────────────────────────────────────
-- Comment:
-- Anchor member: the starting SELECT (base case — no self-reference)
-- Recursive member: the SELECT that references the CTE itself (UNION ALL below anchor)
-- MAXRECURSION: default 100 — prevents infinite loops. SQL Server stops and throws error.
-- Raise it: OPTION (MAXRECURSION 500) — for deep hierarchies or long date ranges
-- Lower it to 0 for unlimited (careful — only when termination is guaranteed)

-- Task 8a: Number sequence 1–100
WITH Numbers AS (
    SELECT 1 AS N                    -- anchor
    UNION ALL
    SELECT N + 1 FROM Numbers        -- recursive member
    WHERE  N < 100
)
SELECT N FROM Numbers
OPTION (MAXRECURSION 100);
GO

-- Task 8b: Date sequence between earliest and latest CreatedOn
WITH DateRange AS (
    SELECT CAST(MIN(CreatedOn) AS DATE) AS Dt,
           CAST(MAX(CreatedOn) AS DATE) AS MaxDt
    FROM   shashank.Attribute
    UNION ALL
    SELECT DATEADD(DAY, 1, Dt), MaxDt
    FROM   DateRange
    WHERE  Dt < MaxDt
)
SELECT Dt AS DateInRange FROM DateRange
OPTION (MAXRECURSION 0);  -- data spans > 100 days so raise limit
GO

-- Task 8c: Organisational hierarchy
-- Add ParentBusinessUnitId column (run once)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE  object_id = OBJECT_ID('shashank.BusinessUnit')
    AND    name = 'ParentBusinessUnitId'
)
    ALTER TABLE shashank.BusinessUnit
    ADD ParentBusinessUnitId INT NULL
    CONSTRAINT FK_BU_Parent FOREIGN KEY (ParentBusinessUnitId)
        REFERENCES shashank.BusinessUnit(BusinessUnitId);
GO

-- Insert parent-child rows
UPDATE shashank.BusinessUnit SET ParentBusinessUnitId = NULL WHERE BusinessUnitId = 1; -- Finance = root
UPDATE shashank.BusinessUnit SET ParentBusinessUnitId = 1     WHERE BusinessUnitId = 2; -- HR under Finance
UPDATE shashank.BusinessUnit SET ParentBusinessUnitId = 1     WHERE BusinessUnitId = 3; -- IT under Finance
UPDATE shashank.BusinessUnit SET ParentBusinessUnitId = 2     WHERE BusinessUnitId = 4; -- Marketing under HR
GO

-- Recursive CTE to walk hierarchy
WITH OrgHierarchy AS (
    -- Anchor: root nodes (no parent)
    SELECT
        BusinessUnitId,
        BusinessUnitName,
        ParentBusinessUnitId,
        0                          AS Level,
        CAST(BusinessUnitName AS NVARCHAR(500)) AS Path
    FROM shashank.BusinessUnit
    WHERE ParentBusinessUnitId IS NULL

    UNION ALL

    -- Recursive: children
    SELECT
        bu.BusinessUnitId,
        bu.BusinessUnitName,
        bu.ParentBusinessUnitId,
        oh.Level + 1,
        CAST(oh.Path + N' > ' + bu.BusinessUnitName AS NVARCHAR(500))
    FROM shashank.BusinessUnit bu
    JOIN OrgHierarchy oh ON oh.BusinessUnitId = bu.ParentBusinessUnitId
)
SELECT
    REPLICATE('    ', Level) + BusinessUnitName AS IndentedName,
    Level,
    Path
FROM OrgHierarchy
ORDER BY Path;
GO

-- ── Task 9: Derived tables ────────────────────────────────────
-- Comment: Derived table vs CTE vs Temp table:
-- Derived table : inline anonymous subquery in FROM — not reusable, not named outside
-- CTE           : named in WITH block — reusable within same statement, no materialization
-- Temp table    : stored in tempdb, survives across statements in same session, can be indexed
-- Materialization: derived tables and CTEs are expanded inline (not stored)
--                  Temp tables are always physically written to disk

-- Task 9a: BU + IsActive aggregation via derived table
SELECT
    d.BusinessUnitName,
    d.IsActive,
    d.AttrCount
FROM (
    SELECT
        bu.BusinessUnitName,
        a.IsActive,
        COUNT(a.AttributeId) AS AttrCount
    FROM shashank.BusinessUnit bu
    LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
    GROUP BY bu.BusinessUnitName, a.IsActive
) AS d
ORDER BY d.BusinessUnitName, d.IsActive;
GO

-- Task 9b: Attributes where BU has above-average activity
SELECT
    a.AttributeName,
    bu.BusinessUnitName,
    perBU.BUCount,
    avgAll.AvgCount
FROM shashank.Attribute a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
JOIN (
    SELECT BusinessUnitId, COUNT(*) AS BUCount
    FROM   shashank.Attribute
    GROUP  BY BusinessUnitId
) AS perBU ON perBU.BusinessUnitId = a.BusinessUnitId
CROSS JOIN (
    SELECT AVG(CAST(cnt AS DECIMAL(10,2))) AS AvgCount
    FROM   (SELECT COUNT(*) AS cnt FROM shashank.Attribute GROUP BY BusinessUnitId) AS x
) AS avgAll
WHERE perBU.BUCount > avgAll.AvgCount
ORDER BY bu.BusinessUnitName;
GO

-- ── Task 10: Views ────────────────────────────────────────────
-- Comment: Use a View when:
-- (1) Same complex JOIN is used in many places — single point of change
-- (2) You want to restrict column visibility for a role
-- (3) You want to simplify a complex query for report writers
-- You CAN INSERT into a View IF: no aggregation, no DISTINCT, no GROUP BY,
-- no subquery in SELECT, no UNION, all NOT NULL base columns are covered.

CREATE OR ALTER VIEW shashank.vw_AttributeDetail AS
SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitId,
    bu.BusinessUnitName,
    cl.CustomerLocationId,
    ISNULL(cl.CustomerLocationName, 'No Location') AS CustomerLocationName,
    co.CompanyId,
    co.CompanyName,
    a.IsActive,
    a.CreatedOn,
    a.CreatedBy,
    a.UpdatedOn,
    a.UpdatedBy
FROM shashank.Attribute        a
JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId;
GO

CREATE OR ALTER VIEW shashank.vw_BusinessUnitSummary AS
SELECT
    bu.BusinessUnitId,
    bu.BusinessUnitName,
    COUNT(a.AttributeId)                                      AS TotalAttributes,
    SUM(CASE WHEN a.IsActive = 1 THEN 1 ELSE 0 END)         AS ActiveCount,
    SUM(CASE WHEN a.IsActive = 0 THEN 1 ELSE 0 END)         AS InactiveCount,
    MAX(a.CreatedOn)                                          AS MostRecentCreatedOn
FROM shashank.BusinessUnit bu
LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitId, bu.BusinessUnitName;
GO

-- Verify views
SELECT * FROM shashank.vw_AttributeDetail     ORDER BY BusinessUnitName;
SELECT * FROM shashank.vw_BusinessUnitSummary ORDER BY TotalAttributes DESC;
GO

-- ============================================================
-- SECTION 5: SCHEMAS
-- ============================================================

-- Comment: Schema vs Database:
-- Database = entire container of all objects, files, logins
-- Schema   = logical namespace within a database (like a folder)
-- dbo is the default schema — every object without explicit schema goes here
-- Schemas help with:
-- (1) Permissions: GRANT SELECT ON SCHEMA::Reporting grants access to ALL objects in it
-- (2) Namespacing: Reporting.vw_Sales vs HR.vw_Sales — no name collision
-- (3) Team org: DBA team owns dbo; Reporting team owns Reporting schema
-- (4) Security: Finance team can see Finance schema only

-- Task 11: Create schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Reporting')
    EXEC('CREATE SCHEMA Reporting');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Audit')
    EXEC('CREATE SCHEMA Audit');
GO

-- Move views to Reporting schema
-- Option 1: ALTER SCHEMA TRANSFER (moves object in-place)
IF OBJECT_ID('shashank.vw_AttributeDetail', 'V') IS NOT NULL
    ALTER SCHEMA Reporting TRANSFER shashank.vw_AttributeDetail;
IF OBJECT_ID('shashank.vw_BusinessUnitSummary', 'V') IS NOT NULL
    ALTER SCHEMA Reporting TRANSFER shashank.vw_BusinessUnitSummary;
GO

-- Option 2 (if transfer fails): drop and recreate under Reporting schema
CREATE OR ALTER VIEW Reporting.vw_AttributeDetail AS
SELECT
    a.AttributeId, a.AttributeName,
    bu.BusinessUnitName,
    ISNULL(cl.CustomerLocationName,'No Location') AS CustomerLocationName,
    co.CompanyName,
    a.IsActive, a.CreatedOn, a.CreatedBy
FROM shashank.Attribute        a
JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId        = a.BusinessUnitId
LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId;
GO

CREATE OR ALTER VIEW Reporting.vw_BusinessUnitSummary AS
SELECT
    bu.BusinessUnitName,
    COUNT(a.AttributeId)                                AS TotalAttributes,
    SUM(CASE WHEN a.IsActive = 1 THEN 1 ELSE 0 END)   AS ActiveCount,
    SUM(CASE WHEN a.IsActive = 0 THEN 1 ELSE 0 END)   AS InactiveCount,
    MAX(a.CreatedOn)                                    AS MostRecentCreatedOn
FROM shashank.BusinessUnit bu
LEFT JOIN shashank.Attribute a ON a.BusinessUnitId = bu.BusinessUnitId
GROUP BY bu.BusinessUnitName;
GO

-- Grant SELECT on Reporting schema to a role
-- (Document only — run if you have a test user/role)
-- GRANT SELECT ON SCHEMA::Reporting TO [SomeRole];

-- Verify
SELECT * FROM Reporting.vw_AttributeDetail     ORDER BY BusinessUnitName;
SELECT * FROM Reporting.vw_BusinessUnitSummary ORDER BY TotalAttributes DESC;
GO

-- ============================================================
-- SECTION 6: SET OPERATORS
-- ============================================================

-- Comment on set operators:
-- Rules: both SELECT lists must have SAME number of columns AND compatible data types
-- UNION / INTERSECT / EXCEPT all remove duplicates (like DISTINCT)
-- UNION ALL keeps duplicates — faster because no de-dup step
-- INTERSECT: handles NULLs as equal (NULL INTERSECT NULL = returns the row)
-- EXCEPT: same NULL handling — NULLs are treated as equal for comparison
-- Prefer set operators over complex JOINs when working with sets of keys

-- ── Task 12a: UNION vs UNION ALL ─────────────────────────────
-- With UNION (deduplicates)
SELECT a.AttributeName, bu.BusinessUnitName, 'Active'   AS StatusLabel
FROM   shashank.Attribute a
JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  a.IsActive = 1
UNION
SELECT a.AttributeName, bu.BusinessUnitName, 'Inactive' AS StatusLabel
FROM   shashank.Attribute a
JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  a.IsActive = 0
ORDER  BY StatusLabel, BusinessUnitName;

-- With UNION ALL (keeps all rows — faster, no sort/hash for dedup)
SELECT a.AttributeName, bu.BusinessUnitName, 'Active'   AS StatusLabel
FROM   shashank.Attribute a
JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  a.IsActive = 1
UNION ALL
SELECT a.AttributeName, bu.BusinessUnitName, 'Inactive' AS StatusLabel
FROM   shashank.Attribute a
JOIN   shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE  a.IsActive = 0
ORDER  BY StatusLabel, BusinessUnitName;
GO

-- ── Task 12b: INTERSECT ───────────────────────────────────────
-- BUs that have BOTH active Attributes AND recent Attributes (last 6 months)
SELECT BusinessUnitId FROM shashank.Attribute WHERE IsActive = 1
INTERSECT
SELECT BusinessUnitId FROM shashank.Attribute
WHERE  CreatedOn >= DATEADD(MONTH, -36, GETDATE()); -- 36 months as data is historical

-- Rewrite with EXISTS
SELECT DISTINCT a.BusinessUnitId
FROM   shashank.Attribute a
WHERE  a.IsActive = 1
AND    EXISTS (
    SELECT 1 FROM shashank.Attribute a2
    WHERE  a2.BusinessUnitId = a.BusinessUnitId
    AND    a2.CreatedOn >= DATEADD(MONTH, -36, GETDATE())
);
GO

-- ── Task 12c: EXCEPT ──────────────────────────────────────────
-- BUs with Attributes but ALL are inactive (no active ones)
SELECT BusinessUnitId FROM shashank.Attribute
EXCEPT
SELECT BusinessUnitId FROM shashank.Attribute WHERE IsActive = 1;

-- Rewrite with NOT EXISTS
SELECT DISTINCT a.BusinessUnitId
FROM   shashank.Attribute a
WHERE  NOT EXISTS (
    SELECT 1 FROM shashank.Attribute a2
    WHERE  a2.BusinessUnitId = a.BusinessUnitId
    AND    a2.IsActive = 1
);
GO

-- ============================================================
-- SECTION 7: NULL HANDLING
-- ============================================================

-- Comment: Why NULL = NULL returns UNKNOWN (not TRUE):
-- NULL means "unknown value". An unknown value is not equal to another unknown value
-- because both could be different unknowns. SQL uses three-valued logic: TRUE/FALSE/UNKNOWN.
-- WHERE NULL = NULL returns UNKNOWN, which is treated as FALSE in filtering.
-- Effect on JOINs: a JOIN ON a.col = b.col will NEVER match NULL to NULL —
-- rows with NULL keys are excluded from INNER JOINs (use IS NULL checks explicitly).

-- Task 13a: Attributes never updated
SELECT AttributeId, AttributeName, UpdatedBy, UpdatedOn
FROM   shashank.Attribute
WHERE  UpdatedBy IS NULL;
GO

-- Task 13b: COALESCE — friendly label for NULL
SELECT
    AttributeName,
    COALESCE(UpdatedBy, 'Never Updated') AS LastUpdatedBy,
    COALESCE(CONVERT(VARCHAR,UpdatedOn,106), 'Never Updated') AS LastUpdatedOn
FROM shashank.Attribute;
GO

-- Task 13c: ISNULL — show CreatedOn when UpdatedOn is NULL
SELECT
    AttributeName,
    CreatedOn,
    UpdatedOn,
    ISNULL(UpdatedOn, CreatedOn) AS EffectiveDate
FROM shashank.Attribute;
GO

-- Task 13d: Deliberate NULL comparison failure — DOCUMENT
-- This query returns 0 rows even though NULL values exist:
SELECT AttributeId, AttributeName, UpdatedBy
FROM   shashank.Attribute
WHERE  UpdatedBy = NULL;  -- WRONG: always returns 0 rows
-- Reason: NULL = NULL evaluates to UNKNOWN, not TRUE.
-- SQL filters WHERE UNKNOWN as FALSE — so no rows qualify.
-- Correct: WHERE UpdatedBy IS NULL

-- Demonstrate the difference:
SELECT COUNT(*) AS WrongWay FROM shashank.Attribute WHERE UpdatedBy =  NULL; -- 0
SELECT COUNT(*) AS RightWay FROM shashank.Attribute WHERE UpdatedBy IS NULL;  -- actual count
GO

-- ============================================================
-- END OF ASSIGNMENT 2
-- Views (Reporting.vw_AttributeDetail, Reporting.vw_BusinessUnitSummary),
-- Reporting and Audit schemas, and all query patterns carry into Assignments 3–5.
-- Do NOT drop anything.
-- ============================================================
