-- ============================================================
--  ASSIGNMENT 3 — Window Functions & Analytical Queries
--  Developer : Shashank Masih | Mentor: Shivam | Path 2
--  Database  : TrainingDB | Schema: shashank
--  Builds on : Assignment 1 (tables + data)
-- ============================================================

USE TrainingDB;
GO

-- ============================================================
-- SECTION 1: RANKING WINDOW FUNCTIONS
-- ============================================================

-- ── Task 1a: ROW_NUMBER() — row number per BU by CreatedOn DESC
-- ─────────────────────────────────────────────────────────────
-- Shows each Attribute's position within its BusinessUnit
-- ordered by most recently created first.

SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    ROW_NUMBER() OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn DESC
    ) AS RowNumInBU
FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, RowNumInBU;
GO

-- Use ROW_NUMBER to find the MOST RECENTLY created Attribute per BU
WITH RankedByRecent AS (
    SELECT
        a.AttributeId,
        a.AttributeName,
        bu.BusinessUnitName,
        a.CreatedOn,
        ROW_NUMBER() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn DESC
        ) AS RN
    FROM shashank.Attribute    a
    JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
)
SELECT
    AttributeId,
    AttributeName,
    BusinessUnitName,
    CreatedOn AS MostRecentCreatedOn
FROM RankedByRecent
WHERE RN = 1
ORDER BY BusinessUnitName;
GO

-- ── Task 1b: RANK() vs DENSE_RANK() — side-by-side with ties ──
-- ─────────────────────────────────────────────────────────────
-- First insert two rows with the SAME CreatedOn to create a tie

INSERT INTO shashank.Attribute
    (AttributeName, BusinessUnitId, CompanyId, CreatedBy, CreatedOn)
VALUES
    ('Tie Demo Alpha', 1, 1, 'TieTest', '2024-06-10 00:00:00'),
    ('Tie Demo Beta',  1, 1, 'TieTest', '2024-06-10 00:00:00');
-- Same CreatedOn → both rows tie on the ORDER BY column
GO

SELECT
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    ROW_NUMBER() OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
    ) AS RowNum,
    RANK() OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
    ) AS RankVal,
    DENSE_RANK() OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
    ) AS DenseRankVal
FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
WHERE a.BusinessUnitId = 1
ORDER BY a.CreatedOn, a.AttributeName;
GO

/*
COMMENT — RANK vs DENSE_RANK difference:

  Tie scenario with 3 rows (rows A and B share the same CreatedOn):

  AttributeName  | ROW_NUMBER | RANK | DENSE_RANK
  ─────────────────────────────────────────────────
  Old Attribute  |     1      |  1   |     1
  Tie Demo Alpha |     2      |  2   |     2
  Tie Demo Beta  |     3      |  2   |     2   ← both tied
  Next Attribute |     4      |  4   |     3   ← RANK skips 3, DENSE_RANK does not

  RANK():       leaves a GAP after ties  (1, 2, 2, 4)  — position 3 is skipped
  DENSE_RANK(): NO gap after ties        (1, 2, 2, 3)  — continuous sequence

  When does the difference MATTER?
  Real-world example: Top 3 employee salary bands.
  With RANK():       Employees ranked 1, 2, 2, 4 — asking for "Top 3" misses
                     rank-3 employees because no one has rank 3.
  With DENSE_RANK(): Employees ranked 1, 2, 2, 3 — "Top 3" correctly includes
                     all employees in the third-highest band.
  Use DENSE_RANK when ties should not consume the next position.
  Use RANK when position reflects true competition standing (e.g. race positions).
*/

-- Clean up tie demo rows
DELETE FROM shashank.Attribute WHERE CreatedBy = 'TieTest';
GO

-- ── Task 1c: NTILE(4) — divide into 4 quartiles by CreatedOn ──
-- ─────────────────────────────────────────────────────────────

SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    NTILE(4) OVER (
        ORDER BY a.CreatedOn
    ) AS Quartile
FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY Quartile, a.CreatedOn;
GO

-- Summary: how many Attributes fall in each quartile?
WITH Quartiled AS (
    SELECT
        NTILE(4) OVER (ORDER BY CreatedOn) AS Quartile
    FROM shashank.Attribute
)
SELECT
    Quartile,
    COUNT(*) AS AttrCount
