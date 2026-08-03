USE TrainingDB;
GO

CREATE NONCLUSTERED INDEX IX_Attribute_AttributeName
ON shashank.Attribute (AttributeName);

CREATE NONCLUSTERED INDEX IX_Attribute_BusinessUnitId_Cover
ON shashank.Attribute (BusinessUnitId)
INCLUDE (AttributeName, IsActive, CreatedOn, CompanyId, CustomerLocationId);

CREATE NONCLUSTERED INDEX IX_Attribute_BU_IsActive
ON shashank.Attribute (BusinessUnitId, IsActive);
GO
