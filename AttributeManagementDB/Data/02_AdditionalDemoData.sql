USE TrainingDB;
GO

INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy, CreatedOn)
VALUES ('Tied Attribute X', 1, 1, 'TieTest', '2024-06-10'),
       ('Tied Attribute Y', 1, 1, 'TieTest', '2024-06-10');
GO

INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('Trigger Test Attribute', 1, 1, 'TriggerTest');
GO

UPDATE shashank.Attribute
SET AttributeName = 'Trigger Test Attribute RENAMED', UpdatedBy = 'TriggerTest'
WHERE AttributeName = 'Trigger Test Attribute';
GO

UPDATE shashank.Attribute
SET CreatedOn = GETDATE(), UpdatedBy = 'TriggerTest'
WHERE AttributeName = 'Trigger Test Attribute RENAMED';
GO

DELETE FROM shashank.Attribute
WHERE  AttributeName = 'Trigger Test Attribute RENAMED';
GO
