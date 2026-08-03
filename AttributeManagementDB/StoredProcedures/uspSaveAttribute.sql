USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspSaveAttribute
    @AttributeId        INT            = NULL,
    @AttributeName      NVARCHAR(300),
    @BusinessUnitId     INT,
    @CustomerLocationId INT            = NULL,
    @CompanyId          INT,
    @IsActive           BIT            = 1,
    @UpdatedBy          NVARCHAR(100)  = 'SYSTEM',
    @ResultAttributeId  INT            OUTPUT,
    @ResultMessage      NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ResultAttributeId = -1;
    SET @ResultMessage     = '';

    IF LTRIM(RTRIM(ISNULL(@AttributeName,''))) = ''
    BEGIN
        SET @ResultMessage = 'Validation Error: AttributeName cannot be empty.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM shashank.BusinessUnit WHERE BusinessUnitId = @BusinessUnitId)
    BEGIN
        SET @ResultMessage = 'Validation Error: BusinessUnitId ' + CAST(@BusinessUnitId AS VARCHAR) + ' does not exist.';
        RETURN;
    END;

    BEGIN TRY
        IF @AttributeId IS NULL
        BEGIN
            INSERT INTO shashank.Attribute
                (AttributeName, BusinessUnitId, CustomerLocationId, CompanyId,
                 IsActive, CreatedBy, CreatedOn)
            VALUES
                (LTRIM(RTRIM(@AttributeName)), @BusinessUnitId, @CustomerLocationId,
                 @CompanyId, @IsActive, @UpdatedBy, GETDATE());

            SET @ResultAttributeId = SCOPE_IDENTITY();
            SET @ResultMessage     = 'Insert Successful';
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM shashank.Attribute WHERE AttributeId = @AttributeId)
            BEGIN
                SET @ResultMessage = 'Validation Error: AttributeId not found.';
                RETURN;
            END;

            UPDATE shashank.Attribute
            SET
                AttributeName      = LTRIM(RTRIM(@AttributeName)),
                BusinessUnitId     = @BusinessUnitId,
                CustomerLocationId = @CustomerLocationId,
                CompanyId          = @CompanyId,
                IsActive           = @IsActive,
                UpdatedOn          = GETDATE(),
                UpdatedBy          = @UpdatedBy
            WHERE AttributeId = @AttributeId;

            SET @ResultAttributeId = @AttributeId;
            SET @ResultMessage     = 'Update Successful';
        END;
    END TRY
    BEGIN CATCH
        SET @ResultAttributeId = -1;
        SET @ResultMessage =
            'Error ' + CAST(ERROR_NUMBER() AS VARCHAR) +
            ' at Line '  + CAST(ERROR_LINE()    AS VARCHAR) +
            ' in '       + ISNULL(ERROR_PROCEDURE(), 'ad-hoc') +
            ': '         + ERROR_MESSAGE();

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH;
END;
GO
