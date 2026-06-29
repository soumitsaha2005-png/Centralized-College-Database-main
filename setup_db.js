const mysql = require('mysql2');

const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'Ball@123',
  multipleStatements: true
});

db.connect((err) => {
  if (err) { console.error('❌ Connection failed:', err.message); process.exit(1); }
  console.log('✅ Connected to MySQL');

  const setupSQL = `
    CREATE DATABASE IF NOT EXISTS CCD;
    USE CCD;

    CREATE TABLE IF NOT EXISTS department (
      department_id   INT PRIMARY KEY,
      department_name VARCHAR(255)
    );

    CREATE TABLE IF NOT EXISTS instructor (
      instructor_id   INT PRIMARY KEY,
      instructor_name VARCHAR(255),
      department_id   INT,
      FOREIGN KEY (department_id) REFERENCES department(department_id)
    );

    CREATE TABLE IF NOT EXISTS courses (
      course_id       INT PRIMARY KEY,
      course_name     VARCHAR(255),
      department_id   INT,
      instructor_id   INT,
      course_duration VARCHAR(255),
      FOREIGN KEY (department_id) REFERENCES department(department_id),
      FOREIGN KEY (instructor_id) REFERENCES instructor(instructor_id)
    );

    CREATE TABLE IF NOT EXISTS student (
      student_id   INT,
      course_id    INT,
      PRIMARY KEY  (student_id, course_id),
      student_name VARCHAR(255),
      year         INT,
      age          INT,
      address      VARCHAR(255),
      FOREIGN KEY  (course_id) REFERENCES courses(course_id)
    );

    INSERT IGNORE INTO department (department_id, department_name) VALUES
      (1,'Computer Science'),(2,'Electrical Engineering'),
      (3,'Math'),(4,'English'),(5,'History');

    INSERT IGNORE INTO instructor (instructor_id, instructor_name, department_id) VALUES
      (1,'Prof. Alan Turing',1),(2,'Prof. Nikola Tesla',2),
      (3,'Prof. Carl Gauss',3),(4,'Prof. Virginia Woolf',4),(5,'Prof. Howard Zinn',5);

    INSERT IGNORE INTO courses (course_id,course_name,department_id,instructor_id,course_duration) VALUES
      (1,'Introduction to Computer Science',1,1,'6 months'),
      (2,'Digital Logic Design',1,1,'6 months'),
      (3,'Calculus I',3,3,'6 months'),
      (4,'Introduction to Literature',4,4,'6 months'),
      (5,'US History I',5,5,'6 months'),
      (6,'Data Structures and Algorithms',1,1,'6 months'),
      (7,'Power Systems',2,2,'6 months'),
      (8,'Linear Algebra',3,3,'6 months'),
      (9,'Shakespearean Literature',4,4,'6 months'),
      (10,'World History I',5,5,'6 months'),
      (11,'Computer Networks',1,1,'6 months'),
      (12,'Electronics I',2,2,'6 months'),
      (13,'Calculus II',3,3,'6 months'),
      (14,'Modern American Literature',4,4,'6 months'),
      (15,'US History II',5,5,'6 months'),
      (16,'Database Systems',1,1,'6 months'),
      (17,'Power Electronics',2,2,'6 months'),
      (18,'Multivariable Calculus',3,3,'6 months'),
      (19,'British Literature',4,4,'6 months'),
      (20,'World History II',5,5,'6 months');

    INSERT IGNORE INTO student (student_id,course_id,student_name,year,age,address) VALUES
      (1,1,'Rahul Sharma',2022,20,'12 MG Road, Delhi'),
      (2,3,'Priya Patel',2023,21,'45 Lake Ave, Mumbai'),
      (3,7,'Ankit Verma',2022,19,'7 Park St, Pune'),
      (4,4,'Sneha Roy',2023,22,'8 Civil Lines, Jaipur'),
      (5,6,'Vikram Singh',2024,21,'14 Rajpur Road, Dehradun');
  `;

  db.query(setupSQL, (err) => {
    if (err) { console.error('❌ Setup error:', err.message); db.end(); process.exit(1); }
    console.log('✅ Database CCD is ready — all tables created and seeded.');
    db.end();
  });
});
