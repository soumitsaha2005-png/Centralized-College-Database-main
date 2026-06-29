USE CCD;

-- Departments
INSERT IGNORE INTO department (department_id, department_name) VALUES
(1, 'Computer Science'),
(2, 'Electrical Engineering'),
(3, 'Math'),
(4, 'English'),
(5, 'History');

-- Instructors
INSERT IGNORE INTO instructor (instructor_id, instructor_name, department_id) VALUES
(1, 'Prof. Alan Turing', 1),
(2, 'Prof. Nikola Tesla', 2),
(3, 'Prof. Carl Gauss', 3),
(4, 'Prof. Virginia Woolf', 4),
(5, 'Prof. Howard Zinn', 5);

-- Courses (matching the course_ids and names hard-coded in addStudent.html)
INSERT IGNORE INTO courses (course_id, course_name, department_id, instructor_id, course_duration) VALUES
(1,  'Introduction to Computer Science', 1, 1, '6 months'),
(2,  'Digital Logic Design',             1, 1, '6 months'),
(3,  'Calculus I',                       3, 3, '6 months'),
(4,  'Introduction to Literature',       4, 4, '6 months'),
(5,  'US History I',                     5, 5, '6 months'),
(6,  'Data Structures and Algorithms',   1, 1, '6 months'),
(7,  'Power Systems',                    2, 2, '6 months'),
(8,  'Linear Algebra',                   3, 3, '6 months'),
(9,  'Shakespearean Literature',         4, 4, '6 months'),
(10, 'World History I',                  5, 5, '6 months'),
(11, 'Computer Networks',                1, 1, '6 months'),
(12, 'Electronics I',                    2, 2, '6 months'),
(13, 'Calculus II',                      3, 3, '6 months'),
(14, 'Modern American Literature',       4, 4, '6 months'),
(15, 'US History II',                    5, 5, '6 months'),
(16, 'Database Systems',                 1, 1, '6 months'),
(17, 'Power Electronics',                2, 2, '6 months'),
(18, 'Multivariable Calculus',           3, 3, '6 months'),
(19, 'British Literature',               4, 4, '6 months'),
(20, 'World History II',                 5, 5, '6 months');
