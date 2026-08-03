USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspGetAttributeRankings
    @BusinessUnitId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AttributeId,
        a.AttributeName,
        bu.BusinessUnitName,
        a.CreatedOn,

        ROW_NUMBER() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn DESC
        ) AS RowNumInBU,

        RANK() OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.AttributeName ASC
        ) AS RankByName,

        NTILE(4) OVER (
            ORDER BY a.CreatedOn
        ) AS Quartile,

        LAG(a.AttributeName) OVER (
            PARTITION BY a.BusinessUnitId
            ORDER BY     a.CreatedOn
        ) AS PreviousAttributeName,

        DATEDIFF(DAY,
            LAG(a.CreatedOn) OVER (
                PARTITION BY a.BusinessUnitId
                ORDER BY     a.CreatedOn
            ),
            a.CreatedOn
        ) AS DaysSincePrevious,

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
