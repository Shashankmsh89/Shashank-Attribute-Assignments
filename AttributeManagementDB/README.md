# AttributeManagementDB

This folder contains the SQL assets reorganized into the requested structure.

## Structure
- Schema: CREATE SCHEMA / CREATE TABLE / ALTER TABLE / constraints and related database-object definitions.
- Data: INSERT and other data-loading statements.
- StoredProcedures: one SQL file per stored procedure.
- Functions: one SQL file per user-defined function.
- Indexes: CREATE INDEX statements.

## Notes
- The original source scripts in the SQL folder were preserved as-is and were not rewritten or optimized.
- The object shashank.uspSaveAttribute appears in more than one source script; the stored procedure file in this folder uses the later Assignment 5 implementation.
