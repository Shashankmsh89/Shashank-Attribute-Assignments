USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspTransferAttributes
    @FromBusinessUnitId INT,
    @ToBusinessUnitId   INT,
    @ResultMessage      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ResultMessage = '';

    IF NOT EXISTS (SELECT 1 FROM shashank.BusinessUnit WHERE BusinessUnitId = @ToBusinessUnitId)
    BEGIN
        SET @ResultMessage = 'Error: Target BusinessUnitId ' + CAST(@ToBusinessUnitId AS VARCHAR) + ' does not exist.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE shashank.Attribute
        SET    BusinessUnitId = @ToBusinessUnitId,
               UpdatedOn      = GETDATE(),
               UpdatedBy      = 'TRANSFER'
        WHERE  BusinessUnitId = @FromBusinessUnitId;

        UPDATE shashank.Attribute
        SET    CustomerLocationId = NULL,
               UpdatedOn          = GETDATE(),
               UpdatedBy          = 'TRANSFER'
        WHERE  BusinessUnitId = @ToBusinessUnitId;

        COMMIT TRANSACTION;
        SET @ResultMessage = 'Transfer Successful: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' attributes moved.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ResultMessage = 'Transfer Failed: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO
