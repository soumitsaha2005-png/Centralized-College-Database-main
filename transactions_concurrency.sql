-- ==============================================================================
-- CHAPTER 5: TRANSACTIONS AND CONCURRENCY CONTROL
-- Student Management System — Centralized College Database (CCD)
-- ==============================================================================

USE CCD;

-- ==============================================================================
-- PREREQUISITE: Add enrollment table if not already present
-- ==============================================================================

CREATE TABLE IF NOT EXISTS enrollment (
  student_id INT NOT NULL,
  course_id  INT NOT NULL,
  status     VARCHAR(50) DEFAULT 'ACTIVE',
  enrollment_date DATE DEFAULT (CURRENT_DATE),
  PRIMARY KEY (student_id, course_id),
  FOREIGN KEY (student_id) REFERENCES student(student_id),
  FOREIGN KEY (course_id)  REFERENCES courses(course_id)
);

-- Optional: add seats_available column to courses for concurrency demo
ALTER TABLE courses ADD COLUMN IF NOT EXISTS seats_available INT DEFAULT 30;


-- ==============================================================================
-- TRANSACTION 1: Student Registration and Course Enrollment
-- Scenario: Add a new student Meera Joshi and enroll her in Database Systems
-- ==============================================================================

START TRANSACTION;

  -- Step 1: Insert the new student
  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (201, 'Meera Joshi', 20, '22 Brigade Road, Bangalore', 2024);

  -- Step 2: Save progress after student insertion
  SAVEPOINT after_student_insert;

  -- Step 3: Enroll the student in Database Systems (course_id = 16)
  INSERT INTO enrollment (student_id, course_id)
  VALUES (201, 16);

  -- Step 4: Verify the enrollment
  SELECT s.student_name, c.course_name
  FROM student s
  JOIN enrollment e ON s.student_id = e.student_id
  JOIN courses c    ON e.course_id  = c.course_id
  WHERE s.student_id = 201;

COMMIT;

/*
Expected Output:
+--------------+------------------+
| student_name | course_name      |
+--------------+------------------+
| Meera Joshi  | Database Systems |
+--------------+------------------+
*/


-- ==============================================================================
-- TRANSACTION 2: Update with SAVEPOINT and Partial ROLLBACK
-- Scenario: Update address for student 101; rollback an erroneous second update
-- ==============================================================================

START TRANSACTION;

  -- Step 1: Correct address update
  UPDATE student
  SET address = '55 Nehru Place, New Delhi'
  WHERE student_id = 101;

  SAVEPOINT address_checkpoint;

  -- Step 2: Erroneous update on wrong student
  UPDATE student
  SET address = 'WRONG ADDRESS'
  WHERE student_id = 102;

  -- Step 3: Rollback only the erroneous update
  ROLLBACK TO address_checkpoint;

  -- Step 4: Verify correct state
  SELECT student_id, student_name, address
  FROM student
  WHERE student_id IN (101, 102);

COMMIT;

/*
Expected Output:
+------------+--------------+----------------------------+
| student_id | student_name | address                    |
+------------+--------------+----------------------------+
|        101 | Rahul Sharma | 55 Nehru Place, New Delhi  |
|        102 | Priya Patel  | 45 Lake Ave, Mumbai        |
+------------+--------------+----------------------------+
Student 102 address is UNCHANGED — ROLLBACK TO SAVEPOINT worked correctly.
*/


-- ==============================================================================
-- TRANSACTION 3: Cascade Delete of a Course and its Enrollments
-- Scenario: Remove World History II (course_id = 20) and all related enrollments
-- ==============================================================================

START TRANSACTION;

  SAVEPOINT before_deletion;

  -- Step 1: Delete all enrollments for the course first (avoid FK violation)
  DELETE FROM enrollment
  WHERE course_id = 20;

  -- Step 2: Delete the course itself
  DELETE FROM courses
  WHERE course_id = 20;

  -- Step 3: Verify no orphan enrollments remain
  SELECT * FROM enrollment WHERE course_id = 20;

  -- Step 4: Verify course is removed
  SELECT * FROM courses WHERE course_id = 20;

COMMIT;

/*
Expected Output:
Both queries return Empty set
-- If error occurred, use: ROLLBACK TO before_deletion;
*/


-- ==============================================================================
-- TRANSACTION 4: Course Transfer (Drop one course, Add another)
-- Scenario: Student 103 drops Electronics I (12), enrolls in Computer Networks (11)
-- ==============================================================================

