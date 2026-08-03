USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspGetAttributeList
    @IsActiveFilter BIT          = NULL,
    @SearchTerm     NVARCHAR(100) = NULL
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
