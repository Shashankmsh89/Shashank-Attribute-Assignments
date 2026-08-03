USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspGetCompanies
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CompanyId AS Id, CompanyName AS Name
    FROM   shashank.Company
    WHERE  IsActive = 1
    ORDER  BY CompanyName;
END;
GO
