USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspGetBusinessUnits
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BusinessUnitId AS Id, BusinessUnitName AS Name
    FROM   shashank.BusinessUnit
    WHERE  IsActive = 1
    ORDER  BY BusinessUnitName;
END;
GO
