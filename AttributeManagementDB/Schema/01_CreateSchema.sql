IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'shashank')
    EXEC('CREATE SCHEMA shashank');
GO