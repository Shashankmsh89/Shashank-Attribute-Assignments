USE TrainingDB;
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
