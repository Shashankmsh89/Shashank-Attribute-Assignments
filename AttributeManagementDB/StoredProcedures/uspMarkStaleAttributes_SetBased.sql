USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspMarkStaleAttributes_SetBased
AS
BEGIN
    SET NOCOUNT ON;
    SET STATISTICS TIME ON;
    SET STATISTICS IO ON;

    UPDATE shashank.Attribute
    SET
        IsActive  = 0,
        UpdatedBy = 'SYSTEM_STALE',
        UpdatedOn = GETDATE()
    WHERE
        IsActive   = 1
        AND DATEDIFF(YEAR, CreatedOn, GETDATE()) >= 1
        AND UpdatedOn IS NULL;

    SET STATISTICS IO  OFF;
    SET STATISTICS TIME OFF;
END;
GO
