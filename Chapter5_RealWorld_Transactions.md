## 5.3 Real-World Scenario: Student Enrolling in a Course

In a Student Management System, a student "buying" or enrolling in a course is a classic transaction scenario. This process involves multiple dependent steps, such as:
1. Checking and reducing the `available_seats` in the **Course** table.
2. Inserting a new record into the **Enrollment** table.

If the course is full, or if the insert fails, the system must **roll back** to ensure no seats are wrongly deducted.

**Tables Used for these Examples:**
- `Student(student_id, student_name, dept_id)`
- `Course(course_id, course_name, available_seats)`
- `Enrollment(en_id, student_id, course_id, date)`

---

### 5.3.1 Transaction 1: Successful Course Enrollment

**Question:** Student "Rohan" (ID: 101) wants to enroll in the course "DBMS" (Course ID: C1). There are available seats. Write a transaction to safely enroll the student.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Reduce available seats by 1
UPDATE Course 
SET available_seats = available_seats - 1 
WHERE course_id = 'C1';

-- Step 2: Insert into Enrollment
INSERT INTO Enrollment (en_id, student_id, course_id, date) 
VALUES (1, 101, 'C1', CURDATE());

-- Step 3: Both steps successful, make changes permanent
COMMIT;
```

**Output Explanation:**
The transaction successfully deducts 1 seat from the `Course` table for 'C1' and adds a new enrollment record for Student 101. The `COMMIT` command permanently saves these changes to the database.

---

### 5.3.2 Transaction 2: Failure Case (Course Full → Rollback)

**Question:** Student "Neha" (ID: 102) tries to enroll in "OS" (Course ID: C2). However, after trying to update the seats, the system detects an error (e.g., negative seats or system failure). Handle this failure using a rollback.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Attempt to reduce seats constraint
UPDATE Course 
SET available_seats = available_seats - 1 
WHERE course_id = 'C2';

-- Step 2: Suddenly an error occurs (e.g., course is actually full)
-- The application detects a problem and aborts the insert

-- Step 3: Undo the seat reduction
ROLLBACK;
```

**Output Explanation:**
When a failure occurs, the `ROLLBACK` command is triggered. The database returns to its exact state before the `START TRANSACTION`. The seat count for 'C2' is restored to its original value, ensuring data consistency.

---

### 5.3.3 Transaction 3: Partial Update with SAVEPOINT

**Question:** Student "Amit" (ID: 103) wants to enroll in "Networks" (C3). First, update the course seats successfully. Create a savepoint. Then, attempt to insert the enrollment. The admin makes a typo during insertion. Rollback only the typo using the savepoint and insert the correct data.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Update the course seats
UPDATE Course 
SET available_seats = available_seats - 1 
WHERE course_id = 'C3';

-- Step 2: Create a savepoint
SAVEPOINT seats_updated;

-- Step 3: Admin makes a typo and inserts the wrong student ID (999)
INSERT INTO Enrollment (en_id, student_id, course_id, date) 
VALUES (3, 999, 'C3', CURDATE()); 
-- Error occurs due to foreign key failure (Student 999 does not exist)

-- Step 4: Mistake realized, rollback ONLY to the savepoint (Undo the bad insert)
ROLLBACK TO seats_updated;

-- Step 5: Insert with the correct student ID
INSERT INTO Enrollment (en_id, student_id, course_id, date) 
VALUES (3, 103, 'C3', CURDATE());

-- Step 6: Commit all valid changes
COMMIT;
```

**Output Explanation:**
The `SAVEPOINT` acts as a safe checkpoint. When the first `INSERT` failed due to a typo, `ROLLBACK TO seats_updated` undid the bad insert without undoing the successful seat reduction. The transaction then finished successfully.

---

### 5.3.4 Transaction 4: Delete Enrollment with Rollback

**Question:** Student "Sara" (ID: 104) accidentally clicks "Drop Course" for "AI" (Course ID: C4). The backend deletes her enrollment. Before the transaction finishes, she cancels the action. Rollback the deletion.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Delete the enrollment record
DELETE FROM Enrollment 
WHERE student_id = 104 AND course_id = 'C4';

-- Step 2: User aborts the action before the seat count is updated

-- Step 3: Undo the deletion to restore her enrollment
ROLLBACK;
```

**Output Explanation:**
The `DELETE` statement temporarily removes Sara's data from the database. However, because the transaction was not committed, `ROLLBACK` fully restores her enrollment row as if the deletion never happened.

---

### 5.3.5 Transaction 5: Update Enrollment (Changing Course)

**Question:** Student "Rohan" (ID: 101) wants to change his enrolled course from "DBMS" (C1) to "OS" (C2). Coordinate dropping the old course and adding the new one atomically.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Update the enrollment record to the new course
UPDATE Enrollment 
SET course_id = 'C2' 
WHERE student_id = 101 AND course_id = 'C1';

-- Step 2: Increase available seats for the old course
UPDATE Course 
SET available_seats = available_seats + 1 
WHERE course_id = 'C1';

-- Step 3: Decrease available seats for the new course
UPDATE Course 
SET available_seats = available_seats - 1 
WHERE course_id = 'C2';

-- Step 4: Transaction complete, save changes
COMMIT;
```

**Output Explanation:**
This transaction handles a course transfer securely. It coordinates three actions simultaneously: modifying the student's enrollment, returning a seat to the old course, and consuming a seat in the new course. `COMMIT` guarantees that either all three happen, or none do.
