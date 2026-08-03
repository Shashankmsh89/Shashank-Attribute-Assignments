USE TrainingDB;
GO

INSERT INTO shashank.BusinessUnit (BusinessUnitName, CreatedBy) VALUES ('TestBU_Constraint', 'Admin');
INSERT INTO shashank.Company      (CompanyName,      CreatedBy) VALUES ('TestCo_Constraint', 'Admin');
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('DuplicateTest', 1, 1, 'Admin');
INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('DuplicateTest', 1, 1, 'Admin');
GO

INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CustomerLocationId, CompanyId, CreatedBy)
VALUES ('FKViolationTest', 1, 9999, 1, 'Admin');
GO

INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy, CreatedOn)
VALUES ('CheckViolationTest', 1, 1, 'Admin', '2099-01-01');
GO

INSERT INTO shashank.Attribute (AttributeName, BusinessUnitId, CompanyId, CreatedBy)
VALUES ('NullViolationTest', 1, 1, NULL);
GO

DELETE FROM shashank.Attribute    WHERE AttributeName = 'DuplicateTest';
DELETE FROM shashank.Company      WHERE CompanyName   = 'TestCo_Constraint';
DELETE FROM shashank.BusinessUnit WHERE BusinessUnitName = 'TestBU_Constraint';
DBCC CHECKIDENT ('shashank.BusinessUnit',     RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('shashank.Company',          RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('shashank.Attribute',        RESEED, 0) WITH NO_INFOMSGS;
GO

INSERT INTO shashank.BusinessUnit (BusinessUnitName, IsActive, CreatedBy, CreatedOn) VALUES
('Finance',         1, 'Admin',    '2023-01-10'),
('Human Resources', 1, 'Admin',    '2023-02-15'),
('IT Operations',   1, 'shashank', '2023-03-20'),
('Marketing',       0, 'Admin',    '2023-04-05'),
('Legal',           0, 'john.doe', '2023-05-01');
GO

INSERT INTO shashank.CustomerLocation (CustomerLocationName, BusinessUnitId, IsActive, CreatedBy, CreatedOn) VALUES
('Finance - Mumbai HQ',        1, 1, 'Admin',    '2023-01-15'),
('Finance - Delhi Branch',     1, 1, 'Admin',    '2023-02-01'),
('Finance - Hyderabad Office', 1, 0, 'Admin',    '2023-03-10'),
('HR - Bangalore',             2, 1, 'Admin',    '2023-03-20'),
('HR - Chennai',               2, 1, 'john.doe', '2023-04-01'),
('IT Ops - Data Center A',     3, 1, 'shashank', '2023-05-10'),
('IT Ops - Data Center B',     3, 1, 'shashank', '2023-06-15'),
('IT Ops - Remote Office',     3, 0, 'shashank', '2023-07-01'),
('Marketing - Pune',           4, 1, 'Admin',    '2023-08-01'),
('Marketing - Kolkata',        4, 1, 'Admin',    '2023-09-01');
GO

INSERT INTO shashank.Company (CompanyName, IsActive, CreatedBy, CreatedOn) VALUES
('GlobalTech Solutions', 1, 'Admin',    '2023-01-05'),
('DataBridge Pvt Ltd',   1, 'Admin',    '2023-02-10'),
('Nexus Enterprises',    1, 'shashank', '2023-03-15'),
('BlueCore Systems',     0, 'john.doe', '2023-04-20'),
('Vertex Analytics',     1, 'Admin',    '2023-05-25');
GO

INSERT INTO shashank.Attribute
    (AttributeName, BusinessUnitId, CustomerLocationId, CompanyId,
     IsActive, CreatedBy, CreatedOn, UpdatedOn, UpdatedBy)
VALUES
('Global Revenue Tracker',    1, 1, 1, 1, 'Admin',    '2023-02-01', NULL,         NULL),
('Budget Allocation Rule',    1, 2, 2, 1, 'Admin',    '2023-04-10', '2023-08-01', 'Admin'),
('Expense Approval Limit',    1, 3, 1, 0, 'Admin',    '2023-06-15', NULL,         NULL),
('Tax Compliance Flag',       1, 1, 3, 1, 'john.doe', '2023-08-20', '2024-01-10', 'john.doe'),
('Audit Trail Enabled',       1, 2, 5, 1, 'Admin',    '2024-01-05', NULL,         NULL),
('Headcount Limit',           2, 4, 2, 1, 'Admin',    '2023-03-01', NULL,         NULL),
('Leave Accrual Policy',      2, 5, 3, 1, 'john.doe', '2023-05-20', '2023-11-01', 'Admin'),
('Performance Rating Scale',  2, 4, 1, 0, 'Admin',    '2023-07-10', NULL,         NULL),
('Employee Data Encryption',  2, 5, 4, 1, 'Admin',    '2023-09-15', '2024-03-01', 'shashank'),
('Onboarding Checklist Flag', 2, NULL, 2, 1, 'shashank','2024-02-01', NULL,       NULL),
('Server Uptime Threshold',   3, 6, 3, 1, 'shashank', '2023-04-01', '2024-05-01', 'shashank'),
('Backup Retention Days',     3, 7, 5, 1, 'shashank', '2023-06-10', NULL,         NULL),
('Global Network Bandwidth',  3, 6, 1, 1, 'Admin',    '2023-08-05', '2024-02-20', 'Admin'),
('Patch Cycle Frequency',     3, 8, 2, 0, 'shashank', '2023-10-01', NULL,         NULL),
('Incident Response SLA',     3, 7, 3, 1, 'shashank', '2024-01-20', '2024-06-10', 'shashank'),
('Campaign Budget Cap',       4, NULL, 4, 1, 'Admin',    '2023-05-15', NULL,       NULL),
('Social Media Approval',     4, NULL, 5, 0, 'john.doe', '2023-07-20', '2023-12-01','Admin'),
('Lead Scoring Algorithm',    4, NULL, 2, 1, 'Admin',    '2023-09-10', NULL,       NULL),
('Contract Review Period',    5, NULL, 1, 1, 'john.doe', '2023-11-01', '2024-04-01','john.doe'),
('Data Retention Compliance', 5, NULL, 3, 1, 'Admin',    '2024-03-15', NULL,       NULL);
GO
