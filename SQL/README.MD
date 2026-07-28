# SQL Server Database Foundation Assignment

## Overview

This project is a SQL Server database assignment developed for the **Amicus Fresher Development Program – Path 2**.

The objective is to demonstrate a strong understanding of relational database design, SQL Server programming, constraints, data integrity, DML operations, filtering, aggregation, and advanced SQL concepts using a realistic Attribute Management database.

The solution uses Microsoft SQL Server and follows good database design practices such as normalization, foreign keys, check constraints, unique constraints, default constraints, and meaningful sample data.

---

# Developer

**Developer:** Shashank Masih

**Mentor:** Shivam

**Database:** TrainingDB

**Schema:** shashank

---

# Project Objectives

The assignment demonstrates:

- Database creation
- Schema creation
- Table design
- Primary Keys
- Foreign Keys
- Unique Constraints
- Check Constraints
- Default Constraints
- Identity Columns
- Data Population
- UPDATE statements
- DELETE statements
- MERGE statements
- Filtering
- Logical Operators
- Pagination
- Aggregate Functions
- String Functions
- Date Functions
- CASE Expressions
- PIVOT
- UNPIVOT
- CROSS APPLY

---

# Database Structure

The project contains four relational tables.

## BusinessUnit

Stores business units within the organization.

Examples:

- Finance
- Human Resources
- IT Operations
- Marketing
- Legal

---

## CustomerLocation

Stores customer locations.

Each location belongs to one Business Unit.

Relationship

BusinessUnit

↓

CustomerLocation

---

## Company

Stores companies associated with attributes.

Examples:

- GlobalTech Solutions
- DataBridge Pvt Ltd
- Nexus Enterprises

---

## Attribute

The central entity of the project.

Stores:

- Attribute Name
- Business Unit
- Customer Location
- Company
- Status
- Created Information
- Updated Information

Relationships

BusinessUnit

↓

Attribute

↑

CustomerLocation

↓

Company

---

# Features

- Fully normalized database
- Identity Primary Keys
- Foreign Key relationships
- Unique Constraints
- Default Constraints
- Check Constraints
- Safe object recreation
- Sample production-like data
- Constraint violation demonstrations
- CRUD operations
- MERGE Upsert
- Pagination
- Aggregation
- Pivoting
- Unpivoting
- CROSS APPLY
- Advanced filtering

---

# Assignment Tasks

## Task 1

Database Foundation

- Schema creation
- Safe object cleanup

---

## Task 2

Database Design

Created tables:

- BusinessUnit
- CustomerLocation
- Company
- Attribute

Implemented:

- Primary Keys
- Foreign Keys
- Default Constraints
- Unique Constraints
- Check Constraints

---

## Task 3

Constraint Demonstrations

Intentional violations were created for:

- UNIQUE constraint
- FOREIGN KEY constraint
- CHECK constraint
- NOT NULL constraint

These examples demonstrate SQL Server's integrity enforcement.

---

## Task 4

Data Population

Inserted realistic sample data including:

- Multiple Business Units
- Customer Locations
- Companies
- Attributes
- Active and inactive records
- Different creators
- Different creation dates

---

## Task 5

UPDATE

Updated all Marketing attributes to inactive.

Demonstrates safe UPDATE practices by previewing records before modification.

---

## Task 6

DELETE

Removed Customer Locations without Attributes.

Demonstrates:

- DELETE
- NOT EXISTS
- Safe filtering

---

## Task 7

MERGE

Performed UPSERT operations using MERGE.

Covered:

- MATCHED
- NOT MATCHED
- OUTPUT clause

---

## Task 8

Filtering

Implemented:

- BETWEEN
- IN
- NOT IN
- NOT EXISTS
- LEFT JOIN
- LIKE
- AND
- OR
- NOT

---

## Task 9

Pagination

Implemented:

- TOP
- TOP WITH TIES
- OFFSET FETCH
- Parameterized Pagination

---

## Task 10

Aggregate Functions

Used:

- COUNT
- AVG
- MAX
- MIN
- GROUP BY
- HAVING

---

## Task 11

String Functions

Used:

- CHARINDEX
- UPPER
- SUBSTRING
- REPLACE
- LEN

---

## Task 12

Date Functions

Used:

- DATEADD
- DATEDIFF
- FORMAT
- CONVERT
- YEAR
- MONTH
- DATENAME

---

## Task 13

CASE Expressions

Generated:

- Status
- Age Category
- Data Completeness

using CASE expressions.

---

## Task 14

PIVOT

Converted row-based data into columns.

---

## Task 15

UNPIVOT

Converted column-based data back into rows.

---

## Task 16

CROSS APPLY

Used CROSS APPLY with VALUES to generate additional calculated rows.

---

# Database Design Decisions

Several SQL Server best practices were followed throughout the project.

## Why DATETIME2 instead of DATETIME?

DATETIME2 provides:

- Better precision
- Larger date range
- Less storage
- Recommended by Microsoft

---

## Why BIT for status?

BIT is the most efficient data type for storing boolean values.

---

## Why NVARCHAR instead of VARCHAR?

NVARCHAR supports Unicode, allowing international characters.

---

## Why use CHECK constraints?

CHECK constraints prevent invalid data from entering the database.

Example:

Future creation dates are rejected.

---

## Why use UNIQUE constraints?

Prevents duplicate business data while still allowing efficient indexing.

---

## Why use Foreign Keys?

Foreign Keys guarantee referential integrity between tables.

---

## Why use MERGE?

MERGE allows INSERT and UPDATE operations to be performed in a single statement.

---

# Concepts Demonstrated

- Relational Database Design
- Data Integrity
- Referential Integrity
- SQL Server Constraints
- Data Manipulation
- Query Optimization Concepts
- Aggregate Queries
- Conditional Logic
- Data Transformation
- Advanced Query Techniques

---

# Requirements

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)

---

# Running the Project

1. Create the database:

```
CREATE DATABASE TrainingDB;
```

2. Open the assignment SQL script.

3. Execute the script in SQL Server Management Studio.

4. Verify tables and inserted data.

---

# Learning Outcomes

This assignment strengthened understanding of:

- SQL Server architecture
- Relational database modeling
- Constraint enforcement
- Query writing
- Data transformation
- SQL Server best practices
- Production-style database development

---

# Author

**Shashank Masih**

Amicus Fresher Development Program

Path 2 – SQL Server Database Foundation