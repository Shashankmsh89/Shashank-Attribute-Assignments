USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspXactAbortDemo
    @UseXactAbort BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF @UseXactAbort = 1 SET XACT_ABORT ON ELSE SET XACT_ABORT OFF;

    BEGIN TRANSACTION;

    INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
    VALUES ('XactAbort Test', 1, 1, 'XactTest');

    INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
    VALUES ('XactAbort Test 2', 1, 9999, 'XactTest');

    COMMIT TRANSACTION;
END;
GO
