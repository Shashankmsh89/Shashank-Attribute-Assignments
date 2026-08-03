USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspGetBusinessUnitSummary
    @SortBy NVARCHAR(20) = 'Name'
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
