-- ============================================================
-- CHAPTER 4: NORMALIZATION — SQL DEMONSTRATION
-- Student Management System (Centralized College Database)
-- UNF → 1NF → 2NF → 3NF → BCNF → 4NF → 5NF
-- ============================================================

CREATE DATABASE IF NOT EXISTS SMS_Normalization;
USE SMS_Normalization;


-- ============================================================
-- STEP 0: UNNORMALIZED FORM (UNF)
-- Single flat table with repeating groups and multi-valued cells
-- Problem: CourseIDs and CourseNames store multiple values
-- ============================================================

CREATE TABLE IF NOT EXISTS Student_Raw (
    StudentID       INT,
    StudentName     VARCHAR(100),
    CourseIDs       VARCHAR(50),      -- Stores "1, 2" — NOT atomic
    CourseNames     VARCHAR(200),     -- Stores "OS, DBMS" — NOT atomic
    DeptID          INT,
    DeptName        VARCHAR(100),
    InstructorID    VARCHAR(50),      -- Stores "501, 503" — NOT atomic
    InstructorName  VARCHAR(200)      -- Stores "Dr. Alan, Dr. John" — NOT atomic
);

INSERT INTO Student_Raw VALUES
(101, 'Rahul Sharma', '1, 2',  'OS, DBMS',   10, 'Comp. Sci', '501',      'Dr. Alan'),
(102, 'Priya Patel',  '3',     'Networks',    10, 'Comp. Sci', '502',      'Dr. Ada'),
(103, 'Amit Kumar',   '1, 4',  'OS, AI',      10, 'Comp. Sci', '501, 503', 'Dr. Alan, Dr. John');

-- View UNF table
SELECT * FROM Student_Raw;

/*
Pitfalls in UNF:
  - Data Redundancy : DeptName "Comp. Sci" repeats for every student
  - Insertion Anomaly: Cannot add a new course without a student enrolled
  - Update Anomaly  : Changing DeptName requires updating every row
  - Deletion Anomaly: Deleting student 102 removes all info about "Networks" course
*/


-- ============================================================
-- STEP 1: FIRST NORMAL FORM (1NF)
-- Rule: All values must be atomic. No repeating groups.
-- Fix : Expand multi-valued cells into separate rows.
-- Primary Key: (StudentID, CourseID)
-- ============================================================

CREATE TABLE IF NOT EXISTS Student_1NF (
    StudentID       INT,
    StudentName     VARCHAR(100),
    CourseID        INT,              -- Now atomic: one value per cell
    CourseName      VARCHAR(100),     -- Now atomic
    DeptID          INT,
    DeptName        VARCHAR(100),
    InstructorID    INT,              -- Now atomic
    InstructorName  VARCHAR(100),     -- Now atomic
    PRIMARY KEY (StudentID, CourseID)
);

INSERT INTO Student_1NF VALUES
(101, 'Rahul Sharma', 1, 'OS',       10, 'Comp. Sci', 501, 'Dr. Alan'),
(101, 'Rahul Sharma', 2, 'DBMS',     10, 'Comp. Sci', 501, 'Dr. Alan'),
(102, 'Priya Patel',  3, 'Networks', 10, 'Comp. Sci', 502, 'Dr. Ada'),
(103, 'Amit Kumar',   1, 'OS',       10, 'Comp. Sci', 501, 'Dr. Alan'),
(103, 'Amit Kumar',   4, 'AI',       10, 'Comp. Sci', 503, 'Dr. John');

-- View 1NF table
SELECT * FROM Student_1NF;

/*
1NF Achieved:
  ✅ No repeating groups
  ✅ All cell values are atomic (single value per cell)
  ✅ Primary Key = (StudentID, CourseID)

Remaining Problem (Partial Dependencies):
  StudentID  -> StudentName        (depends only on StudentID, not full key)
  CourseID   -> CourseName, DeptID, DeptName, InstructorID, InstructorName
                                   (depends only on CourseID, not full key)
*/


-- ============================================================
-- STEP 2: SECOND NORMAL FORM (2NF)
-- Rule: Must be in 1NF + No partial dependencies.
-- Fix : Decompose into 3 tables — Student, Course, Enrollment.
-- ============================================================

-- Table 1: Student (depends only on StudentID)
CREATE TABLE IF NOT EXISTS Student_2NF (
    StudentID   INT PRIMARY KEY,
    StudentName VARCHAR(100)
);

INSERT INTO Student_2NF VALUES
(101, 'Rahul Sharma'),
(102, 'Priya Patel'),
(103, 'Amit Kumar');

