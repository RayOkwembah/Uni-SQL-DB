-- ============================================================
-- University Library Management System
-- queries.sql — 15 analytical queries (beginner → advanced)
-- ============================================================

-- ============================================================
-- BASIC QUERIES
-- ============================================================

-- Q1. List all books with their category name (simple JOIN)
SELECT
    b.book_id,
    b.title,
    c.name    AS category,
    b.publisher,
    b.published_year,
    b.available_copies,
    b.total_copies
FROM books b
JOIN categories c ON b.category_id = c.category_id
ORDER BY c.name, b.title;

-- Q2. Find all students enrolled in Computer Science
SELECT
    student_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    year_of_study
FROM students
WHERE major = 'Computer Science'
ORDER BY year_of_study, last_name;

-- Q3. Show all books that currently have no available copies
SELECT
    b.title,
    c.name AS category,
    b.total_copies
FROM books b
JOIN categories c ON b.category_id = c.category_id
WHERE b.available_copies = 0;

-- ============================================================
-- INTERMEDIATE QUERIES
-- ============================================================

-- Q4. List every book with all its authors (multi-row join)
SELECT
    b.title,
    CONCAT(a.first_name, ' ', a.last_name) AS author,
    a.nationality,
    c.name AS category
FROM books b
JOIN book_authors ba ON b.book_id   = ba.book_id
JOIN authors a       ON ba.author_id = a.author_id
JOIN categories c    ON b.category_id = c.category_id
ORDER BY b.title, a.last_name;

-- Q5. Show all currently active loans with days remaining / overdue
SELECT
    l.loan_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student,
    b.title,
    l.loan_date,
    l.due_date,
    CASE
        WHEN DATEDIFF(l.due_date, CURRENT_DATE) >= 0
            THEN CONCAT(DATEDIFF(l.due_date, CURRENT_DATE), ' days remaining')
        ELSE
            CONCAT(ABS(DATEDIFF(l.due_date, CURRENT_DATE)), ' days OVERDUE')
    END AS status
FROM loans l
JOIN students s ON l.student_id = s.student_id
JOIN books    b ON l.book_id    = b.book_id
WHERE l.return_date IS NULL
ORDER BY l.due_date;

-- Q6. How many times has each book been borrowed? (GROUP BY + aggregate)
SELECT
    b.title,
    COUNT(l.loan_id)  AS times_borrowed,
    c.name            AS category
FROM books b
LEFT JOIN loans      l ON b.book_id    = l.book_id
LEFT JOIN categories c ON b.category_id = c.category_id
GROUP BY b.book_id, b.title, c.name
ORDER BY times_borrowed DESC;

-- Q7. Students with unpaid fines (subquery approach)
SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS student,
    s.email,
    SUM(f.amount) AS total_unpaid
FROM students s
JOIN loans l ON s.student_id = l.student_id
JOIN fines f ON l.loan_id    = f.loan_id
WHERE f.paid_at IS NULL
GROUP BY s.student_id, s.first_name, s.last_name, s.email
ORDER BY total_unpaid DESC;

-- Q8. Average loan duration (in days) per category
SELECT
    c.name AS category,
    ROUND(AVG(DATEDIFF(l.return_date, l.loan_date)), 1) AS avg_loan_days,
    COUNT(l.loan_id)                                    AS total_loans
FROM loans l
JOIN books      b ON l.book_id    = b.book_id
JOIN categories c ON b.category_id = c.category_id
WHERE l.return_date IS NOT NULL
GROUP BY c.category_id, c.name
ORDER BY avg_loan_days DESC;

-- ============================================================
-- ADVANCED QUERIES
-- ============================================================

-- Q9. Rank students by number of books borrowed (window function)
SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS student,
    s.major,
    COUNT(l.loan_id)                        AS books_borrowed,
    RANK() OVER (ORDER BY COUNT(l.loan_id) DESC) AS borrow_rank
FROM students s
LEFT JOIN loans l ON s.student_id = l.student_id
GROUP BY s.student_id, s.first_name, s.last_name, s.major
ORDER BY borrow_rank;

-- Q10. Monthly borrowing trend (GROUP BY year-month)
SELECT
    DATE_FORMAT(loan_date, '%Y-%m') AS month,
    COUNT(*)                        AS loans_issued
FROM loans
GROUP BY month
ORDER BY month;

-- Q11. Most popular category per student year (CTE + window function)
WITH category_popularity AS (
    SELECT
        s.year_of_study,
        c.name           AS category,
        COUNT(l.loan_id) AS loan_count,
        RANK() OVER (
            PARTITION BY s.year_of_study
            ORDER BY COUNT(l.loan_id) DESC
        ) AS rnk
    FROM loans l
    JOIN students   s ON l.student_id  = s.student_id
    JOIN books      b ON l.book_id     = b.book_id
    JOIN categories c ON b.category_id = c.category_id
    GROUP BY s.year_of_study, c.category_id, c.name
)
SELECT year_of_study, category, loan_count
FROM   category_popularity
WHERE  rnk = 1
ORDER BY year_of_study;

-- Q12. Students who have never borrowed a book (LEFT JOIN + IS NULL)
SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS student,
    s.email,
    s.major,
    s.year_of_study
FROM students s
LEFT JOIN loans l ON s.student_id = l.student_id
WHERE l.loan_id IS NULL;

-- Q13. Books overdue right now with estimated fine if returned today
SELECT
    b.title,
    CONCAT(s.first_name, ' ', s.last_name) AS student,
    l.due_date,
    DATEDIFF(CURRENT_DATE, l.due_date)     AS days_overdue,
    DATEDIFF(CURRENT_DATE, l.due_date) * 0.50 AS estimated_fine
FROM loans l
JOIN books    b ON l.book_id    = b.book_id
JOIN students s ON l.student_id = s.student_id
WHERE l.return_date IS NULL
  AND l.due_date < CURRENT_DATE
ORDER BY days_overdue DESC;

-- Q14. Fine collection rate per month (paid vs total)
SELECT
    DATE_FORMAT(issued_at, '%Y-%m') AS month,
    COUNT(*)                        AS fines_issued,
    SUM(amount)                     AS total_fined,
    SUM(CASE WHEN paid_at IS NOT NULL THEN amount ELSE 0 END) AS collected,
    ROUND(
        100.0 * SUM(CASE WHEN paid_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        1
    )                               AS pct_paid
FROM fines
GROUP BY month
ORDER BY month;

-- Q15. Full student borrowing history with running total of fines (CTE + window)
WITH student_loans AS (
    SELECT
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        b.title,
        l.loan_date,
        l.return_date,
        COALESCE(f.amount, 0)                   AS fine_amount
    FROM students s
    JOIN loans l ON s.student_id = l.student_id
    JOIN books  b ON l.book_id   = b.book_id
    LEFT JOIN fines f ON l.loan_id = f.loan_id
)
SELECT
    student_name,
    title,
    loan_date,
    return_date,
    fine_amount,
    SUM(fine_amount) OVER (
        PARTITION BY student_id
        ORDER BY loan_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_fine_total
FROM student_loans
ORDER BY student_name, loan_date;