FROM Quartiled
GROUP BY Quartile
ORDER BY Quartile;
GO

/*
COMMENT — How NTILE handles uneven division:

  If there are 22 rows and 4 buckets:
    22 / 4 = 5 remainder 2
  The FIRST 2 buckets (lower-numbered) each get 6 rows.
  The remaining 2 buckets each get 5 rows.
  Rule: extra rows always go to the LOWEST-numbered buckets first.

  Result: Bucket 1 → 6 rows, Bucket 2 → 6 rows,
          Bucket 3 → 5 rows, Bucket 4 → 5 rows

  What is NTILE useful for?
  (1) Percentile analysis — identify bottom/top 25% performers
  (2) A/B testing — assign rows evenly to test groups without manual math
  (3) Performance tiering — "Gold/Silver/Bronze/Basic" customer segments
  (4) Data sampling — pick every Nth row from each quartile for a sample
*/

-- ── Task 1d: LAG() and LEAD() partitioned by BusinessUnit ─────
-- ─────────────────────────────────────────────────────────────

SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,

    -- Previous Attribute name within the same BU (by CreatedOn)
    LAG(a.AttributeName, 1, 'FIRST IN BU') OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
    ) AS PreviousAttributeName,

    -- Next Attribute name within the same BU (by CreatedOn)
    LEAD(a.AttributeName, 1, 'LAST IN BU') OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
    ) AS NextAttributeName

FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

/*
COMMENT — LAG/LEAD at boundary rows:

  At the FIRST row in a partition (no previous row):
    LAG() returns NULL by default.
    Handle with: LAG(col, 1, 'default_value') — third argument is the default.
    Or wrap with: ISNULL(LAG(col) OVER (...), 'First Record')
    Or:           COALESCE(LAG(col) OVER (...), 'N/A')

  At the LAST row in a partition (no next row):
    LEAD() returns NULL by default.
    Same handling: LEAD(col, 1, 'No Next Record')

  In this query we use the three-argument form:
    LAG(col, offset, default)
    LEAD(col, offset, default)
  So boundary rows show 'FIRST IN BU' and 'LAST IN BU' instead of NULL.

  The PARTITION BY ensures LAG/LEAD restarts at the boundary of each BU —
  the first row in BU 2 does NOT look back to the last row in BU 1.
*/

-- ============================================================
-- SECTION 2: ANALYTICAL QUERIES
-- ============================================================

-- ── Task 2a: Running count of Attributes within each BU ───────

SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    COUNT(*) OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningCountInBU
FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

-- ── Task 2b: Running percentage of BU total ───────────────────

SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,

    -- Running count up to current row
    COUNT(*) OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningCount,

    -- Total count in this BU (no ORDER BY = whole partition)
    COUNT(*) OVER (
        PARTITION BY a.BusinessUnitId
    ) AS TotalInBU,

    -- Running percentage: running / total * 100
    CAST(
        COUNT(*) OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS DECIMAL(10, 2)
    )
    /
    COUNT(*) OVER (PARTITION BY a.BusinessUnitId)
    * 100.0 AS RunningPctOfBU

FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

-- ── Task 2c: 3-month moving average of Attributes per month ───

WITH MonthlyAgg AS (
    -- First aggregate to one row per month
    SELECT
        YEAR(CreatedOn)                               AS Yr,
        MONTH(CreatedOn)                              AS Mo,
        CAST(
            CAST(YEAR(CreatedOn) AS VARCHAR) + '-' +
            RIGHT('0' + CAST(MONTH(CreatedOn) AS VARCHAR), 2) + '-01'
        AS DATE)                                      AS MonthStart,
        COUNT(*)                                      AS AttrCount
    FROM shashank.Attribute
    GROUP BY YEAR(CreatedOn), MONTH(CreatedOn)
)
SELECT
    Yr,
    Mo,
    MonthStart,
    AttrCount                                         AS AttributesThisMonth,

    -- 3-month moving average: current month + 2 preceding months
    AVG(CAST(AttrCount AS DECIMAL(10, 2))) OVER (
        ORDER BY Yr, Mo
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3Month,

    -- Running total across all months
    SUM(AttrCount) OVER (
        ORDER BY Yr, Mo
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeTotal

FROM MonthlyAgg
ORDER BY Yr, Mo;
GO

-- ── Task 2d: Days since previous Attribute in same BU ─────────

SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,

    LAG(a.CreatedOn) OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
    ) AS PrevCreatedOn,

    DATEDIFF(DAY,
        LAG(a.CreatedOn) OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn
        ),
        a.CreatedOn
    ) AS DaysSincePreviousInBU

FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

/*
COMMENT — ROWS BETWEEN vs RANGE BETWEEN:

  Both define the window frame (which rows are included in each calculation).

  ROWS BETWEEN: counts PHYSICAL rows from the current row.
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW → always exactly 3 rows maximum
    regardless of whether any ORDER BY values are the same.

  RANGE BETWEEN: counts LOGICAL rows based on ORDER BY VALUE.
    RANGE BETWEEN 2 PRECEDING AND CURRENT ROW → includes all rows whose
    ORDER BY value falls within the range [current - 2, current].
    If two rows share the same CreatedOn, RANGE treats them as one unit —
    both are included OR excluded together.

  When does it matter?
  Example: 3 rows all created on '2024-01-15':
    ROWS BETWEEN 1 PRECEDING AND CURRENT ROW → includes 2 rows (strictly positional)
    RANGE BETWEEN 1 PRECEDING AND CURRENT ROW → includes all 3 rows
    (because all three have the same date value, they are treated as tied)

  Practical rule:
    Use ROWS for moving averages (predictable row count per window).
    Use RANGE for "everything up to and including today's date"
    where ties should all be included in the same frame.

  Default frame (when ORDER BY is present but BETWEEN is omitted):
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    (this is why running totals can be surprising when ties exist — use ROWS explicitly)
*/

-- ============================================================
-- SECTION 3: COMBINED PATTERNS — ROW_NUMBER + PIVOT
-- ============================================================

-- ── Task 3: Top 3 most recent Attributes per BU as PIVOT ──────
-- ─────────────────────────────────────────────────────────────
-- Step 1: Use ROW_NUMBER to rank Attributes within each BU

WITH TopThreePerBU AS (
    SELECT
        a.AttributeId,
        a.AttributeName,
        bu.BusinessUnitName,
        a.CreatedOn,
        ROW_NUMBER() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn DESC   -- most recent first
        ) AS RN
    FROM shashank.Attribute    a
    JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
)
-- Step 2: Filter to top 3 only, then PIVOT RN into columns
SELECT
    BusinessUnitName,
    [1] AS MostRecent_1,
    [2] AS MostRecent_2,
    [3] AS MostRecent_3
FROM TopThreePerBU
WHERE RN <= 3
PIVOT (
    MAX(AttributeName)     -- MAX used as aggregate (only 1 row per RN per BU)
    FOR RN IN ([1], [2], [3])
) AS PivotResult
ORDER BY BusinessUnitName;
GO

-- Extended version: include CreatedOn dates alongside names
WITH TopThreePerBU AS (
    SELECT
        a.AttributeName,
        CONVERT(VARCHAR(10), a.CreatedOn, 23) AS CreatedOnStr,
        bu.BusinessUnitName,
        ROW_NUMBER() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn DESC
        ) AS RN
    FROM shashank.Attribute    a
    JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
)
SELECT
    BusinessUnitName,
    MAX(CASE WHEN RN = 1 THEN AttributeName  END) AS MostRecent_1,
    MAX(CASE WHEN RN = 1 THEN CreatedOnStr   END) AS MostRecent_1_Date,
    MAX(CASE WHEN RN = 2 THEN AttributeName  END) AS MostRecent_2,
    MAX(CASE WHEN RN = 2 THEN CreatedOnStr   END) AS MostRecent_2_Date,
    MAX(CASE WHEN RN = 3 THEN AttributeName  END) AS MostRecent_3,
    MAX(CASE WHEN RN = 3 THEN CreatedOnStr   END) AS MostRecent_3_Date
