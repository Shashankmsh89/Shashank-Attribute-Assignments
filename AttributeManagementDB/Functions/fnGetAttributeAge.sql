USE TrainingDB;
GO

CREATE OR ALTER FUNCTION shashank.fnGetAttributeAge
    (@CreatedOn DATETIME2)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Days    INT = DATEDIFF(DAY,  @CreatedOn, GETDATE());
    DECLARE @Months  INT = DATEDIFF(MONTH,@CreatedOn, GETDATE());
    DECLARE @Years   INT = DATEDIFF(YEAR, @CreatedOn, GETDATE());
    DECLARE @Result  NVARCHAR(50);

    SET @Result =
        CASE
            WHEN @Days   < 1    THEN '< 1 day'
            WHEN @Days   < 30   THEN CAST(@Days  AS NVARCHAR) + ' days'
            WHEN @Months < 12   THEN CAST(@Months AS NVARCHAR) + ' months'
            ELSE
                CAST(@Years AS NVARCHAR) + ' year' + CASE WHEN @Years > 1 THEN 's ' ELSE ' ' END
                + CAST(@Months - (@Years * 12) AS NVARCHAR) + ' months'
        END;

    RETURN @Result;
END;
GO