-- Table 2: Course (depends only on CourseID)
CREATE TABLE IF NOT EXISTS Course_2NF (
    CourseID        INT PRIMARY KEY,
    CourseName      VARCHAR(100),
    DeptID          INT,
    DeptName        VARCHAR(100),
    InstructorID    INT,
    InstructorName  VARCHAR(100)
);

INSERT INTO Course_2NF VALUES
(1, 'OS',       10, 'Comp. Sci', 501, 'Dr. Alan'),
(2, 'DBMS',     10, 'Comp. Sci', 501, 'Dr. Alan'),
(3, 'Networks', 10, 'Comp. Sci', 502, 'Dr. Ada'),
(4, 'AI',       10, 'Comp. Sci', 503, 'Dr. John');

-- Table 3: Enrollment (depends on full composite key)
CREATE TABLE IF NOT EXISTS Enrollment_2NF (
    StudentID INT,
    CourseID  INT,
    PRIMARY KEY (StudentID, CourseID)
);

INSERT INTO Enrollment_2NF VALUES
(101, 1),
(101, 2),
(102, 3),
(103, 1),
(103, 4);

-- Verify 2NF tables
SELECT * FROM Student_2NF;
SELECT * FROM Course_2NF;
SELECT * FROM Enrollment_2NF;

/*
2NF Achieved:
  ✅ No partial dependencies
  ✅ StudentName depends ONLY on StudentID
  ✅ CourseName, DeptName etc. depend ONLY on CourseID
  ✅ Enrollment table has no extra non-key attributes

Remaining Problem (Transitive Dependencies in Course_2NF):
  CourseID -> DeptID    -> DeptName
  CourseID -> InstructorID -> InstructorName
*/


-- ============================================================
-- STEP 3: THIRD NORMAL FORM (3NF)
-- Rule: Must be in 2NF + No transitive dependencies.
-- Fix : Extract Department and Instructor into separate tables.
-- ============================================================

-- Table 1: Department (removes DeptID -> DeptName transitive dep)
CREATE TABLE IF NOT EXISTS Department (
    DeptID   INT PRIMARY KEY,
    DeptName VARCHAR(100)
);

INSERT INTO Department VALUES
(10, 'Comp. Sci');

-- Table 2: Instructor (removes InstructorID -> InstructorName transitive dep)
CREATE TABLE IF NOT EXISTS Instructor (
    InstructorID   INT PRIMARY KEY,
    InstructorName VARCHAR(100),
    DeptID         INT,
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

INSERT INTO Instructor VALUES
(501, 'Dr. Alan', 10),
(502, 'Dr. Ada',  10),
(503, 'Dr. John', 10);

-- Table 3: Course_3NF (only keeps FKs, no transitive attributes)
CREATE TABLE IF NOT EXISTS Course_3NF (
    CourseID     INT PRIMARY KEY,
    CourseName   VARCHAR(100),
    DeptID       INT,
    InstructorID INT,
    FOREIGN KEY (DeptID)       REFERENCES Department(DeptID),
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID)
);

INSERT INTO Course_3NF VALUES
(1, 'OS',       10, 501),
(2, 'DBMS',     10, 501),
(3, 'Networks', 10, 502),
(4, 'AI',       10, 503);

-- Table 4: Student (unchanged from 2NF)
CREATE TABLE IF NOT EXISTS Student_3NF (
    StudentID   INT PRIMARY KEY,
    StudentName VARCHAR(100)
);

INSERT INTO Student_3NF VALUES
(101, 'Rahul Sharma'),
(102, 'Priya Patel'),
(103, 'Amit Kumar');

-- Table 5: Enrollment (unchanged from 2NF)
CREATE TABLE IF NOT EXISTS Enrollment_3NF (
    StudentID INT,
    CourseID  INT,
    PRIMARY KEY (StudentID, CourseID),
    FOREIGN KEY (StudentID) REFERENCES Student_3NF(StudentID),
    FOREIGN KEY (CourseID)  REFERENCES Course_3NF(CourseID)
);

INSERT INTO Enrollment_3NF VALUES
(101, 1),
(101, 2),
(102, 3),
(103, 1),
(103, 4);

-- Verify 3NF tables
SELECT * FROM Department;
SELECT * FROM Instructor;
SELECT * FROM Course_3NF;
SELECT * FROM Student_3NF;
SELECT * FROM Enrollment_3NF;

-- Sample JOIN Query to verify relationships are intact
SELECT
    s.StudentName,
    c.CourseName,
    d.DeptName,
    i.InstructorName
FROM Enrollment_3NF e
JOIN Student_3NF s ON e.StudentID = s.StudentID
JOIN Course_3NF  c ON e.CourseID  = c.CourseID
JOIN Department  d ON c.DeptID    = d.DeptID
JOIN Instructor  i ON c.InstructorID = i.InstructorID;