START TRANSACTION;

  SAVEPOINT before_transfer;

  -- Step 1: Drop old course enrollment
  DELETE FROM enrollment
  WHERE student_id = 103 AND course_id = 12;

  -- Step 2: Add new course enrollment
  INSERT INTO enrollment (student_id, course_id)
  VALUES (103, 11);

  -- Step 3: Verify the transfer
  SELECT s.student_name, c.course_name
  FROM student s
  JOIN enrollment e ON s.student_id = e.student_id
  JOIN courses c    ON e.course_id  = c.course_id
  WHERE s.student_id = 103;

  -- Uncomment to rollback if wrong: ROLLBACK TO before_transfer;

COMMIT;

/*
Expected Output:
+--------------+-------------------+
| student_name | course_name       |
+--------------+-------------------+
| Ankit Verma  | Power Systems     |
| Ankit Verma  | Computer Networks |
+--------------+-------------------+
*/


-- ==============================================================================
-- TRANSACTION 5: Bulk Update of Course Duration with Validation
-- Scenario: Update all CS department (dept_id = 1) courses to 12 months
-- ==============================================================================

START TRANSACTION;

  -- Step 1: See original durations
  SELECT course_id, course_name, course_duration
  FROM courses
  WHERE department_id = 1;

  SAVEPOINT before_bulk_update;

  -- Step 2: Bulk update
  UPDATE courses
  SET course_duration = '12 months'
  WHERE department_id = 1;

  -- Step 3: Check affected rows
  SELECT ROW_COUNT() AS rows_updated;

  -- Step 4: Verify results
  SELECT course_id, course_name, course_duration
  FROM courses
  WHERE department_id = 1;

  -- Uncomment to rollback: ROLLBACK TO before_bulk_update;

COMMIT;

/*
Expected Output (After Update):
+-----------+------------------------------+-----------------+
| course_id | course_name                  | course_duration |
+-----------+------------------------------+-----------------+
|         1 | Intro to Computer Science    | 12 months       |
|         2 | Digital Logic Design         | 12 months       |
|         6 | Data Structures & Algorithms | 12 months       |
|        11 | Computer Networks            | 12 months       |
|        16 | Database Systems             | 12 months       |
+-----------+------------------------------+-----------------+
*/


-- ==============================================================================
-- CONCURRENCY CONTROL EXAMPLE 1: SELECT ... FOR UPDATE (Row-Level Locking)
-- Scenario: Two admins enrolling students in same course simultaneously
-- Run Session A first, then Session B in a second MySQL connection
-- ==============================================================================

-- ---- SESSION A ----
START TRANSACTION;  -- Session A

  -- Acquires exclusive row-level lock → Session B will WAIT
  SELECT course_id, course_name, seats_available
  FROM courses
  WHERE course_id = 16
  FOR UPDATE;

  -- Enroll Student 201
  INSERT INTO enrollment (student_id, course_id)
  VALUES (201, 16);

  -- Decrement available seats
  UPDATE courses
  SET seats_available = seats_available - 1
  WHERE course_id = 16;

COMMIT;  -- Lock released; Session B can now proceed


-- ---- SESSION B (run in a second connection after Session A starts) ----
START TRANSACTION;  -- Session B

  -- Waits until Session A commits, then reads updated seats_available
  SELECT course_id, course_name, seats_available
  FROM courses
  WHERE course_id = 16
  FOR UPDATE;

  -- Enroll Student 202
  INSERT INTO enrollment (student_id, course_id)
  VALUES (202, 16);

  -- Decrement seats — correctly reflects Session A's decrement
  UPDATE courses
  SET seats_available = seats_available - 1
  WHERE course_id = 16;

COMMIT;


-- ==============================================================================
-- CONCURRENCY CONTROL EXAMPLE 2: LOCK TABLES (Table-Level Locking)
-- Scenario: Batch grade finalization — lock enrollment table to prevent changes
-- ==============================================================================

-- Acquire write lock on enrollment, read lock on student and courses
LOCK TABLES
  enrollment WRITE,
  student    READ,
  courses    READ;

  -- Batch update: Finalize all active enrollments for 2024
  UPDATE enrollment
  SET status = 'FINALIZED'
  WHERE YEAR(enrollment_date) = 2024;

  -- Audit count of finalized records
  SELECT COUNT(*) AS finalized_count
  FROM enrollment
  WHERE status = 'FINALIZED';

-- Release all locks
UNLOCK TABLES;

/*
Expected Output:
+-----------------+
| finalized_count |
+-----------------+
|              47 |
+-----------------+
*/

-- ==============================================================================
-- END OF CHAPTER 5 SQL EXAMPLES
-- Student Management System — Centralized College Database
-- ==============================================================================
