-- ==============================================================================
-- ADVANCED SQL EXAMPLES FOR CENTRALIZED COLLEGE DATABASE
-- This file contains examples of Constraints, Sets, Joins, Views, Triggers, 
-- and Cursors based on your actual CCD schema.
-- ==============================================================================

USE CCD;

-- ==============================================================================
-- 1. CONSTRAINTS
-- Examples of adding constraints to existing tables (or defining them).
-- Note: Your DatabaseDesign.sql already uses PRIMARY KEY and FOREIGN KEY.
-- Below are examples of additional constraints (CHECK, UNIQUE, DEFAULT).
-- ==============================================================================

-- Example A: Ensure a student's age is realistic (CHECK constraint)
-- ALTER TABLE student ADD CONSTRAINT chk_student_age CHECK (age >= 16 AND age <= 100);

-- Example B: Ensure course names are unique within the college (UNIQUE constraint)
-- ALTER TABLE courses ADD CONSTRAINT chk_unique_course_name UNIQUE (course_name);

-- Example C: Set a default duration for courses if not specified (DEFAULT value)
-- ALTER TABLE courses ALTER course_duration SET DEFAULT '6 months';


-- ==============================================================================
-- 2. SET OPERATIONS (UNION, INTERSECT, EXCEPT)
-- Note: MySQL does not natively support INTERSECT or EXCEPT, but we can 
-- emulate them using JOINs or subqueries. It does support UNION.
-- ==============================================================================

-- Example: Get a single list of all names in the college (Instructors + Students)
-- Uses UNION to combine two different queries into one result set.
SELECT instructor_name AS Person_Name, 'Instructor' AS Role 
FROM instructor
UNION
SELECT student_name AS Person_Name, 'Student' AS Role 
FROM student;


-- ==============================================================================
-- 3. JOINS
-- Used to combine rows from two or more tables based on a related column.
-- ==============================================================================

-- Example: INNER JOIN (Get students and the name of the course they are enrolled in)
SELECT s.student_name, c.course_name 
FROM student s
INNER JOIN courses c ON s.course_id = c.course_id;

-- Example: LEFT JOIN (Get ALL departments, and courses if they have any)
-- This ensures departments with 0 courses still show up in the result.
SELECT d.department_name, c.course_name
FROM department d
LEFT JOIN courses c ON d.department_id = c.department_id;

-- Example: MULTIPLE JOINS (The queries used in your Node.js search API)
SELECT s.student_name, c.course_name, i.instructor_name, d.department_name
FROM student s
JOIN courses c ON s.course_id = c.course_id
JOIN instructor i ON c.instructor_id = i.instructor_id
JOIN department d ON c.department_id = d.department_id;


-- ==============================================================================
-- 4. VIEWS
-- Virtual tables based on the result of an SQL statement.
-- ==============================================================================

-- Example: Create a View that gives a clean overview of Student Enrollments
-- This hides the complex JOIN logic behind a simple view name.
CREATE OR REPLACE VIEW Student_Enrollment_Details AS
SELECT 
    s.student_id,
    s.student_name,
    c.course_name,
    d.department_name,
    s.year AS admission_year
FROM student s
JOIN courses c ON s.course_id = c.course_id
JOIN department d ON c.department_id = d.department_id;

-- To use the view later, you would just run:
-- SELECT * FROM Student_Enrollment_Details WHERE admission_year = 2023;


-- ==============================================================================
-- 5. TRIGGERS
-- A set of SQL statements automatically executed before/after an INSERT/UPDATE/DELETE.
-- ==============================================================================

-- Example: Prevent an instructor from being deleted if they are assigned to a course.
-- (Normally a Foreign Key handles this, but here is how a trigger would intercept it).

DELIMITER //

CREATE TRIGGER prevent_instructor_deletion
BEFORE DELETE ON instructor
FOR EACH ROW
BEGIN
    DECLARE course_count INT;
    
    -- Check how many courses this instructor teaches
    SELECT COUNT(*) INTO course_count FROM courses WHERE instructor_id = OLD.instructor_id;
    
    -- If they teach 1 or more courses, throw an error preventing deletion
    IF course_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete instructor: They are currently assigned to one or more courses.';
    END IF;
END //

DELIMITER ;


-- ==============================================================================
-- 6. CURSORS (Inside a Stored Procedure)
-- Cursors allow you to iterate through a result set row by row.
-- ==============================================================================

-- Example: A Stored Procedure that loops through all students and generates 
-- a custom formatted string report for each one.

DELIMITER //

CREATE PROCEDURE Generate_Student_Report()
BEGIN
    -- Variables to hold data from the cursor
    DECLARE v_student_name VARCHAR(255);
    DECLARE v_course_name VARCHAR(255);
    DECLARE v_done INT DEFAULT FALSE;
    
    -- 1. Declare the cursor
    DECLARE student_cursor CURSOR FOR 
        SELECT s.student_name, c.course_name 
        FROM student s
        JOIN courses c ON s.course_id = c.course_id;
        
    -- 2. Declare a handler to know when we reach the end of the rows
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    -- 3. Open the cursor
    OPEN student_cursor;
    
    -- 4. Loop through the rows
    read_loop: LOOP
        FETCH student_cursor INTO v_student_name, v_course_name;
        
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        -- Inside this loop, you process each row individually.
        -- For example, just selecting the combined string as output:
        SELECT CONCAT('Report: Student ', v_student_name, ' is enrolled in ', v_course_name) AS Output;
        
    END LOOP;
    
    -- 5. Close the cursor
    CLOSE student_cursor;
END //

DELIMITER ;

-- To run the procedure with the cursor:
-- CALL Generate_Student_Report();
