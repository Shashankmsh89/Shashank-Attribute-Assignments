USE TrainingDB;
GO

CREATE OR ALTER PROCEDURE shashank.uspDynamicSearch
    @TableName   NVARCHAR(100),
    @ColumnName  NVARCHAR(100),
    @SearchValue NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF @TableName NOT IN ('shashank.Attribute', 'shashank.BusinessUnit', 'shashank.Company')
    BEGIN
        RAISERROR('Unauthorised table name: %s', 16, 1, @TableName);
        RETURN;
    END;

    DECLARE @SafeSQL  NVARCHAR(MAX);
    DECLARE @Params   NVARCHAR(500);
    DECLARE @LikeVal  NVARCHAR(202) = '%' + @SearchValue + '%';

    IF NOT EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN   sys.objects o ON o.object_id = c.object_id
        WHERE  c.name = @ColumnName
    )
    BEGIN
        RAISERROR('Column not found: %s', 16, 1, @ColumnName);
        RETURN;
    END;

    SET @SafeSQL = N'SELECT * FROM ' + @TableName +
                   N' WHERE ' + QUOTENAME(@ColumnName) + N' LIKE @SearchParam';
    SET @Params  = N'@SearchParam NVARCHAR(202)';

    EXEC sp_executesql @SafeSQL, @Params, @SearchParam = @LikeVal;
END;
GO
