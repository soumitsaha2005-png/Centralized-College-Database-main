const express = require('express');
const mysql = require('mysql2');
const path = require('path');
const app = express();

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(__dirname));

// ─── Database ────────────────────────────────────────────────────────────────
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'Ball@123',
  database: 'CCD'
});

db.connect((err) => {
  if (err) { console.error('DB connection error:', err.stack); return; }
  console.log('✅ Connected to MySQL (id ' + db.threadId + ')');
});

// ─── Page Routes ─────────────────────────────────────────────────────────────
app.get('/',               (req, res) => res.sendFile(path.join(__dirname, 'index.html')));
app.get('/add-student',    (req, res) => res.sendFile(path.join(__dirname, 'addStudent.html')));
app.get('/enroll',         (req, res) => res.sendFile(path.join(__dirname, 'enroll.html')));
app.get('/search',         (req, res) => res.sendFile(path.join(__dirname, 'searchFilter.html')));
app.get('/instructors',    (req, res) => res.sendFile(path.join(__dirname, 'instructor.html')));
app.get('/about',          (req, res) => res.sendFile(path.join(__dirname, 'aboutCollege.html')));

// ─── API: Add Student ─────────────────────────────────────────────────────────
app.post('/api/students', (req, res) => {
  const { student_id, course_id, student_name, year, age, address } = req.body;
  const sql = 'INSERT INTO student (student_id, course_id, student_name, year, age, address) VALUES (?, ?, ?, ?, ?, ?)';
  db.query(sql, [student_id, course_id, student_name, year, age, address], (err, result) => {
    if (err) {
      console.error('Insert error:', err);
      return res.status(500).json({ success: false, message: err.sqlMessage || 'Database error' });
    }
    res.json({ success: true, message: 'Student added successfully!' });
  });
});

// ─── API: Search Students ─────────────────────────────────────────────────────
app.get('/api/search', (req, res) => {
  const { department_id, instructor_id, course_id, course_name, student_id, student_name, year } = req.query;
  let sql = `SELECT s.student_id, s.student_name, s.year, s.age, s.address,
    c.course_id, c.course_name, c.course_duration,
    i.instructor_id, i.instructor_name,
    d.department_id, d.department_name
    FROM student s
    LEFT JOIN courses c ON s.course_id = c.course_id
    LEFT JOIN instructor i ON c.instructor_id = i.instructor_id
    LEFT JOIN department d ON c.department_id = d.department_id
    WHERE 1=1`;
  const params = [];
  if (department_id) { sql += ' AND d.department_id = ?'; params.push(department_id); }
  if (instructor_id) { sql += ' AND i.instructor_id = ?'; params.push(instructor_id); }
  if (course_id)     { sql += ' AND c.course_id = ?';     params.push(course_id); }
  if (course_name)   { sql += ' AND c.course_name LIKE ?'; params.push(`%${course_name}%`); }
  if (student_id)    { sql += ' AND s.student_id = ?';    params.push(student_id); }
  if (student_name)  { sql += ' AND s.student_name LIKE ?'; params.push(`%${student_name}%`); }
  if (year)          { sql += ' AND s.year = ?';          params.push(year); }
  db.query(sql, params, (err, result) => {
    if (err) { console.error('Search error:', err); return res.status(500).json({ error: err.message }); }
    res.json(result);
  });
});

// ─── API: Get all Instructors ─────────────────────────────────────────────────
app.get('/api/instructors', (req, res) => {
  db.query('SELECT i.*, d.department_name FROM instructor i JOIN department d ON i.department_id = d.department_id', (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result);
  });
});

// ─── API: Add Instructor ──────────────────────────────────────────────────────
app.post('/api/instructors', (req, res) => {
  const { instructor_id, instructor_name, department_id } = req.body;
  const sql = 'INSERT INTO instructor (instructor_id, instructor_name, department_id) VALUES (?, ?, ?)';
  db.query(sql, [instructor_id, instructor_name, department_id], (err) => {
    if (err) return res.status(500).json({ success: false, message: err.sqlMessage || 'Database error' });
    res.json({ success: true, message: 'Instructor added successfully!' });
  });
});

