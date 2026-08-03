USE TrainingDB;
GO

CREATE OR ALTER FUNCTION shashank.fnGetBusinessUnitReport
    (@BusinessUnitId INT)
RETURNS @Result TABLE (
    AttributeId   INT,
    AttributeName NVARCHAR(300),
    AgeCategory   NVARCHAR(20),
    DaysOld       INT,
    CompanyName   NVARCHAR(250),
    LocationName  NVARCHAR(300),
    Status        NVARCHAR(10)
)
AS
BEGIN
    INSERT INTO @Result (AttributeId, AttributeName, AgeCategory, DaysOld,
                         CompanyName, LocationName, Status)
    SELECT
        a.AttributeId,
        a.AttributeName,
        ''                                               AS AgeCategory,
        DATEDIFF(DAY, a.CreatedOn, GETDATE())           AS DaysOld,
        co.CompanyName,
        ISNULL(cl.CustomerLocationName, 'No Location')  AS LocationName,
        ''                                               AS Status
    FROM shashank.Attribute        a
    JOIN shashank.Company          co ON co.CompanyId             = a.CompanyId
    LEFT JOIN shashank.CustomerLocation cl ON cl.CustomerLocationId = a.CustomerLocationId
    WHERE a.BusinessUnitId = @BusinessUnitId;

    UPDATE @Result
    SET AgeCategory =
        CASE
            WHEN DaysOld <  90  THEN 'New'
            WHEN DaysOld <  180 THEN 'Recent'
            WHEN DaysOld <  365 THEN 'Established'
            ELSE                     'Old'
        END;

    UPDATE r
    SET    r.Status = CASE WHEN a.IsActive = 1 THEN 'Active' ELSE 'Inactive' END
    FROM   @Result r
    JOIN   shashank.Attribute a ON a.AttributeId = r.AttributeId;

    RETURN;
END;
GO
