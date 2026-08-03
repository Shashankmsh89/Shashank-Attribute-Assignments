USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspSearchAttributes
    @SearchTerm  NVARCHAR(100) = NULL,
    @PageNumber  INT           = 1,
    @PageSize    INT           = 20,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM shashank.Attribute        a
    JOIN shashank.BusinessUnit     bu ON bu.BusinessUnitId = a.BusinessUnitId
    JOIN shashank.Company          co ON co.CompanyId      = a.CompanyId
    WHERE
        @SearchTerm IS NULL
        OR a.AttributeName    LIKE '%' + @SearchTerm + '%'
        OR bu.BusinessUnitName LIKE '%' + @SearchTerm + '%'
        OR co.CompanyName      LIKE '%' + @SearchTerm + '%';

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
