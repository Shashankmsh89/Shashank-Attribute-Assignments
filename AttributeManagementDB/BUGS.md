# Deliberate Bugs

## Bug 1 – UPDATE without WHERE

### Description
A demonstration of how an UPDATE statement without a WHERE clause can unintentionally modify every record.

### Cause
The filtering condition was omitted.

### Fix
Always include an appropriate WHERE clause before executing UPDATE statements.

### Lesson Learned
Review UPDATE statements carefully before execution.

---

## Bug 2 – Foreign Key Constraint Violation

### Description
Attempting to insert an Attribute using a CompanyId that does not exist.

### Cause
The referenced parent record was missing.

### Error
The INSERT statement conflicted with the FOREIGN KEY constraint.

### Fix
Insert the parent Company record first or use a valid CompanyId.

### Lesson Learned
Maintain referential integrity by validating foreign keys before inserting child records.
