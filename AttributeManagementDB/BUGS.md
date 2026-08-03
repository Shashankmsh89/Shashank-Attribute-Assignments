# BUGS and Reorganization Notes

## Duplicate objects detected before reorganization
- shashank.uspSaveAttribute is defined in more than one source script:
  - SQL/assignment4_query.sql
  - SQL/assignment5query.sql
- The stored procedure file in this project uses the later Assignment 5 implementation so the object is represented once in the new folder structure.

## Missing objects detected before reorganization
- No database objects were missing from the source SQL; all relevant schema, data, procedure, function, and index definitions were captured in the new structure.

## Notes
- Standalone query exercises and isolation-level demo scripts were intentionally not moved into the object folders because they do not define reusable database objects.
- SQL logic and comments were preserved; only the project organization was changed.
