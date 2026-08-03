USE TrainingDB;
GO

IF OBJECT_ID('shashank.AttributeAudit','U') IS NULL
CREATE TABLE shashank.AttributeAudit (
    AuditId          INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_AttrAudit PRIMARY KEY,
    AttributeId      INT            NOT NULL,
    Action           NVARCHAR(10)   NOT NULL,
    OldAttributeName NVARCHAR(300)  NULL,
    NewAttributeName NVARCHAR(300)  NULL,
    OldIsActive      BIT            NULL,
    NewIsActive      BIT            NULL,
    ChangedBy        NVARCHAR(100)  NULL,
    ChangedOn        DATETIME2(0)   NOT NULL DEFAULT GETDATE()
);
GO

CREATE OR ALTER TRIGGER shashank.trgAttribute_AfterInsert
ON shashank.Attribute
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO shashank.AttributeAudit
        (AttributeId, Action, NewAttributeName, NewIsActive, ChangedBy, ChangedOn)
    SELECT
        i.AttributeId, 'INSERT', i.AttributeName, i.IsActive, i.CreatedBy, GETDATE()
    FROM INSERTED i;
END;
GO

CREATE OR ALTER TRIGGER shashank.trgAttribute_AfterUpdate
ON shashank.Attribute
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO shashank.AttributeAudit
        (AttributeId, Action, OldAttributeName, NewAttributeName,
         OldIsActive, NewIsActive, ChangedBy, ChangedOn)
    SELECT
        i.AttributeId, 'UPDATE',
        d.AttributeName, i.AttributeName,
        d.IsActive,      i.IsActive,
        i.UpdatedBy,     GETDATE()
    FROM INSERTED i
    JOIN DELETED  d ON d.AttributeId = i.AttributeId
    WHERE i.AttributeName <> d.AttributeName
       OR i.IsActive      <> d.IsActive;
END;
GO

CREATE OR ALTER TRIGGER shashank.trgAttribute_AfterDelete
ON shashank.Attribute
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO shashank.AttributeAudit
        (AttributeId, Action, OldAttributeName, OldIsActive, ChangedBy, ChangedOn)
    SELECT
        d.AttributeId, 'DELETE', d.AttributeName, d.IsActive, d.UpdatedBy, GETDATE()
    FROM DELETED d;
END;
GO

CREATE OR ALTER VIEW shashank.vw_ActiveAttributes AS
    SELECT * FROM shashank.Attribute WHERE IsActive = 1;
GO

CREATE OR ALTER TRIGGER shashank.trgActiveAttr_InsteadOfDelete
ON shashank.vw_ActiveAttributes
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE shashank.Attribute
    SET    IsActive  = 0,
           UpdatedOn = GETDATE(),
           UpdatedBy = 'SYSTEM_VIEW_DELETE'
    WHERE  AttributeId IN (SELECT AttributeId FROM DELETED);
END;
GO
