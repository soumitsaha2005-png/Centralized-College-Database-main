# CHAPTER 6: FRONT-END AND BACK-END CODE OF CENTRALIZED COLLEGE DATABASE

## 6.1 Front–End Module Codes
The front-end of the Centralized College Database is built using HTML5, Vanilla CSS, and JavaScript, forming a modern, responsive, and unified multipage interface. It utilizes a shared dark-themed design system with glassmorphism elements, dynamic particle backgrounds, and real-time form validations.

Below are snippets of the critical front-end modules:

### 1. Shared Layout and Design System (`shared.css`)
This module handles the global typography, color variables, navigation bar, and the responsive glassmorphism card layouts used across all pages.
```css
:root {
  --bg:          #050818;
  --surface:     rgba(10, 20, 40, 0.75);
  --cyan:        #03e9f4;
  --text:        #e2e8f0;
}
/* Glassmorphism Card Layout */
.card {
  background: var(--surface);
  border: 1px solid rgba(3, 233, 244, 0.18);
  border-radius: 12px;
  backdrop-filter: blur(20px);
  padding: 2rem;
}
/* Navigation Bar */
.navbar {
  position: fixed;
  top: 0; left: 0; right: 0;
  height: 64px;
  display: flex;
  justify-content: space-between;
  background: rgba(5, 8, 24, 0.85);
  backdrop-filter: blur(18px);
}
```

### 2. Main Dashboard & Routing (`index.html`)
The landing page serves as the main entry point, featuring animated canvas particles and fetching real-time database statistics (total students, courses, instructors, departments) via an API call.
```javascript
// Fetching Live Statistics for Dashboard
fetch('/api/stats')
  .then(response => response.json())
  .then(data => {
    document.getElementById('stat-students').textContent = data.students;
    document.getElementById('stat-courses').textContent = data.courses;
    document.getElementById('stat-instructors').textContent = data.instructors;
    document.getElementById('stat-departments').textContent = data.departments;
  });
```

### 3. Asynchronous Data Submission (`addStudent.html`)
The front-end handles form submissions asynchronously using the Fetch API, preventing page reloads and displaying animated toast notifications upon success or failure.
```javascript
document.getElementById('studentForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const data = {
    student_id: document.getElementById('student_id').value,
    student_name: document.getElementById('student_name').value,
    age: document.getElementById('age').value,
    address: document.getElementById('address').value,
    year: document.getElementById('year').value,
    course_id: document.getElementById('course_id').value
  };
  
  // Sending data to backend
  const res = await fetch('/api/students', { 
    method: 'POST', 
    headers: { 'Content-Type': 'application/json' }, 
    body: JSON.stringify(data) 
  });
  const json = await res.json();
  
  if (json.success) {
    showToast('Student added successfully!', 'success');
  } else {
    showToast(json.message, 'error');
  }
});
```

### 4. Interactive Data Visualization (`aboutCollege.html`)
This module integrates D3.js to dynamically render a hierarchical tree structure of the college departments and their respective courses.
```javascript
const svg = d3.select('#tree-container').append('svg')
  .attr('width', 900).attr('height', 480);
const tree = d3.tree().size([400, 680]);
const root = d3.hierarchy(treeData);
tree(root);

// Drawing links
svg.selectAll('.link').data(root.links()).enter().append('path')
  .attr('class', 'link')
  .attr('fill', 'none')
  .attr('stroke', 'rgba(3,233,244,0.3)')
  .attr('d', d3.linkHorizontal().x(d => d.y).y(d => d.x));
```

## 6.2 Database Connectivity
The backend is powered by Node.js and Express.js, utilizing the `mysql2` package to establish a robust and secure connection to the local MySQL 8.0 server. 

### Database Connection Setup (`server.js`)
The connection is established upon server startup. It maintains a persistent connection to the `CCD` database to handle all incoming queries.
```javascript
const express = require('express');
const mysql = require('mysql2');
const app = express();

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// ─── Database Connectivity ──────────────────────────────────
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'Ball@123',
  database: 'CCD' // Centralized College Database
});

db.connect((err) => {
  if (err) { 
    console.error('Database connection error:', err.stack); 
    return; 
  }
  console.log('✅ Connected to MySQL Database with Connection ID: ' + db.threadId);
});
```

### API Implementation using the Connection
The unified server defines RESTful API endpoints that interact directly with the database using SQL queries. For example, the dynamic search functionality joins multiple tables to retrieve comprehensive student records.
```javascript
// ─── API: Search Students ───────────────────────────────────
app.get('/api/search', (req, res) => {
  const { student_name, department_id } = req.query;
  
  let sql = `SELECT s.student_id, s.student_name, s.year, s.age, 
             c.course_name, i.instructor_name, d.department_name
             FROM student s
             JOIN courses c ON s.course_id = c.course_id
             JOIN instructor i ON c.instructor_id = i.instructor_id
             JOIN department d ON c.department_id = d.department_id
             WHERE 1=1`;
             
  const params = [];
  if (student_name) { 
      sql += ' AND s.student_name LIKE ?'; 
      params.push(`%${student_name}%`); 
  }
  
  db.query(sql, params, (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result);
  });
});
```

---
<br><br>

# CHAPTER 7: RESULTS AND DISCUSSIONS

## 7.1 Screenshots of front-end
*(Note for User: Please insert the screenshots you take of your running application under these headings)*

**Figure 7.1.1: Main Dashboard (Home Page)**
*Description*: Shows the landing page with dynamic particle background, unified navigation bar, and live database statistics cards (Students, Courses, Instructors, Departments).

**Figure 7.1.2: Add Student Form**
*Description*: Displays the responsive glassmorphism form where an admin can input a student's ID, Name, Age, Year, Address, and select an enrolled Course from the dropdown menu.

**Figure 7.1.3: Search Database Functionality**
*Description*: Shows the split-layout search page with the filtering sidebar on the left and a tabulated result set on the right, successfully joining data across departments, instructors, and courses.

**Figure 7.1.4: Instructor Management Panel**
*Description*: Demonstrates the page where new instructors are added, and existing ones are listed in a table with department-colored badges and dynamic "Delete" action buttons.

**Figure 7.1.5: College Structure Visualization**
*Description*: Shows the "About" page containing the interactive D3.js hierarchical tree diagram that visually maps the relationship between the College, Departments, and Courses.

## 7.2 Screenshots of Database
*(Note for User: You can take these screenshots by opening MySQL Command Line or MySQL Workbench, running the queries below, and taking a screenshot of the results).*

**Figure 7.2.1: The CCD Database Tables**
*Query to run*: `SHOW TABLES;`
*Description*: Displays the structure of the database containing the `courses`, `department`, `instructor`, and `student` tables.

**Figure 7.2.2: Department and Instructor Records**
*Query to run*: `SELECT * FROM department;` and `SELECT * FROM instructor;`
*Description*: Shows the pre-seeded records of the 5 main college departments and their associated instructors, demonstrating primary and foreign key relations.

**Figure 7.2.3: Student Enrollment Records**
*Query to run*: `SELECT * FROM student;`
*Description*: Shows the successful insertion of student data into the relational table, storing their demographic information and the `course_id` they are enrolled in.

**Figure 7.2.4: Advanced Query Result (Joined Data)**
*Query to run*: 
```sql
SELECT s.student_name, c.course_name, d.department_name 
FROM student s 
JOIN courses c ON s.course_id = c.course_id 
JOIN department d ON c.department_id = d.department_id;
```
*Description*: Proves the relational integrity of the database by successfully joining the student table with the courses and department tables to provide a human-readable output.
