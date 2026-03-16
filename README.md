# 📚 University Library Management System

A relational database project built with MySQL, modelling the core operations of a university library — book cataloguing, student borrowing, overdue tracking, and fine management.

---

## Project Overview

This project demonstrates practical SQL skills through a realistic use case. It covers database design, normalisation, complex querying, and procedural SQL — the kinds of problems you encounter in real-world data engineering and backend development.

---

## Entity Relationship Diagram

```
students ────< loans >──── books >──── book_authors ────< authors
                │                          │
               fines                  categories
```

**Relationships:**
- A student can take out many loans; each loan belongs to one student
- A book can appear in many loans; each loan is for one book
- A book can have many authors; an author can write many books (many-to-many resolved via `book_authors`)
- Each loan may have at most one fine (one-to-one)
- Each book belongs to one category

---

## Database Schema

| Table          | Description                                              |
|----------------|----------------------------------------------------------|
| `students`     | University students who can borrow books                 |
| `categories`   | Subject/genre classifications (e.g. Computer Science)   |
| `authors`      | Book authors with nationality and birth year             |
| `books`        | Library catalogue with copy availability tracking       |
| `book_authors` | Junction table resolving many-to-many between books and authors |
| `loans`        | Records of book borrowing with loan and due dates        |
| `fines`        | Late return fines linked to individual loans             |

---

## Design Decisions

**Why separate `authors` from `books`?**  
A book can have multiple authors (e.g. *Introduction to Algorithms* has four). Storing authors in the `books` table directly would require either a comma-separated field (breaking 1NF) or lots of NULL columns. A junction table is the correct relational approach.

**Why track `available_copies` separately from `total_copies`?**  
Rather than counting active loans every time a user checks availability (which would be an expensive query on a large dataset), we update `available_copies` at the time of borrowing/returning. This is a classic trade-off: slightly more complexity on writes in exchange for fast reads.

**Why is `fine_id` a UNIQUE constraint on `loan_id`?**  
A single loan should never generate two fines. The UNIQUE constraint enforces this at the database level, not just the application level — a much safer guarantee.

**Why use a trigger to block borrowing with unpaid fines?**  
Business rules that must always hold (like "no borrowing with $5+ in fines") are safer enforced at the database level. If you only enforce them in application code, a different app or a direct SQL insert could bypass the rule.

---

## Features

- ✅ Fully normalised schema (3NF)
- ✅ Foreign key constraints and CHECK constraints
- ✅ Three useful views (`v_active_loans`, `v_book_availability`, `v_student_fines`)
- ✅ Two stored procedures (`borrow_book`, `return_book`)
- ✅ Business-rule trigger (blocks borrowing when fines exceed $5)
- ✅ 15 analytical queries ranging from basic JOINs to CTEs and window functions
- ✅ Realistic seed data (15 students, 15 books, 20 loans, 4 fines)

---

## Files

```
library-db/
├── schema.sql      # All CREATE TABLE, VIEW, PROCEDURE, and TRIGGER statements
├── seed_data.sql   # Sample data to populate the database
├── queries.sql     # 15 analytical SQL queries
└── README.md       # This file
```

---

## How to Run

**Prerequisites:** MySQL 8.0+ (or MariaDB 10.5+)

```bash
# 1. Create the database
mysql -u root -p -e "CREATE DATABASE library_db;"

# 2. Load the schema
mysql -u root -p library_db < schema.sql

# 3. Insert sample data
mysql -u root -p library_db < seed_data.sql

# 4. Run the queries
mysql -u root -p library_db < queries.sql
```

Or connect interactively and paste queries directly:

```bash
mysql -u root -p library_db
```

---

## Example Queries

**Find all overdue loans:**
```sql
SELECT * FROM v_active_loans WHERE days_overdue > 0;
```

**Borrow a book (using the stored procedure):**
```sql
CALL borrow_book(1, 5, 14);  -- student_id=1, book_id=5, 14 days
```

**Return a book:**
```sql
CALL return_book(1);  -- loan_id=1 (auto-calculates and inserts fine if late)
```

**Rank students by borrowing activity:**
```sql
-- See queries.sql → Q9
```

---

## SQL Concepts Demonstrated

| Concept                  | Where Used                              |
|--------------------------|-----------------------------------------|
| DDL (CREATE, DROP)       | `schema.sql`                            |
| Primary & foreign keys   | All tables                              |
| CHECK constraints        | `books`, `students`, `loans`            |
| JOINs (INNER, LEFT)      | Q1, Q4, Q5, Q6, Q12                    |
| GROUP BY + Aggregates    | Q6, Q7, Q8, Q10, Q14                   |
| Subqueries               | Q7, trigger                             |
| CTEs (WITH clause)       | Q11, Q15                                |
| Window functions         | Q9, Q11, Q15                            |
| CASE expressions         | Q5, Q14                                 |
| Views                    | `v_active_loans`, `v_book_availability` |
| Stored Procedures        | `borrow_book`, `return_book`            |
| Triggers                 | `trg_check_fines_before_loan`           |

---

## Potential Extensions

- Add a `reservations` table so students can queue for unavailable books
- Add a `staff` table to track which librarian processed each loan
- Build a Python or Node.js API on top of this schema
- Create a dashboard using a BI tool (e.g. Metabase, Grafana) connected to the DB
- Add full-text search on `books.title` using MySQL's `FULLTEXT` index

---

## Author

Built as a university database systems project.  
Okwembah Ray Jerome 
Feel free to fork, extend, or use as a learning reference.

---

## License

MIT — free to use for educational purposes.