// ─── API: Delete Instructor ───────────────────────────────────────────────────
app.delete('/api/instructors/:id', (req, res) => {
  const id = req.params.id;
  db.query('SELECT COUNT(*) AS cnt FROM instructor', (err, result) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    if (result[0].cnt < 2) return res.status(400).json({ success: false, message: 'Cannot delete — at least 1 instructor must remain.' });
    db.query('DELETE FROM instructor WHERE instructor_id = ?', [id], (err2) => {
      if (err2) return res.status(500).json({ success: false, message: err2.sqlMessage });
      res.json({ success: true, message: 'Instructor deleted.' });
    });
  });
});

// ─── API: Get Departments ─────────────────────────────────────────────────────
app.get('/api/departments', (req, res) => {
  db.query('SELECT * FROM department', (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result);
  });
});

// ─── API: Courses with seats (for enroll page) ──────────────────────────────
app.get('/api/courses-with-seats', (req, res) => {
  const sql = `SELECT c.course_id, c.course_name, c.course_duration,
    COALESCE(c.seats_available, 30) AS seats_available,
    d.department_name, i.instructor_name
    FROM courses c
    JOIN department d ON c.department_id = d.department_id
    JOIN instructor i ON c.instructor_id = i.instructor_id
    ORDER BY d.department_name, c.course_name`;
  db.query(sql, (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// ─── API: Student Enrollments lookup ─────────────────────────────────────────
app.get('/api/student-enrollments/:sid', (req, res) => {
  const sid = req.params.sid;
  // First get student name
  db.query('SELECT student_name FROM student WHERE student_id = ?', [sid], (err, sRows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!sRows.length) return res.status(404).json({ error: `Student ID ${sid} not found in database.` });
    const student_name = sRows[0].student_name;
    // Get their enrollments via JOIN
    const sql = `SELECT s.student_id, s.student_name, c.course_id, c.course_name,
      c.course_duration, d.department_name, i.instructor_name
      FROM student s
      JOIN courses c ON s.course_id = c.course_id
      JOIN department d ON c.department_id = d.department_id
      JOIN instructor i ON c.instructor_id = i.instructor_id
      WHERE s.student_id = ?`;
    db.query(sql, [sid], (err2, rows) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({ student_name, enrollments: rows });
    });
  });
});

// ─── API: Enroll Student in Course (TRANSACTION with SAVEPOINT) ──────────────
app.post('/api/enroll', (req, res) => {
  const { student_id, course_id } = req.body;
  const txLog = [];
  const log = (text, type='info') => txLog.push({ text, type });

  // Check student exists
  db.query('SELECT student_id FROM student WHERE student_id = ?', [student_id], (err, sRows) => {
    if (err) return res.status(500).json({ success: false, message: err.message, txLog });
    if (!sRows.length) return res.status(400).json({ success: false, message: `Student ID ${student_id} does not exist.`, txLog });

    log('START TRANSACTION;', 'ok');
    db.beginTransaction(err => {
      if (err) return res.status(500).json({ success: false, message: err.message, txLog });

      // SAVEPOINT before_enrollment
      log('SAVEPOINT before_enrollment;', 'info');
      db.query('SAVEPOINT before_enrollment', err => {
        if (err) { log('ROLLBACK; -- savepoint error', 'err'); return db.rollback(() => res.status(500).json({ success: false, message: err.message, txLog })); }

        // Step 1: Check seats
        log(`SELECT seats_available FROM courses WHERE course_id = ${course_id};`, 'info');
        db.query('SELECT seats_available, course_name FROM courses WHERE course_id = ?', [course_id], (err, cRows) => {
          if (err) { log('ROLLBACK TO before_enrollment; -- seat check error', 'err'); return db.rollback(() => res.status(500).json({ success: false, message: err.message, txLog })); }
          if (!cRows.length) { log('ROLLBACK; -- course not found', 'err'); return db.rollback(() => res.status(400).json({ success: false, message: 'Course not found.', txLog })); }

          const seats = cRows[0].seats_available ?? 30;
          log(`-- Seats available: ${seats}`, seats > 0 ? 'ok' : 'err');

          if (seats <= 0) {
            log('-- ❌ Course is FULL → ROLLBACK TO before_enrollment;', 'err');
            return db.rollback(() => res.status(400).json({ success: false, message: `Course "${cRows[0].course_name}" is full. Transaction rolled back.`, txLog }));
          }

          // Step 2: Reduce seats
          log(`UPDATE courses SET seats_available = seats_available - 1 WHERE course_id = ${course_id};`, 'warn');
          db.query('UPDATE courses SET seats_available = seats_available - 1 WHERE course_id = ?', [course_id], err => {
            if (err) { log('ROLLBACK TO before_enrollment; -- seat update failed', 'err'); return db.rollback(() => res.status(500).json({ success: false, message: err.message, txLog })); }
            log('-- ✅ seats_available decremented', 'ok');

            // Step 3: Insert enrollment
            log(`INSERT INTO enrollment (student_id, course_id) VALUES (${student_id}, ${course_id});`, 'warn');
            db.query('INSERT INTO enrollment (student_id, course_id) VALUES (?, ?)', [student_id, course_id], err => {
              if (err) {
                log('ROLLBACK TO before_enrollment; -- enrollment insert failed: ' + (err.sqlMessage || err.message), 'err');
                return db.rollback(() => res.status(400).json({ success: false, message: err.sqlMessage || 'Enrollment failed (already enrolled or constraint violation).', txLog }));
              }
              log('-- ✅ Enrollment record inserted', 'ok');
              log('COMMIT;', 'ok');
              db.commit(err => {
                if (err) { log('ROLLBACK; -- commit failed', 'err'); return db.rollback(() => res.status(500).json({ success: false, message: err.message, txLog })); }
                res.json({ success: true, message: 'Enrolled successfully!', txLog });
              });
            });
          });
        });
      });
    });
  });
});

// ─── API: Drop Enrollment (TRANSACTION) ──────────────────────────────────────
app.delete('/api/drop-enrollment', (req, res) => {
  const { student_id, course_id } = req.body;
  db.beginTransaction(err => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    db.query('DELETE FROM enrollment WHERE student_id = ? AND course_id = ?', [student_id, course_id], (err, result) => {
      if (err)               { return db.rollback(() => res.status(500).json({ success: false, message: err.message })); }
      if (!result.affectedRows) { return db.rollback(() => res.status(404).json({ success: false, message: 'Enrollment not found.' })); }
      db.query('UPDATE courses SET seats_available = seats_available + 1 WHERE course_id = ?', [course_id], err => {
        if (err) { return db.rollback(() => res.status(500).json({ success: false, message: err.message })); }
        db.commit(err => {
          if (err) return db.rollback(() => res.status(500).json({ success: false, message: err.message }));
          res.json({ success: true, message: 'Enrollment dropped successfully.' });
        });
      });
    });
  });
});

// ─── API: Stats ───────────────────────────────────────────────────────────────
app.get('/api/stats', (req, res) => {
  const queries = {
    students:    'SELECT COUNT(*) AS cnt FROM student',
    courses:     'SELECT COUNT(*) AS cnt FROM courses',
    instructors: 'SELECT COUNT(*) AS cnt FROM instructor',
    departments: 'SELECT COUNT(*) AS cnt FROM department'
  };
  const results = {};
  let done = 0;
  for (const [key, sql] of Object.entries(queries)) {
    db.query(sql, (err, rows) => {
      results[key] = err ? 0 : rows[0].cnt;
      if (++done === 4) res.json(results);
    });
  }
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(3000, () => console.log('🚀 Server running at http://localhost:3000'));
