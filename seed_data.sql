-- ============================================================
-- University Library Management System
-- seed_data.sql — Realistic sample data for all tables
-- ============================================================

-- ============================================================
-- CATEGORIES
-- ============================================================
INSERT INTO categories (name, description) VALUES
('Computer Science',    'Textbooks and references on programming, algorithms, and systems'),
('Mathematics',         'Pure and applied mathematics, statistics, and discrete math'),
('Physics',             'Classical and modern physics, quantum mechanics, and thermodynamics'),
('Literature',          'Fiction, poetry, and literary criticism'),
('History',             'World history, political history, and historical analysis'),
('Biology',             'Cell biology, genetics, ecology, and life sciences'),
('Economics',           'Micro and macroeconomics, econometrics, and financial theory'),
('Philosophy',          'Ethics, logic, epistemology, and metaphysics');

-- ============================================================
-- AUTHORS
-- ============================================================
INSERT INTO authors (first_name, last_name, nationality, birth_year) VALUES
('Thomas',    'Cormen',      'American',  1956),
('Donald',    'Knuth',       'American',  1938),
('Martin',    'Fowler',      'British',   1963),
('James',     'Stewart',     'Canadian',  1941),
('Richard',   'Feynman',     'American',  1918),
('George',    'Orwell',      'British',   1903),
('Yuval',     'Harari',      'Israeli',   1976),
('Stephen',   'Hawking',     'British',   1942),
('Jane',      'Austen',      'British',   1775),
('Carl',      'Sagan',       'American',  1934),
('Charles',   'Leiserson',   'American',  1953),
('Clifford',  'Stein',       'American',  1965),
('Ronald',    'Rivest',      'American',  1947),
('Paul',      'Krugman',     'American',  1953),
('Immanuel',  'Kant',        'German',    1724);

-- ============================================================
-- BOOKS
-- ============================================================
INSERT INTO books (isbn, title, category_id, publisher, published_year, total_copies, available_copies) VALUES
('978-0262033848', 'Introduction to Algorithms',           1, 'MIT Press',        2009, 4, 2),
('978-0201896831', 'The Art of Computer Programming',      1, 'Addison-Wesley',   1968, 2, 1),
('978-0134757599', 'Refactoring: Improving the Design',    1, 'Addison-Wesley',   2018, 3, 3),
('978-1305266643', 'Calculus: Early Transcendentals',      2, 'Cengage Learning', 2015, 5, 4),
('978-0321816184', 'Discrete Mathematics',                 2, 'Pearson',          2011, 3, 2),
('978-0805388480', 'Six Easy Pieces',                      3, 'Basic Books',      1994, 2, 2),
('978-0553380163', 'A Brief History of Time',              3, 'Bantam Books',     1988, 3, 1),
('978-0451524935', 'Nineteen Eighty-Four',                 4, 'Signet Classic',   1949, 4, 4),
('978-0141439518', 'Pride and Prejudice',                  4, 'Penguin Classics', 1813, 3, 3),
('978-0062316097', 'Sapiens: A Brief History',             5, 'Harper Perennial', 2011, 4, 2),
('978-0385333481', 'The Demon-Haunted World',              3, 'Ballantine Books', 1995, 2, 2),
('978-0393978575', 'The Return of Depression Economics',   7, 'W. W. Norton',     2009, 2, 1),
('978-0521880688', 'Principles of Economics',              7, 'Cambridge UP',     2007, 3, 3),
('978-0872201225', 'Groundwork of the Metaphysics of Morals', 8, 'Hackett',       1785, 2, 2),
('978-0140444308', 'The Selfish Gene',                     6, 'Penguin Books',    1976, 3, 2);

-- ============================================================
-- BOOK_AUTHORS (junction table)
-- ============================================================
INSERT INTO book_authors (book_id, author_id) VALUES
(1,  1),  -- Intro to Algorithms → Cormen
(1, 11),  -- Intro to Algorithms → Leiserson
(1, 12),  -- Intro to Algorithms → Stein
(1, 13),  -- Intro to Algorithms → Rivest
(2,  2),  -- Art of Computer Programming → Knuth
(3,  3),  -- Refactoring → Fowler
(4,  4),  -- Calculus → Stewart
(6,  5),  -- Six Easy Pieces → Feynman
(7,  8),  -- Brief History of Time → Hawking
(8,  6),  -- 1984 → Orwell
(9,  9),  -- Pride and Prejudice → Austen
(10, 7),  -- Sapiens → Harari
(11,10),  -- Demon-Haunted World → Sagan
(12,14),  -- Depression Economics → Krugman
(14,15);  -- Groundwork → Kant

