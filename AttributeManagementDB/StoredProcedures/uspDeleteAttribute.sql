USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspDeleteAttribute
    @AttributeId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM shashank.Attribute WHERE AttributeId = @AttributeId)
    BEGIN
        RETURN 0;
    END;

    UPDATE shashank.Attribute
    SET
        IsActive  = 0,
        UpdatedOn = GETDATE(),
        UpdatedBy = 'SYSTEM'
    WHERE AttributeId = @AttributeId;

    RETURN 1;
END;
GO
