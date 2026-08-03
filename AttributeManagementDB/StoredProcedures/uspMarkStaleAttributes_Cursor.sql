USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspMarkStaleAttributes_Cursor
AS
BEGIN
    SET NOCOUNT ON;
    SET STATISTICS TIME ON;
    SET STATISTICS IO ON;

    DECLARE @AttrId    INT;
    DECLARE @CreatedOn DATETIME2;
    DECLARE @UpdatedOn DATETIME2;

    DECLARE stale_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT AttributeId, CreatedOn, UpdatedOn
        FROM   shashank.Attribute
        WHERE  IsActive = 1;

    OPEN stale_cursor;
    FETCH NEXT FROM stale_cursor INTO @AttrId, @CreatedOn, @UpdatedOn;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF DATEDIFF(YEAR, @CreatedOn, GETDATE()) >= 1
           AND @UpdatedOn IS NULL
        BEGIN
            UPDATE shashank.Attribute
            SET    IsActive  = 0,
                   UpdatedBy = 'SYSTEM_STALE',
                   UpdatedOn = GETDATE()
            WHERE  AttributeId = @AttrId;
        END;

        FETCH NEXT FROM stale_cursor INTO @AttrId, @CreatedOn, @UpdatedOn;
    END;

    CLOSE stale_cursor;
    DEALLOCATE stale_cursor;

    SET STATISTICS IO  OFF;
    SET STATISTICS TIME OFF;
END;
GO