-- ============================================================
-- STUDENTS
-- ============================================================
INSERT INTO students (first_name, last_name, email, major, year_of_study, enrolled_at) VALUES
('Alice',   'Johnson',  'alice.johnson@uni.edu',    'Computer Science',    2, '2023-09-01'),
('Ben',     'Martinez', 'ben.martinez@uni.edu',     'Mathematics',         3, '2022-09-01'),
('Chloe',   'Thompson', 'chloe.thompson@uni.edu',   'Physics',             1, '2024-09-01'),
('David',   'Nguyen',   'david.nguyen@uni.edu',     'Economics',           4, '2021-09-01'),
('Eva',     'Smith',    'eva.smith@uni.edu',         'Literature',          2, '2023-09-01'),
('Frank',   'Kim',      'frank.kim@uni.edu',         'Computer Science',    3, '2022-09-01'),
('Grace',   'Patel',    'grace.patel@uni.edu',       'Biology',             1, '2024-09-01'),
('Henry',   'O''Brien', 'henry.obrien@uni.edu',      'History',             4, '2021-09-01'),
('Isabel',  'Chen',     'isabel.chen@uni.edu',       'Mathematics',         2, '2023-09-01'),
('Jack',    'Williams', 'jack.williams@uni.edu',     'Computer Science',    1, '2024-09-01'),
('Karen',   'Davis',    'karen.davis@uni.edu',       'Philosophy',          3, '2022-09-01'),
('Liam',    'Garcia',   'liam.garcia@uni.edu',       'Economics',           2, '2023-09-01'),
('Maya',    'Robinson', 'maya.robinson@uni.edu',     'Physics',             4, '2021-09-01'),
('Nathan',  'Lee',      'nathan.lee@uni.edu',        'Computer Science',    3, '2022-09-01'),
('Olivia',  'Walker',   'olivia.walker@uni.edu',     'Literature',          1, '2024-09-01');

-- ============================================================
-- LOANS
-- A mix of returned, active, and overdue loans
-- ============================================================
INSERT INTO loans (student_id, book_id, loan_date, due_date, return_date) VALUES
-- Returned on time
(1,  1,  '2024-01-10', '2024-01-24', '2024-01-22'),
(2,  4,  '2024-01-15', '2024-01-29', '2024-01-28'),
(3,  7,  '2024-02-01', '2024-02-15', '2024-02-14'),
(5,  8,  '2024-02-03', '2024-02-17', '2024-02-17'),
(6,  2,  '2024-02-10', '2024-02-24', '2024-02-20'),
(8, 10,  '2024-02-12', '2024-02-26', '2024-02-25'),
(9,  5,  '2024-03-01', '2024-03-15', '2024-03-12'),
(11,14,  '2024-03-05', '2024-03-19', '2024-03-18'),

-- Returned late (will generate fines via return_book procedure —
--  here we insert fines manually to match seed data)
(4, 12,  '2024-01-05', '2024-01-19', '2024-01-25'),  -- 6 days late
(7, 15,  '2024-02-05', '2024-02-19', '2024-02-26'),  -- 7 days late
(10, 3,  '2024-03-01', '2024-03-15', '2024-03-22'),  -- 7 days late
(12, 12, '2024-03-10', '2024-03-24', '2024-04-01'),  -- 8 days late

-- Still active (not yet returned)
(1,  6,  '2024-04-01', '2024-04-15', NULL),
(2,  1,  '2024-04-02', '2024-04-16', NULL),
(6,  3,  '2024-04-05', '2024-04-19', NULL),
(13, 7,  '2024-04-06', '2024-04-20', NULL),
(14, 2,  '2024-04-07', '2024-04-21', NULL),
(15, 8,  '2024-04-08', '2024-04-22', NULL),

-- Overdue (active but past due date — for demo purposes)
(3, 11,  '2024-03-01', '2024-03-15', NULL),   -- overdue
(5,  9,  '2024-03-05', '2024-03-19', NULL);   -- overdue

-- ============================================================
-- FINES  (for the late returns seeded above)
-- ============================================================
INSERT INTO fines (loan_id, amount, issued_at, paid_at) VALUES
(9,  3.00, '2024-01-25 10:00:00', '2024-01-26 09:00:00'),  -- paid
(10, 3.50, '2024-02-26 11:00:00', NULL),                   -- unpaid
(11, 3.50, '2024-03-22 14:00:00', '2024-03-23 10:00:00'),  -- paid
(12, 4.00, '2024-04-01 09:00:00', NULL);                   -- unpaid