/*
3NF Achieved:
  ✅ No transitive dependencies
  ✅ DeptName is stored ONCE in Department table
  ✅ InstructorName stored ONCE in Instructor table
  ✅ All non-key attributes depend ONLY on the primary key of their table

Remaining Problem (BCNF Violation):
  In a Student_Advisor scenario, AdvisorID -> DeptID
  but AdvisorID is not a candidate key of that table.
*/


-- ============================================================
-- STEP 4: BOYCE-CODD NORMAL FORM (BCNF)
-- Rule: Must be in 3NF + Every determinant must be a candidate key.
-- Scenario: Students have Advisors. Each Advisor belongs to one Dept.
-- Problem: AdvisorID -> DeptID, but AdvisorID is not a key of Student_Advisor.
-- Fix : Separate into Advises + Advisor tables.
-- ============================================================

-- BEFORE (violates BCNF): AdvisorID determines DeptID, but is not a key
CREATE TABLE IF NOT EXISTS Student_Advisor_Before (
    StudentID INT,
    DeptID    INT,
    AdvisorID VARCHAR(10),
    PRIMARY KEY (StudentID, DeptID)
    -- Problem: AdvisorID -> DeptID, but AdvisorID is NOT a superkey here
);

INSERT INTO Student_Advisor_Before VALUES
(101, 10, 'A1'),
(102, 10, 'A1');

SELECT * FROM Student_Advisor_Before;

-- AFTER (BCNF): Decompose into two tables
-- Table 1: Advises — stores which student is advised by which advisor
CREATE TABLE IF NOT EXISTS Advises (
    StudentID INT,
    AdvisorID VARCHAR(10),
    PRIMARY KEY (StudentID, AdvisorID)
);

INSERT INTO Advises VALUES
(101, 'A1'),
(102, 'A1');

