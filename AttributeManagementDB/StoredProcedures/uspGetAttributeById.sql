USE TrainingDB;
GO

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
END;
GO