FROM TopThreePerBU
WHERE RN <= 3
GROUP BY BusinessUnitName
ORDER BY BusinessUnitName;
GO

/*
COMMENT — Why is ROW_NUMBER + PIVOT a common pattern?

  The problem: PIVOT aggregates ALL rows per group into one value per column.
  If a BU has 10 Attributes, PIVOT with COUNT gives you 10 — not the top 3 names.
  PIVOT alone cannot limit which rows contribute to each column.

  The pattern:
  (1) ROW_NUMBER() labels rows 1, 2, 3 within each partition
  (2) Filter to WHERE RN <= 3 — now each partition has at most 3 rows
  (3) PIVOT spreads RN (1, 2, 3) into column positions
  (4) MAX() as the aggregate picks the single value (there is only one per RN per BU)

  Why MAX()? Because PIVOT requires an aggregate function. Since we already
  guaranteed one row per (BU, RN) via ROW_NUMBER + WHERE, MAX/MIN/SUM all
  return the same single value. MAX is conventional.

  Alternative approaches:
  (1) CASE + GROUP BY (no PIVOT keyword):
      SELECT BUName,
             MAX(CASE WHEN RN=1 THEN AttributeName END) AS MostRecent_1,
             MAX(CASE WHEN RN=2 THEN AttributeName END) AS MostRecent_2,
             MAX(CASE WHEN RN=3 THEN AttributeName END) AS MostRecent_3
      FROM TopThreePerBU GROUP BY BUName
      — More readable, allows mixed types per column, easier to extend.

  (2) STRING_AGG with TOP 3:
      Concatenates top 3 names into one comma-separated column — simpler
      but loses the ability to reference each position independently.

  (3) JSON / FOR XML PATH:
      For variable-width results (top N where N is unknown at design time).

  The CASE + GROUP BY alternative (shown above) is often preferred because:
  - No need to hard-code column names in PIVOT's IN clause
  - Can return different data types per column
  - Works correctly when some BUs have fewer than 3 Attributes (NULLs appear naturally)
*/

-- ============================================================
-- BONUS: Full summary view — all window functions in one query
-- (This is the foundation for uspGetAttributeRankings in Assignment 4)
-- ============================================================

SELECT
    a.AttributeId,
    a.AttributeName,
    bu.BusinessUnitName,
    a.CreatedOn,
    a.IsActive,

    -- Ranking
    ROW_NUMBER() OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn DESC
    )                                                   AS RowNumInBU,

    RANK() OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.AttributeName ASC
    )                                                   AS RankByName,

    DENSE_RANK() OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.AttributeName ASC
    )                                                   AS DenseRankByName,

    NTILE(4) OVER (ORDER BY a.CreatedOn)               AS Quartile,

    -- LAG / LEAD
    LAG(a.AttributeName,  1, 'FIRST') OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn
    )                                                   AS PreviousAttrName,

    LEAD(a.AttributeName, 1, 'LAST') OVER (
        PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn
    )                                                   AS NextAttrName,

    DATEDIFF(DAY,
        LAG(a.CreatedOn) OVER (
            PARTITION BY a.BusinessUnitId ORDER BY a.CreatedOn
        ),
        a.CreatedOn
    )                                                   AS DaysSincePrevious,

    -- Running count + percentage
    COUNT(*) OVER (
        PARTITION BY a.BusinessUnitId
        ORDER BY     a.CreatedOn
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                   AS RunningCountInBU,

    CAST(
        COUNT(*) OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS DECIMAL(10,2)
    )
    / COUNT(*) OVER (PARTITION BY a.BusinessUnitId)
    * 100.0                                             AS RunningPctOfBU

FROM shashank.Attribute    a
JOIN shashank.BusinessUnit bu ON bu.BusinessUnitId = a.BusinessUnitId
ORDER BY bu.BusinessUnitName, a.CreatedOn;
GO

-- ============================================================
-- END OF ASSIGNMENT 3
-- All window function patterns (ROW_NUMBER, RANK, DENSE_RANK, NTILE,
-- LAG, LEAD, running totals, moving avg) carry into Assignment 4
-- inside uspGetAttributeRankings stored procedure.
-- ============================================================
