USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspBulkUpdateAttributes
    @BU1 INT,
    @BU2 INT,
    @BU3 INT,
    @ResultMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ResultMessage = '';

    BEGIN TRY
        BEGIN TRANSACTION;

        SAVE TRANSACTION SP_BU1;
        UPDATE shashank.Attribute
        SET UpdatedBy = 'BULK_BU1', UpdatedOn = GETDATE()
        WHERE BusinessUnitId = @BU1;
        SET @ResultMessage += 'BU1 updated. ';

        SAVE TRANSACTION SP_BU2;
        IF NOT EXISTS (SELECT 1 FROM shashank.Attribute WHERE BusinessUnitId = @BU2)
        BEGIN
            ROLLBACK TRANSACTION SP_BU2;
            SET @ResultMessage += 'BU2 skipped (no attributes — rolled back to SP_BU2). ';
        END
        ELSE
        BEGIN
            UPDATE shashank.Attribute
            SET UpdatedBy = 'BULK_BU2', UpdatedOn = GETDATE()
            WHERE BusinessUnitId = @BU2;
            SET @ResultMessage += 'BU2 updated. ';
        END;

        SAVE TRANSACTION SP_BU3;
        UPDATE shashank.Attribute
        SET UpdatedBy = 'BULK_BU3', UpdatedOn = GETDATE()
        WHERE BusinessUnitId = @BU3;
        SET @ResultMessage += 'BU3 updated. ';

        COMMIT TRANSACTION;
        SET @ResultMessage += 'Transaction committed.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ResultMessage = 'Fatal error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO
