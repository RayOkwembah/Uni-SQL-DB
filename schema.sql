-- ============================================================
-- University Library Management System
-- schema.sql — Database schema with all tables and constraints
-- ============================================================

-- Drop tables if they already exist (useful for re-running the script)
DROP TABLE IF EXISTS fines;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS book_authors;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS students;

-- ============================================================
-- STUDENTS
-- Stores university student information
-- ============================================================
CREATE TABLE students (
    student_id    INT PRIMARY KEY AUTO_INCREMENT,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    major         VARCHAR(80),
    year_of_study TINYINT      CHECK (year_of_study BETWEEN 1 AND 6),
    enrolled_at   DATE         NOT NULL DEFAULT (CURRENT_DATE),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ============================================================
-- CATEGORIES
-- Genre / subject classification for books
-- ============================================================
CREATE TABLE categories (
    category_id   INT PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(80) NOT NULL UNIQUE,
    description   TEXT
);

-- ============================================================
-- AUTHORS
-- Separate table to handle many-to-many with books
-- ============================================================
CREATE TABLE authors (
    author_id     INT PRIMARY KEY AUTO_INCREMENT,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    nationality   VARCHAR(60),
    birth_year    YEAR
);

-- ============================================================
-- BOOKS
-- Core catalogue of library holdings
-- ============================================================
CREATE TABLE books (
    book_id       INT PRIMARY KEY AUTO_INCREMENT,
    isbn          VARCHAR(20)  NOT NULL UNIQUE,
    title         VARCHAR(200) NOT NULL,
    category_id   INT          NOT NULL,
    publisher     VARCHAR(100),
    published_year YEAR,
    total_copies  TINYINT      NOT NULL DEFAULT 1 CHECK (total_copies >= 1),
    available_copies TINYINT   NOT NULL DEFAULT 1,
    CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT chk_available CHECK (available_copies <= total_copies AND available_copies >= 0)
);

-- ============================================================
-- BOOK_AUTHORS  (junction table — resolves many-to-many)
-- A book can have multiple authors; an author can write many books
-- ============================================================
CREATE TABLE book_authors (
    book_id       INT NOT NULL,
    author_id     INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book   FOREIGN KEY (book_id)   REFERENCES books(book_id),
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

-- ============================================================
-- LOANS
-- Tracks which student borrowed which book and when
-- ============================================================
CREATE TABLE loans (
    loan_id       INT PRIMARY KEY AUTO_INCREMENT,
    student_id    INT  NOT NULL,
    book_id       INT  NOT NULL,
    loan_date     DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date      DATE NOT NULL,
    return_date   DATE,          -- NULL means not yet returned
    CONSTRAINT fk_loan_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_loan_book    FOREIGN KEY (book_id)    REFERENCES books(book_id),
    CONSTRAINT chk_due_date    CHECK (due_date > loan_date),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= loan_date)
);

-- ============================================================
-- FINES
-- Auto-generated when a book is returned late (or still overdue)
-- ============================================================
CREATE TABLE fines (
    fine_id       INT PRIMARY KEY AUTO_INCREMENT,
    loan_id       INT            NOT NULL UNIQUE,  -- one fine per loan
    amount        DECIMAL(6, 2)  NOT NULL CHECK (amount > 0),
    issued_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_at       DATETIME,                        -- NULL = unpaid
    CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);

-- ============================================================
-- VIEWS
-- ============================================================

-- Active loans with student and book details
CREATE OR REPLACE VIEW v_active_loans AS
SELECT
    l.loan_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email,
    b.title,
    b.isbn,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURRENT_DATE, l.due_date) AS days_overdue
FROM loans l
JOIN students s ON l.student_id = s.student_id
JOIN books    b ON l.book_id    = b.book_id
WHERE l.return_date IS NULL;

-- Book availability summary
CREATE OR REPLACE VIEW v_book_availability AS
SELECT
    b.book_id,
    b.title,
    b.isbn,
    c.name          AS category,
    b.total_copies,
    b.available_copies,
    (b.total_copies - b.available_copies) AS copies_on_loan
FROM books b
JOIN categories c ON b.category_id = c.category_id;

-- Student fine summary
CREATE OR REPLACE VIEW v_student_fines AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    COUNT(f.fine_id)                        AS total_fines,
    SUM(f.amount)                           AS total_owed,
    SUM(CASE WHEN f.paid_at IS NULL THEN f.amount ELSE 0 END) AS unpaid_amount
FROM students s
LEFT JOIN loans l ON s.student_id = l.student_id
LEFT JOIN fines f ON l.loan_id    = f.loan_id
GROUP BY s.student_id, student_name;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- Borrow a book: validates availability and creates a loan record
CREATE PROCEDURE borrow_book(
    IN p_student_id INT,
    IN p_book_id    INT,
    IN p_days       TINYINT       -- loan duration in days
)
BEGIN
    DECLARE v_available INT;

    SELECT available_copies INTO v_available
    FROM books WHERE book_id = p_book_id;

    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not found.';
    ELSEIF v_available < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No copies available right now.';
    ELSE
        INSERT INTO loans (student_id, book_id, loan_date, due_date)
        VALUES (p_student_id, p_book_id, CURRENT_DATE, DATE_ADD(CURRENT_DATE, INTERVAL p_days DAY));

        UPDATE books
        SET available_copies = available_copies - 1
        WHERE book_id = p_book_id;
    END IF;
END$$

-- Return a book: marks loan as returned and generates a fine if late
CREATE PROCEDURE return_book(IN p_loan_id INT)
BEGIN
    DECLARE v_due_date    DATE;
    DECLARE v_book_id     INT;
    DECLARE v_days_late   INT;
    DECLARE v_fine_amount DECIMAL(6,2);

    SELECT due_date, book_id INTO v_due_date, v_book_id
    FROM loans WHERE loan_id = p_loan_id AND return_date IS NULL;

    IF v_due_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Loan not found or already returned.';
    END IF;

    -- Mark as returned
    UPDATE loans SET return_date = CURRENT_DATE WHERE loan_id = p_loan_id;

    -- Restore available copy
    UPDATE books SET available_copies = available_copies + 1 WHERE book_id = v_book_id;

    -- Charge $0.50 per day late
    SET v_days_late = DATEDIFF(CURRENT_DATE, v_due_date);
    IF v_days_late > 0 THEN
        SET v_fine_amount = v_days_late * 0.50;
        INSERT INTO fines (loan_id, amount) VALUES (p_loan_id, v_fine_amount);
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER: prevent borrowing if student has unpaid fines > $5
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_check_fines_before_loan
BEFORE INSERT ON loans
FOR EACH ROW
BEGIN
    DECLARE v_unpaid DECIMAL(6,2);

    SELECT COALESCE(SUM(f.amount), 0) INTO v_unpaid
    FROM fines f
    JOIN loans l ON f.loan_id = l.loan_id
    WHERE l.student_id = NEW.student_id AND f.paid_at IS NULL;

    IF v_unpaid > 5.00 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student has unpaid fines over $5. Please settle before borrowing.';
    END IF;
END$$
DELIMITER ;