-- Table 2: Advisor — stores which advisor belongs to which department
CREATE TABLE IF NOT EXISTS Advisor (
    AdvisorID VARCHAR(10) PRIMARY KEY,  -- AdvisorID IS now the candidate key
    DeptID    INT,
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

INSERT INTO Advisor VALUES
('A1', 10);

-- Verify BCNF tables
SELECT * FROM Advises;
SELECT * FROM Advisor;

/*
BCNF Achieved:
  ✅ In Advises  : Every determinant {StudentID, AdvisorID} is a candidate key
  ✅ In Advisor  : Every determinant {AdvisorID} is a candidate key
  ✅ No non-superkey determinants remain

Remaining Problem (4NF Violation):
  Student has multiple Phone Numbers AND multiple Hobbies.
  These are independent facts stored in one table — causes redundant rows.
*/


-- ============================================================
-- STEP 5: FOURTH NORMAL FORM (4NF)
-- Rule: Must be in BCNF + No non-trivial multivalued dependencies.
-- Scenario: Student has multiple phones AND multiple hobbies (independent).
-- Problem: StudentID ->> Phone AND StudentID ->> Hobby (independent MVDs).
-- Fix : Separate into Student_Phone and Student_Hobby tables.
-- ============================================================

-- BEFORE (violates 4NF): All phone-hobby combinations are stored
CREATE TABLE IF NOT EXISTS Student_Details_Before (
    StudentID INT,
    Phone     VARCHAR(15),
    Hobby     VARCHAR(50),
    PRIMARY KEY (StudentID, Phone, Hobby)
    -- Problem: Phone and Hobby are independent — creates unnecessary combos
);

INSERT INTO Student_Details_Before VALUES
(101, '9876543210', 'Reading'),
(101, '9876543210', 'Coding'),
(101, '1234567890', 'Reading'),
(101, '1234567890', 'Coding');  -- 2 phones × 2 hobbies = 4 rows (redundant)

SELECT * FROM Student_Details_Before;

-- AFTER (4NF): Separate the two independent multivalued facts
-- Table 1: Student_Phone
CREATE TABLE IF NOT EXISTS Student_Phone (
    StudentID INT,
    Phone     VARCHAR(15),
    PRIMARY KEY (StudentID, Phone)
);

INSERT INTO Student_Phone VALUES
(101, '9876543210'),
(101, '1234567890');

-- Table 2: Student_Hobby
CREATE TABLE IF NOT EXISTS Student_Hobby (
    StudentID INT,
    Hobby     VARCHAR(50),
    PRIMARY KEY (StudentID, Hobby)
);

INSERT INTO Student_Hobby VALUES
(101, 'Reading'),
(101, 'Coding');

-- Verify 4NF tables
SELECT * FROM Student_Phone;
SELECT * FROM Student_Hobby;

/*
4NF Achieved:
  ✅ No multivalued dependencies — Phone and Hobby are separated
  ✅ Adding a new phone: insert 1 row in Student_Phone (not 2 extra rows)
  ✅ Adding a new hobby: insert 1 row in Student_Hobby (not 2 extra rows)

Remaining Problem (5NF Violation):
  The three-way Student-Course-Instructor relationship has a join dependency.
  Splitting into only two binary tables may produce spurious (false) tuples.
*/


-- ============================================================
-- STEP 6: FIFTH NORMAL FORM (5NF) — Project-Join Normal Form (PJNF)
-- Rule: Must be in 4NF + No join dependencies (no spurious tuples on join).
-- Scenario: Student takes a Course taught by a specific Instructor.
--           All three facts are independently constrained.
-- Problem: A two-table decomposition creates spurious tuples on re-join.
-- Fix : Decompose into three binary relation tables.
-- ============================================================

-- BEFORE (violates 5NF): Three-way relationship in one table
CREATE TABLE IF NOT EXISTS Student_Course_Instructor_Before (
    StudentID    INT,
    CourseID     INT,
    InstructorID INT,
    PRIMARY KEY (StudentID, CourseID, InstructorID)
);

INSERT INTO Student_Course_Instructor_Before VALUES
(101, 1, 501),
(101, 2, 501),
(102, 3, 502),
(103, 1, 501),
(103, 4, 503);

SELECT * FROM Student_Course_Instructor_Before;

-- AFTER (5NF): Decompose into three binary tables
-- Table 1: Student_Course (Enrollment — who takes which course)
CREATE TABLE IF NOT EXISTS SC_5NF (
    StudentID INT,
    CourseID  INT,
    PRIMARY KEY (StudentID, CourseID)
);

INSERT INTO SC_5NF VALUES
(101, 1),
(101, 2),
(102, 3),
(103, 1),
(103, 4);

-- Table 2: Course_Instructor (Teaches — who teaches which course)
CREATE TABLE IF NOT EXISTS CI_5NF (
    CourseID     INT,
    InstructorID INT,
    PRIMARY KEY (CourseID, InstructorID)
);

INSERT INTO CI_5NF VALUES
(1, 501),
(2, 501),
(3, 502),
(4, 503);

-- Table 3: Student_Instructor (Guides — which student is guided by which instructor)
CREATE TABLE IF NOT EXISTS SI_5NF (
    StudentID    INT,
    InstructorID INT,
    PRIMARY KEY (StudentID, InstructorID)
);

INSERT INTO SI_5NF VALUES
(101, 501),
(102, 502),
(103, 501),
(103, 503);

-- Verify 5NF tables
SELECT * FROM SC_5NF;
SELECT * FROM CI_5NF;
SELECT * FROM SI_5NF;

-- Lossless Join Verification:
-- Joining all three 5NF tables must reproduce the original table exactly
-- (no spurious / extra tuples)
SELECT
    sc.StudentID,
    sc.CourseID,
    ci.InstructorID
FROM SC_5NF sc
JOIN CI_5NF ci ON sc.CourseID     = ci.CourseID
JOIN SI_5NF si ON sc.StudentID    = si.StudentID
              AND ci.InstructorID = si.InstructorID
ORDER BY sc.StudentID, sc.CourseID;

/*
Expected Result (matches original table exactly — no spurious tuples):

  StudentID | CourseID | InstructorID
  ----------|----------|--------------
  101       | 1        | 501
  101       | 2        | 501
  102       | 3        | 502
  103       | 1        | 501
  103       | 4        | 503

5NF Achieved:
  ✅ No join dependencies — all three binary tables join back losslessly
  ✅ No spurious tuples generated on natural join
  ✅ Database is fully normalized to 5NF
*/


-- ============================================================
-- NORMALIZATION SUMMARY
-- ============================================================
/*
  Stage  | Table(s) Created             | Problem Solved
  -------|------------------------------|-------------------------------------
  UNF    | Student_Raw                  | Raw data — repeating groups, non-atomic
  1NF    | Student_1NF                  | Atomic values, one row per enrollment
  2NF    | Student_2NF, Course_2NF,     | Removed partial dependencies
         | Enrollment_2NF               |
  3NF    | Student_3NF, Course_3NF,     | Removed transitive dependencies
         | Instructor, Department,      |
         | Enrollment_3NF              |
  BCNF   | Advises, Advisor             | Every determinant is a superkey
  4NF    | Student_Phone, Student_Hobby | Removed multivalued dependencies
  5NF    | SC_5NF, CI_5NF, SI_5NF      | Removed join dependency (lossless join)
*/

-- ============================================================
-- END OF NORMALIZATION SQL
-- ============================================================
