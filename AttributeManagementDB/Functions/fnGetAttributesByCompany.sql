USE TrainingDB;
GO

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
