---

# STUDENT MANAGEMENT SYSTEM
## DBMS Mini Project Report
### Centralized College Database (CCD)

---

# CHAPTER 5 — TRANSACTIONS AND CONCURRENCY CONTROL

---

## 5.1 Introduction to Transactions

### What is a Transaction?

A **transaction** is a logical unit of database work that consists of one or more SQL operations (INSERT, UPDATE, DELETE, SELECT) executed as a **single, indivisible unit**. A transaction either:

- **Commits** — all changes are permanently saved, OR  
- **Rolls Back** — all changes are completely undone, as if the transaction never happened.

There is no partial success. This is what makes transactions essential for data integrity.

### Why Transactions Are Needed in Student Management System:

| Scenario | Why Transaction is Required |
|----------|-----------------------------|
| **Student Enrollment** | Insert into `enrollment` AND update seat count — both must succeed or both must fail |
| **Course Transfer** | DELETE old enrollment AND INSERT new one — must be atomic |
| **Grade Finalization** | Bulk updates to grades must all succeed or all rollback |
| **Instructor Reassignment** | Update courses + instructor table simultaneously |
| **Student Withdrawal** | Remove enrollment records + update department stats atomically |

### Basic Transaction Syntax in MySQL:

```sql
START TRANSACTION;           -- Begin the transaction

  -- Your SQL statements here
  INSERT INTO ...;
  UPDATE ...;
  DELETE FROM ...;

  SAVEPOINT checkpoint_name; -- Optional: create a restore point

  -- More SQL statements

  ROLLBACK TO checkpoint_name; -- Undo back to savepoint (partial rollback)
  -- OR
  ROLLBACK;                    -- Undo everything (full rollback)
  -- OR
  COMMIT;                      -- Save everything permanently

COMMIT;                        -- Finalize the transaction
```

---

## 5.2 ACID Properties

**ACID** is an acronym representing the four core properties that guarantee database transactions are processed **reliably and correctly**, even in the presence of errors, power failures, or concurrent access.

```
A — Atomicity
C — Consistency
I — Isolation
D — Durability
```

---

### 5.2.1 Atomicity

> **"All or Nothing"**
>
> A transaction is treated as a **single atomic unit**. Either ALL operations within the transaction are committed, or NONE of them are. There is no partial execution.

**Real-World Analogy:**  
If you transfer money from Account A to Account B — the debit from A and the credit to B must both happen. If only the debit happens and the system crashes, the database is inconsistent.

**Example — Student Enrollment in CCD:**

```sql
-- ATOMICITY EXAMPLE
-- Enrolling Student 101 in Database Systems (course_id = 16)
-- Both operations must succeed together

START TRANSACTION;

  -- Operation 1: Add enrollment record
  INSERT INTO enrollment (student_id, course_id)
  VALUES (101, 16);

  -- Operation 2: Reduce available seats
  UPDATE courses
  SET seats_available = seats_available - 1
  WHERE course_id = 16;

  -- If Operation 2 fails (e.g., seats_available is NULL or constraint violated),
  -- the entire transaction rolls back — enrollment insert is also undone.

COMMIT;
```

**Demonstrating Atomicity with ROLLBACK:**

```sql
START TRANSACTION;

  INSERT INTO enrollment (student_id, course_id) VALUES (102, 16);
  UPDATE courses SET seats_available = seats_available - 1 WHERE course_id = 16;

  -- Simulate an error being detected
  ROLLBACK; -- Both operations are undone — database unchanged

-- Result: No enrollment added, no seat count changed.
```

**Sample Output — Checking Atomicity:**

| Operation | Status After COMMIT | Status After ROLLBACK |
|-----------|---------------------|-----------------------|
| Enrollment inserted | ✅ Saved | ❌ Removed |
| Seats decremented | ✅ Saved | ❌ Restored |

---

### 5.2.2 Consistency

> **"Database must remain in a valid state before and after every transaction"**
>
> A transaction brings the database from one **consistent state** to another **consistent state**. All defined rules, constraints, triggers, and cascades must hold throughout.

**Types of Consistency Rules in CCD:**

| Rule | Enforcement |
|------|-------------|
| `age BETWEEN 16 AND 100` | CHECK constraint on `student` table |
| `course_id` must exist | FOREIGN KEY in `enrollment` table |
| `student_id` must be unique | PRIMARY KEY on `student` table |
| `department_id` must exist in `department` | FOREIGN KEY in `courses` table |

**Example — Constraint Violation (Consistency Maintained):**

```sql
-- CONSISTENCY EXAMPLE
-- Attempting to insert a student with invalid age

START TRANSACTION;

  -- This INSERT violates the CHECK constraint (age must be >= 16)
  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (999, 'Fake Student', 5, 'Unknown Address', 2024);

  -- MySQL raises an error: CHECK constraint failed
  -- The transaction automatically fails

ROLLBACK; -- Explicitly rollback to confirm no change

-- Database remains in consistent state:
SELECT * FROM student WHERE student_id = 999;
-- Result: Empty set (student was not inserted)
```

**Example — Foreign Key Consistency:**

```sql
START TRANSACTION;

  -- This will fail: course_id 999 does not exist in courses table
  INSERT INTO enrollment (student_id, course_id)
  VALUES (101, 999);

  -- ERROR: Cannot add or update a child row: a foreign key constraint fails
  -- Database consistency is maintained — no orphan enrollment record created

ROLLBACK;
```

**Sample Output:**

| Validation Check | Before Transaction | After ROLLBACK |
|------------------|--------------------|----------------|
| student_id = 999 in student table | ❌ Not present | ❌ Not present (consistent) |
| enrollment with course_id = 999 | ❌ Not present | ❌ Not present (consistent) |

---

### 5.2.3 Isolation

> **"Concurrent transactions must not interfere with each other"**
>
> Each transaction executes as if it were the **only transaction** running. Intermediate (uncommitted) state of one transaction is **invisible** to other concurrent transactions.

**Problems Caused by Lack of Isolation:**

| Problem | Description | Example in CCD |
|---------|-------------|----------------|
| **Dirty Read** | T1 reads uncommitted data written by T2, which then rolls back | Admin reads "30 seats" but enrollment was rolled back |
| **Non-Repeatable Read** | T1 reads same row twice and gets different results because T2 committed in between | Viewing student age changes mid-transaction |
| **Phantom Read** | T1 repeats a range query; T2 inserted new rows in between | COUNT(*) of CS students changes during batch processing |
| **Lost Update** | T1 and T2 both read and update same value; one update is lost | Two admins decrement seats simultaneously — only one decrement is saved |

**MySQL Isolation Levels:**

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Performance |
|-----------------|------------|---------------------|--------------|-------------|
| READ UNCOMMITTED | ✅ Can occur | ✅ Can occur | ✅ Can occur | Fastest |
| READ COMMITTED | ❌ Prevented | ✅ Can occur | ✅ Can occur | Fast |
| **REPEATABLE READ** | ❌ Prevented | ❌ Prevented | ✅ Can occur | **Default in MySQL** |
| SERIALIZABLE | ❌ Prevented | ❌ Prevented | ❌ Prevented | Slowest |

**Example — Isolation with REPEATABLE READ:**

```sql
-- ISOLATION EXAMPLE
-- Session A starts transaction and reads student data

-- SESSION A:
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;

  SELECT student_id, student_name, age
  FROM student
  WHERE student_id = 101;
  -- Result: Rahul Sharma, age = 20

  -- (At this point, Session B runs: UPDATE student SET age = 25 WHERE student_id = 101; COMMIT;)

  SELECT student_id, student_name, age
  FROM student
  WHERE student_id = 101;
  -- Result: Rahul Sharma, age = 20  (SAME as before — Session B's change is invisible)
  -- Isolation level REPEATABLE READ guarantees consistent reads within a transaction

COMMIT;
```

**Sample Output:**

| Read # | Session A Reads | Session B Update | Visible to A? |
|--------|-----------------|------------------|---------------|
| First Read | age = 20 | Not yet applied | — |
| Second Read | age = 20 | COMMITTED (age = 25) | ❌ No (isolation) |

---

### 5.2.4 Durability

> **"Once a transaction is committed, its changes persist permanently"**
>
> Committed changes survive **system crashes**, power failures, or hardware failures. The database uses **Write-Ahead Logging (WAL)** — changes are written to a durable log before being applied — ensuring recovery is possible.

**MySQL InnoDB Durability Mechanism:**
1. Changes are first written to the **redo log** (on disk).
2. Then applied to the database buffer pool (in memory).
3. Periodically flushed to the actual data files.
4. On crash recovery, MySQL replays the redo log to restore committed transactions.

**Example — Durability Guarantee:**

```sql
-- DURABILITY EXAMPLE
-- Adding a new student: once committed, it survives any crash

START TRANSACTION;

  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (205, 'Vikram Singh', 21, '14 Rajpur Road, Dehradun', 2024);

COMMIT;

-- Even if the MySQL server crashes NOW after COMMIT,
-- when recovered: SELECT * FROM student WHERE student_id = 205;
-- Result: Vikram Singh's record is permanently present.
```

**Sample Output:**

| Scenario | After COMMIT | After Server Crash + Recovery |
|----------|--------------|-------------------------------|
| student_id = 205 | ✅ Present | ✅ Still Present (durable) |

---

### 5.2.5 ACID Properties Summary Table

| Property | Guarantee | MySQL Mechanism | CCD Example |
|----------|-----------|-----------------|-------------|
| **Atomicity** | All-or-nothing execution | `ROLLBACK` / `COMMIT` | Enrollment + seat update together |
| **Consistency** | Valid state before and after | Constraints, FK, triggers | Age check, valid course_id |
| **Isolation** | Transactions don't interfere | Lock Manager, MVCC | Concurrent enrollment sessions |
| **Durability** | Committed data is permanent | Redo Log (WAL), InnoDB | Student record survives crash |

---

## 5.3 Transaction States

Every transaction goes through a well-defined lifecycle. The following diagram shows all possible states:

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
         BEGIN      ▼         Last Statement       ▼          ▼
         ───►  [ ACTIVE ] ──────────────► [ PARTIALLY  ] ──► [ COMMITTED ]
                    │                     COMMITTED  ]          (Permanent)
                    │                                         
                    │ Error/Failure                           
                    ▼                                         
              [ FAILED ]                                      
                    │                                         
                    │ ROLLBACK                                
                    ▼                                         
              [ ABORTED ]  ──────────────────────────────────►
             (All undone)                                      [ TERMINATED ]
                                                              (End of lifecycle)
```

### State Descriptions:

| State | Trigger | Description |
|-------|---------|-------------|
| **Active** | `START TRANSACTION` | Transaction has started; SQL operations are being executed one by one |
| **Partially Committed** | Last SQL statement executed | All SQL operations are done; changes exist in memory buffer but NOT yet on disk |
| **Committed** | `COMMIT` executed | All changes are permanently written to disk; transaction ends successfully |
| **Failed** | Error / constraint violation | Normal execution cannot continue; transaction must be rolled back |
| **Aborted** | `ROLLBACK` executed | All changes are undone; database restored to pre-transaction state |
| **Terminated** | After Commit or Abort | Transaction lifecycle is complete; resources are freed |

### State Transition Table:

| From State | Event | To State |
|------------|-------|----------|
| — | `START TRANSACTION` | Active |
| Active | SQL executed successfully | Active (continues) |
| Active | All SQL done, awaiting commit | Partially Committed |
| Partially Committed | `COMMIT` | Committed |
| Active | Error or Constraint Violation | Failed |
| Partially Committed | Write error / disk failure | Failed |
| Failed | `ROLLBACK` | Aborted |
| Committed | — | Terminated |
| Aborted | — | Terminated |

### Example Showing All States:

```sql
-- Demonstrates the full transaction state lifecycle

START TRANSACTION;    -- State: ACTIVE

  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (206, 'Riya Das', 20, '3 Queens Road, Kolkata', 2024);
  -- State: ACTIVE (operation succeeded, continues)

  INSERT INTO enrollment (student_id, course_id)
  VALUES (206, 1);
  -- State: ACTIVE (all SQL done)

  -- (Now in PARTIALLY COMMITTED state — changes in buffer, not on disk)

COMMIT;
-- State: COMMITTED → TERMINATED
-- Riya Das and her enrollment are permanently saved.
```

---

## 5.4 SQL Transactions — Five Practical Examples

> All examples are based on the actual CCD tables:  
> `student`, `courses`, `enrollment`, `department`, `instructor`

---

### Transaction 1: New Student Registration and Enrollment

**Scenario:**  
A new student **Meera Joshi** (ID: 201) joins the college and immediately enrolls in **Database Systems** (course_id = 16). This must be atomic — if enrollment fails, the student record should not be saved either.

**Steps:**
1. Insert new student record
2. Create a SAVEPOINT after student insert
3. Insert enrollment record
4. Verify successful enrollment
5. COMMIT if everything is correct

```sql
-- ================================================================
-- TRANSACTION 1: New Student Registration + Enrollment
-- Tables: student, enrollment, courses
-- ================================================================

START TRANSACTION;

  -- STEP 1: Insert new student record
  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (201, 'Meera Joshi', 20, '22 Brigade Road, Bangalore', 2024);

  -- STEP 2: Save progress after student is added
  SAVEPOINT after_student_insert;

  -- STEP 3: Enroll the student in Database Systems (course_id = 16)
  INSERT INTO enrollment (student_id, course_id)
  VALUES (201, 16);

  -- STEP 4: Verify enrollment was created correctly
  SELECT
    s.student_id,
    s.student_name,
    c.course_name,
    d.department_name
  FROM student s
  JOIN enrollment  e ON s.student_id  = e.student_id
  JOIN courses     c ON e.course_id   = c.course_id
  JOIN department  d ON c.department_id = d.department_id
  WHERE s.student_id = 201;

  -- If any error occurred during enrollment, rollback only enrollment:
  -- ROLLBACK TO after_student_insert;

  -- If both steps are fine, commit permanently
COMMIT;
```

**Sample Output:**

| student_id | student_name | course_name      | department_name  |
|------------|--------------|------------------|------------------|
| 201        | Meera Joshi  | Database Systems | Computer Science |

> ✅ Student registered and enrolled in one atomic operation. If enrollment had failed, `ROLLBACK TO after_student_insert` would have removed only the enrollment attempt, preserving the student record.

---

### Transaction 2: Student Address Update with Savepoint and Partial Rollback

**Scenario:**  
The registrar is updating addresses for two students. Student 101's address must change. An erroneous update is accidentally applied to Student 102. The registrar catches the mistake and needs to **undo only Student 102's change** while **keeping Student 101's update**.

```sql
-- ================================================================
-- TRANSACTION 2: Address Update with SAVEPOINT and ROLLBACK TO SAVEPOINT
-- Tables: student
-- Purpose: Demonstrate partial rollback using SAVEPOINT
-- ================================================================

START TRANSACTION;

  -- STEP 1: View current addresses before changes
  SELECT student_id, student_name, address
  FROM student
  WHERE student_id IN (101, 102);

  -- STEP 2: Correct update — Student 101's new address
  UPDATE student
  SET address = '55 Nehru Place, New Delhi'
  WHERE student_id = 101;

  -- STEP 3: Create a savepoint AFTER the correct update
  SAVEPOINT address_checkpoint;

  -- STEP 4: Erroneous update — Wrong address applied to Student 102
  UPDATE student
  SET address = 'WRONG ADDRESS - Data Entry Error'
  WHERE student_id = 102;

  -- STEP 5: Detect the mistake — rollback ONLY to the savepoint
  -- This undoes Step 4 (Student 102's wrong update) but KEEPS Step 2
  ROLLBACK TO address_checkpoint;

  -- STEP 6: Verify final state — only Student 101 was updated
  SELECT student_id, student_name, address
  FROM student
  WHERE student_id IN (101, 102);

COMMIT; -- Saves only Student 101's correct address update
```

**Sample Output — Before Transaction:**

| student_id | student_name | address               |
|------------|--------------|-----------------------|
| 101        | Rahul Sharma | 12 MG Road, Delhi     |
| 102        | Priya Patel  | 45 Lake Ave, Mumbai   |

**Sample Output — After COMMIT:**

| student_id | student_name | address                    |
|------------|--------------|----------------------------|
| 101        | Rahul Sharma | 55 Nehru Place, New Delhi  |
| 102        | Priya Patel  | 45 Lake Ave, Mumbai        |

> ✅ Student 101's address updated correctly.  
> ✅ Student 102's address is **unchanged** — the erroneous update was rolled back using SAVEPOINT.  
> ✅ `ROLLBACK TO SAVEPOINT` enables **fine-grained** partial undo within a transaction.

---

### Transaction 3: Safe Course Deletion with Cascade Enrollment Cleanup

**Scenario:**  
The college decides to retire the course **"World History II"** (course_id = 20) at the end of the semester. All current enrollments must be removed first (to satisfy the Foreign Key constraint), then the course itself is deleted. A SAVEPOINT is created before deletion so the entire operation can be aborted if needed.

```sql
-- ================================================================
-- TRANSACTION 3: Cascade Delete — Remove Course and All Enrollments
-- Tables: enrollment, courses
-- Purpose: Demonstrate safe multi-table deletion with SAVEPOINT guard
-- ================================================================

START TRANSACTION;

  -- STEP 1: Check what will be deleted (audit before deletion)
  SELECT
    s.student_name,
    c.course_name
  FROM enrollment e
  JOIN student s ON e.student_id = s.student_id
  JOIN courses c ON e.course_id  = c.course_id
  WHERE e.course_id = 20;

  -- STEP 2: Create a safety checkpoint before any deletion
  SAVEPOINT before_course_deletion;

  -- STEP 3: Remove all enrollments for course 20 FIRST (FK constraint)
  DELETE FROM enrollment
  WHERE course_id = 20;

  -- Check: enrollment rows removed cleanly
  SELECT COUNT(*) AS remaining_enrollments
  FROM enrollment
  WHERE course_id = 20;

  -- STEP 4: Now safely delete the course itself
  DELETE FROM courses
  WHERE course_id = 20;

  -- STEP 5: Verify course no longer exists
  SELECT course_id, course_name
  FROM courses
  WHERE course_id = 20;

  -- If anything went wrong: ROLLBACK TO before_course_deletion;

COMMIT; -- Permanently removes the course and all its enrollments
```

**Sample Output — Before Transaction (Audit):**

| student_name | course_name    |
|--------------|----------------|
| Sneha Roy    | World History II |
| Riya Das     | World History II |

**Sample Output — After Step 3 (Enrollment check):**

| remaining_enrollments |
|-----------------------|
| 0                     |

**Sample Output — After Step 5 (Course check):**

| course_id | course_name |
|-----------|-------------|
| (Empty set — course successfully deleted) | |

> ✅ Enrollments removed first — no Foreign Key violation.  
> ✅ Course deleted cleanly.  
> ✅ `SAVEPOINT` provides a rollback safety net before any destructive operation.

---

### Transaction 4: Student Course Transfer (Drop + Re-enroll)

**Scenario:**  
Student 103 (Ankit Verma) wants to **drop Electronics I** (course_id = 12) and **switch to Computer Networks** (course_id = 11). Both actions must happen together — if the new enrollment fails, the original enrollment must not be dropped.

```sql
-- ================================================================
-- TRANSACTION 4: Course Transfer — Drop Old, Add New
-- Tables: enrollment, student, courses
-- Purpose: Demonstrate atomic swap of enrollment records
-- ================================================================

START TRANSACTION;

  -- STEP 1: View Student 103's current enrollments
  SELECT
    s.student_name,
    c.course_name,
    d.department_name
  FROM student s
  JOIN enrollment e ON s.student_id = e.student_id
  JOIN courses    c ON e.course_id  = c.course_id
  JOIN department d ON c.department_id = d.department_id
  WHERE s.student_id = 103;

  -- STEP 2: Save state before transfer begins
  SAVEPOINT before_transfer;

  -- STEP 3: Drop enrollment from Electronics I (course_id = 12)
  DELETE FROM enrollment
  WHERE student_id = 103 AND course_id = 12;

  -- STEP 4: Add enrollment to Computer Networks (course_id = 11)
  INSERT INTO enrollment (student_id, course_id)
  VALUES (103, 11);

  -- STEP 5: Verify transfer is correct
  SELECT
    s.student_name,
    c.course_name,
    d.department_name
  FROM student s
  JOIN enrollment e ON s.student_id = e.student_id
  JOIN courses    c ON e.course_id  = c.course_id
  JOIN department d ON c.department_id = d.department_id
  WHERE s.student_id = 103;

  -- If results look wrong: ROLLBACK TO before_transfer;

COMMIT; -- Transfer is permanent
```

**Sample Output — Before Transfer:**

| student_name | course_name    | department_name  |
|--------------|----------------|------------------|
| Ankit Verma  | Power Systems  | Electrical Engg. |
| Ankit Verma  | Electronics I  | Electrical Engg. |

**Sample Output — After Transfer:**

| student_name | course_name       | department_name  |
|--------------|-------------------|------------------|
| Ankit Verma  | Power Systems     | Electrical Engg. |
| Ankit Verma  | Computer Networks | Computer Science |

> ✅ Electronics I dropped atomically with Computer Networks added.  
> ✅ If the INSERT into `enrollment` had failed (e.g., course full), `ROLLBACK TO before_transfer` would restore Electronics I enrollment.  
> ✅ Student is never left in a state where they have no course.

---

### Transaction 5: Bulk Course Duration Update with Validation

**Scenario:**  
The academic committee decides to extend all **Computer Science** department courses (department_id = 1) from 6 months to **12 months**. The update must affect exactly 6 courses. If the row count is wrong (another admin deleted courses concurrently), rollback.

```sql
-- ================================================================
-- TRANSACTION 5: Bulk Update with ROW_COUNT Validation
-- Tables: courses, department
-- Purpose: Demonstrate bulk update with conditional rollback logic
-- ================================================================

START TRANSACTION;

  -- STEP 1: Capture original state for comparison
  SELECT course_id, course_name, course_duration
  FROM courses
  WHERE department_id = 1
  ORDER BY course_id;

  -- STEP 2: Create safety savepoint before bulk modification
  SAVEPOINT before_bulk_update;

  -- STEP 3: Execute the bulk update
  UPDATE courses
  SET course_duration = '12 months'
  WHERE department_id = 1;

  -- STEP 4: Capture the number of rows affected
  SELECT ROW_COUNT() AS rows_updated;

  -- STEP 5: Validate — expected exactly 6 courses in CS dept
  -- If ROW_COUNT() != 6, rollback:
  -- ROLLBACK TO before_bulk_update;

  -- STEP 6: Verify updated records
  SELECT course_id, course_name, course_duration
  FROM courses
  WHERE department_id = 1
  ORDER BY course_id;

COMMIT; -- Persist all 6 course duration updates
```

**Sample Output — STEP 1 (Before Update):**

| course_id | course_name                  | course_duration |
|-----------|------------------------------|-----------------|
| 1         | Intro to Computer Science    | 6 months        |
| 2         | Digital Logic Design         | 6 months        |
| 6         | Data Structures & Algorithms | 6 months        |
| 11        | Computer Networks            | 6 months        |
| 16        | Database Systems             | 6 months        |

**Sample Output — STEP 4 (ROW_COUNT):**

| rows_updated |
|--------------|
| 5            |

**Sample Output — STEP 6 (After Update):**

| course_id | course_name                  | course_duration |
|-----------|------------------------------|-----------------|
| 1         | Intro to Computer Science    | 12 months       |
| 2         | Digital Logic Design         | 12 months       |
| 6         | Data Structures & Algorithms | 12 months       |
| 11        | Computer Networks            | 12 months       |
| 16        | Database Systems             | 12 months       |

> ✅ All 5 CS courses updated to 12 months duration.  
> ✅ `ROW_COUNT()` used to validate the expected number of affected rows.  
> ✅ `SAVEPOINT` allows rollback without cancelling the entire transaction context.

---

## 5.5 Real-World Scenario: Student Enrolling (Buying) a Course

In a Student Management System, a student enrolling in a course is a classic real-world transaction scenario. This process involves multiple dependent steps:
1. Checking and reducing the `available_seats` in the **Course** table.
2. Inserting a new record into the **Enrollment** table.

If the course is full, or if the insert fails, the system must **roll back** to ensure no seats are wrongly deducted.

**Tables Used for these Examples:**

```sql
Student(student_id, student_name, dept_id)
Course(course_id, course_name, available_seats)
Enrollment(en_id, student_id, course_id, date)
```

---

### 5.5.1 Transaction 1: Successful Course Enrollment

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

| en_id | student_id | course_id | date       |
|-------|------------|-----------|------------|
| 1     | 101        | C1        | 2024-04-12 |

| course_id | course_name | available_seats (before) | available_seats (after) |
|-----------|-------------|--------------------------|------------------------|
| C1        | DBMS        | 30                       | 29                     |

---

### 5.5.2 Transaction 2: Failure Case (Course Full → Rollback)

**Question:** Student "Neha" (ID: 102) tries to enroll in "OS" (Course ID: C2). However, after trying to update the seats, the system detects the course is actually full (0 seats). Handle this failure using a rollback.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Attempt to reduce seats
UPDATE Course 
SET available_seats = available_seats - 1 
WHERE course_id = 'C2';

-- Step 2: System detects error — course is actually full (seats would go negative)
-- The application detects a problem and aborts the insert

-- Step 3: Undo the seat reduction — restore original state
ROLLBACK;
```

**Output Explanation:**
When a failure occurs, the `ROLLBACK` command is triggered. The database returns to its exact state before `START TRANSACTION`. The seat count for 'C2' is restored to its original value, ensuring data consistency.

| course_id | course_name | available_seats (before) | available_seats (after ROLLBACK) |
|-----------|-------------|--------------------------|----------------------------------|
| C2        | OS          | 0                        | 0 (unchanged — rollback worked)  |

---

### 5.5.3 Transaction 3: Partial Update with SAVEPOINT

**Question:** Student "Amit" (ID: 103) wants to enroll in "Networks" (C3). First, update the course seats successfully. Create a savepoint. Then, attempt to insert the enrollment but admin makes a typo (wrong student ID 999). Rollback only the typo using the savepoint and insert the correct data.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Update the course seats
UPDATE Course 
SET available_seats = available_seats - 1 
WHERE course_id = 'C3';

-- Step 2: Create a savepoint after successful seat update
SAVEPOINT seats_updated;

-- Step 3: Admin makes a typo — inserts wrong student ID (999)
INSERT INTO Enrollment (en_id, student_id, course_id, date) 
VALUES (3, 999, 'C3', CURDATE()); 
-- Error: Foreign Key violation — Student 999 does not exist

-- Step 4: Mistake realized — rollback ONLY to savepoint (undo bad insert)
ROLLBACK TO seats_updated;

-- Step 5: Insert with the correct student ID
INSERT INTO Enrollment (en_id, student_id, course_id, date) 
VALUES (3, 103, 'C3', CURDATE());

-- Step 6: Commit all valid changes
COMMIT;
```

**Output Explanation:**
The `SAVEPOINT` acts as a safe checkpoint. When the first `INSERT` failed due to a typo, `ROLLBACK TO seats_updated` undid the bad insert **without** undoing the successful seat reduction. The transaction then finished successfully with the correct data.

| Action | Status |
|--------|--------|
| Seat reduction (Step 1) | ✅ Kept (not rolled back) |
| Wrong insert (Step 3)   | ❌ Rolled back to savepoint |
| Correct insert (Step 5) | ✅ Committed |

| en_id | student_id | course_id | date       |
|-------|------------|-----------|------------|
| 3     | 103        | C3        | 2024-04-12 |

---

### 5.5.4 Transaction 4: Delete Enrollment with Rollback

**Question:** Student "Sara" (ID: 104) accidentally clicks "Drop Course" for "AI" (Course ID: C4). The backend deletes her enrollment. Before the transaction finishes, she cancels the action. Rollback the deletion.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Delete the enrollment record
DELETE FROM Enrollment 
WHERE student_id = 104 AND course_id = 'C4';

-- Step 2: User cancels the action before changes are committed

-- Step 3: Undo the deletion — restore her enrollment
ROLLBACK;
```

**Output Explanation:**
The `DELETE` statement temporarily removes Sara's data from the database buffer. However, because the transaction was not committed, `ROLLBACK` fully restores her enrollment row as if the deletion never happened.

| State | Enrollment Record for Sara |
|-------|----------------------------|
| Before DELETE | ✅ Present (en_id=4, student_id=104, course_id=C4) |
| After DELETE (uncommitted) | ❌ Temporarily removed |
| After ROLLBACK | ✅ Restored — record exists again |

---

### 5.5.5 Transaction 5: Update Enrollment (Changing Course)

**Question:** Student "Rohan" (ID: 101) wants to change his course from "DBMS" (C1) to "OS" (C2). Coordinate dropping the old course and adding the new one atomically.

**SQL Statement:**
```sql
START TRANSACTION;

-- Step 1: Update the enrollment record to the new course
UPDATE Enrollment 
SET course_id = 'C2' 
WHERE student_id = 101 AND course_id = 'C1';

-- Step 2: Increase available seats for the old course (return the seat)
UPDATE Course 
SET available_seats = available_seats + 1 
WHERE course_id = 'C1';

-- Step 3: Decrease available seats for the new course (take a seat)
UPDATE Course 
SET available_seats = available_seats - 1 
WHERE course_id = 'C2';

-- Step 4: All three steps successful — save changes permanently
COMMIT;
```

**Output Explanation:**
This transaction handles a course transfer securely. It coordinates three dependent actions simultaneously: modifying the student's enrollment, returning a seat to the old course, and consuming a seat in the new course. `COMMIT` guarantees that either all three happen, or none do.

| course_id | course_name | seats_before | seats_after |
|-----------|-------------|--------------|-------------|
| C1 (old)  | DBMS        | 29           | 30 (+1 returned) |
| C2 (new)  | OS          | 30           | 29 (-1 taken)    |

| en_id | student_id | course_id (before) | course_id (after) |
|-------|------------|--------------------|-----------------  |
| 1     | 101        | C1                 | C2                |

---

## 5.6 Concurrency Control

### 5.6.1 What is Concurrency?

**Concurrency** refers to the ability of a database to handle **multiple transactions executing simultaneously**. Modern databases like MySQL serve hundreds of users concurrently.

Without proper concurrency control, concurrent transactions can produce **incorrect results** even when each transaction individually is correct.

### 5.6.2 Concurrency Problems

| Problem | Description | Example in Student Management |
|---------|-------------|-------------------------------|
| **Dirty Read** | T1 reads data written by T2 before T2 commits. If T2 rolls back, T1 used invalid data. | Admin A reads 10 seats available; Admin B updates to 9 then rolls back; Admin A enrolled based on wrong count |
| **Lost Update** | T1 and T2 both read the same value, both update it — one update overwrites the other silently. | Admins A and B both read `seats = 10`. A writes 9, B writes 9. Net result: 9 (should be 8) |
| **Non-Repeatable Read** | T1 reads a row, T2 modifies and commits, T1 reads same row again — different result. | Registrar reads student age as 20, then again sees 21 mid-transaction |
| **Phantom Read** | T1 reads a set of rows via a WHERE clause. T2 inserts a new row matching that WHERE. T1 re-reads — sees extra "phantom" row. | Count of CS students was 45, then 46 — confused batch report |

### 5.6.3 Concurrency Control Techniques

| Technique | Mechanism | Best Used For |
|-----------|-----------|---------------|
| **Pessimistic Locking** | Lock acquired before reading/writing; others wait | High-conflict scenarios (enrollment, seat booking) |
| **Optimistic Concurrency** | No locks; validate at commit time; rollback on conflict | Low-conflict scenarios (read-heavy reporting) |
| **MVCC** (Multi-Version Concurrency Control) | Keep multiple versions of data; readers don't block writers | MySQL InnoDB default — used automatically |
| **Timestamp Ordering** | Transactions ordered by timestamp; older ones get priority | Distributed databases |

---

### 5.6.4 Concurrency Control Example 1: SELECT ... FOR UPDATE (Pessimistic Row-Level Lock)

**Scenario:**  
Two college administrators are simultaneously trying to enroll students in **Database Systems** (course_id = 16), which has only **1 seat remaining**. Without locking, both could read `seats_available = 1`, both enroll their student, and the seat count goes to -1 (overbooking). We use `SELECT ... FOR UPDATE` to prevent this **Lost Update** problem.

**How `SELECT FOR UPDATE` Works:**
- Acquires an **exclusive row-level lock** on the selected rows.
- Other transactions attempting to `SELECT FOR UPDATE` the same rows will **block and wait**.
- Lock is released automatically on `COMMIT` or `ROLLBACK`.

```sql
-- ================================================================
-- CONCURRENCY EXAMPLE 1: SELECT ... FOR UPDATE (Row-Level Lock)
-- Scenario: Two admins enrolling students in a course with 1 seat left
-- Run SESSION A first; then SESSION B in a second MySQL connection
-- ================================================================

-- ─────────────────────────────────────────────
-- SESSION A: Admin enrolling Student 201
-- ─────────────────────────────────────────────

START TRANSACTION; -- Session A begins

  -- STEP 1: Read and LOCK the course row exclusively
  -- Session B cannot read this row with FOR UPDATE until Session A commits
  SELECT course_id, course_name, seats_available
  FROM courses
  WHERE course_id = 16
  FOR UPDATE;

  -- Session B is now BLOCKED here if it tries SELECT FOR UPDATE on course 16

  -- STEP 2: Check availability then proceed
  -- (In application code, check if seats_available > 0 before proceeding)

  -- STEP 3: Enroll Student 201
  INSERT INTO enrollment (student_id, course_id)
  VALUES (201, 16);

  -- STEP 4: Decrement the seat count
  UPDATE courses
  SET seats_available = seats_available - 1
  WHERE course_id = 16;

  -- STEP 5: Verify seat count
  SELECT course_id, course_name, seats_available
  FROM courses
  WHERE course_id = 16;

COMMIT; -- Lock is RELEASED; Session B can now proceed

-- ─────────────────────────────────────────────
-- SESSION B: Admin enrolling Student 202
-- (Run in a separate MySQL connection simultaneously)
-- ─────────────────────────────────────────────

START TRANSACTION; -- Session B begins

  -- This was BLOCKED until Session A committed
  -- Now Session B reads the UPDATED value: seats_available = 0
  SELECT course_id, course_name, seats_available
  FROM courses
  WHERE course_id = 16
  FOR UPDATE;

  -- Application logic: if seats_available = 0, cannot enroll
  -- Session B would ROLLBACK — preventing overbooking

  -- (If seats_available > 0, proceed with enrollment)
  -- INSERT INTO enrollment (student_id, course_id) VALUES (202, 16);
  -- UPDATE courses SET seats_available = seats_available - 1 WHERE course_id = 16;

ROLLBACK; -- Session B rolls back — course is full
```

**Execution Timeline:**

| Time | Session A | Session B | seats_available |
|------|-----------|-----------|-----------------|
| T1 | `START TRANSACTION` | — | 1 |
| T2 | `SELECT FOR UPDATE` (locks row) | — | 1 |
| T3 | INSERT enrollment | `SELECT FOR UPDATE` → **BLOCKED** | 1 |
| T4 | UPDATE seats = 0 | Still blocked | 0 |
| T5 | `COMMIT` (lock released) | Unblocked | 0 |
| T6 | — | Reads seats = 0 | 0 |
| T7 | — | `ROLLBACK` (no seats) | 0 |

**Sample Output — After Session A COMMIT:**

| course_id | course_name      | seats_available |
|-----------|------------------|-----------------|
| 16        | Database Systems | 0               |

> ✅ No overbooking — `SELECT FOR UPDATE` serialized the two transactions.  
> ✅ Session B correctly sees 0 seats and aborts enrollment.  
> ✅ Row-level locking allows other courses to be enrolled in simultaneously (only course 16 is locked).

---

### 5.6.5 Concurrency Control Example 2: LOCK TABLES (Table-Level Lock)

**Scenario:**  
At the end of semester, the academic office runs a **batch finalization process** — marking all active enrollments as `FINALIZED`. During this process, no student should be able to add or drop courses. A **table-level exclusive lock** is placed on the `enrollment` table.

**How `LOCK TABLES` Works:**
- `LOCK TABLES table_name WRITE` — only the locking session can read/write; all others are blocked.
- `LOCK TABLES table_name READ` — all sessions can read; nobody can write.
- Released by `UNLOCK TABLES` or when the session ends.
- ⚠️ **Note:** `LOCK TABLES` commits any active transaction first.

```sql
-- ================================================================
-- CONCURRENCY EXAMPLE 2: LOCK TABLES (Table-Level Lock)
-- Scenario: End-of-semester batch finalization
-- All student additions/drops are blocked during this operation
-- ================================================================

-- STEP 1: Acquire table-level locks
-- WRITE lock on enrollment (exclusive — blocks all other access)
-- READ lock on student and courses (shared — allows reads, blocks writes)
LOCK TABLES
  enrollment WRITE,
  student    READ,
  courses    READ;

  -- -------------------------------------------------------
  -- All other sessions attempting to access `enrollment`
  -- are now BLOCKED until UNLOCK TABLES is called
  -- -------------------------------------------------------

  -- STEP 2: Audit before batch update
  SELECT
    COUNT(*) AS total_active_enrollments
  FROM enrollment
  WHERE status = 'ACTIVE';

  -- STEP 3: Run batch finalization
  UPDATE enrollment
  SET status = 'FINALIZED'
  WHERE status = 'ACTIVE';

  -- STEP 4: Verify the batch update
  SELECT
    COUNT(*) AS finalized_count,
    status
  FROM enrollment
  GROUP BY status;

  -- STEP 5: Optional — generate a summary report while locks are held
  SELECT
    d.department_name,
    COUNT(*) AS finalized_enrollments
  FROM enrollment e
  JOIN courses    c ON e.course_id    = c.course_id
  JOIN department d ON c.department_id = d.department_id
  WHERE e.status = 'FINALIZED'
  GROUP BY d.department_name
  ORDER BY finalized_enrollments DESC;

-- STEP 6: Release all locks — other sessions can now access enrollment
UNLOCK TABLES;
```

**Sample Output — STEP 2 (Before Batch):**

| total_active_enrollments |
|--------------------------|
| 47                       |

**Sample Output — STEP 4 (After Batch):**

| finalized_count | status    |
|-----------------|-----------|
| 47              | FINALIZED |
| 0               | ACTIVE    |

**Sample Output — STEP 5 (Department-wise Report):**

| department_name    | finalized_enrollments |
|--------------------|-----------------------|
| Computer Science   | 18                    |
| Math               | 12                    |
| Electrical Engg.   | 9                     |
| English            | 5                     |
| History            | 3                     |

> ✅ 47 enrollments finalized in one locked batch operation.  
> ✅ No student could add/drop courses during the process.  
> ✅ `UNLOCK TABLES` releases the lock — normal operations resume.

---

### 5.6.6 Comparison: SELECT FOR UPDATE vs LOCK TABLES

| Feature | `SELECT ... FOR UPDATE` | `LOCK TABLES` |
|---------|------------------------|----------------|
| **Lock Granularity** | **Row-level** (selected rows only) | **Table-level** (entire table) |
| **Used Inside** | Inside a transaction (`START TRANSACTION`) | Outside transaction (session-level) |
| **Other Sessions** | Can still access unaffected rows | Completely blocked from accessing the table |
| **Concurrency** | High — only specific rows are locked | Low — entire table is unavailable |
| **Lock Release** | Automatically on `COMMIT` / `ROLLBACK` | Manually with `UNLOCK TABLES` or session end |
| **Best Use Case** | OLTP — frequent, targeted updates (seat booking, enrollment) | Batch/admin operations (grade finalization, migration) |
| **Performance Impact** | Minimal — only blocks conflicting rows | High — blocks entire table from all users |
| **MySQL Engine** | InnoDB (supports row-level locking) | All engines (MyISAM and InnoDB) |

---

## 5.7 SAVEPOINT Reference

A **SAVEPOINT** is a named marker within a transaction to which you can partially rollback, without cancelling the entire transaction.

### SAVEPOINT Commands:

| Command | Syntax | Description |
|---------|--------|-------------|
| **Create Savepoint** | `SAVEPOINT savepoint_name;` | Creates a restore point at this moment in the transaction |
| **Rollback to Savepoint** | `ROLLBACK TO savepoint_name;` | Undoes all changes made AFTER this savepoint |
| **Release Savepoint** | `RELEASE SAVEPOINT savepoint_name;` | Deletes the savepoint (cannot rollback to it anymore) |

### Savepoint Example — Multiple Checkpoints:

```sql
START TRANSACTION;

  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (210, 'Aarav Mehta', 19, '7 Brigade Road, Bangalore', 2024);

  SAVEPOINT sp_student; -- Checkpoint 1: student added

  INSERT INTO enrollment (student_id, course_id)
  VALUES (210, 1);

  SAVEPOINT sp_enrollment1; -- Checkpoint 2: first enrollment added

  INSERT INTO enrollment (student_id, course_id)
  VALUES (210, 6);

  SAVEPOINT sp_enrollment2; -- Checkpoint 3: second enrollment added

  -- Oops — wrong course for this student, undo only second enrollment:
  ROLLBACK TO sp_enrollment1;
  -- student is saved, first enrollment is saved, second is undone

  -- Now add the correct course instead:
  INSERT INTO enrollment (student_id, course_id)
  VALUES (210, 16); -- Correct course: Database Systems

COMMIT; -- Save: student + enrollment in course 1 + enrollment in course 16
```

**Savepoint State Diagram:**

```
START → [Insert Student] → SAVEPOINT sp_student
                         → [Insert Enrollment 1] → SAVEPOINT sp_enrollment1
                                                 → [Insert Enrollment 2] → SAVEPOINT sp_enrollment2
                                                                         → ROLLBACK TO sp_enrollment1
                                                 → [Insert Enrollment (correct)] → COMMIT
```

---

## 5.8 Complete Chapter Summary

### 5.8.1 Transaction Keywords Reference

| Keyword | Purpose | When to Use |
|---------|---------|-------------|
| `START TRANSACTION` | Begin a new transaction | Before any group of related SQL operations |
| `COMMIT` | Permanently save all changes | When all operations succeeded correctly |
| `ROLLBACK` | Undo all changes since transaction began | When an error occurs or result is wrong |
| `SAVEPOINT name` | Set a named restore point | Before a risky step inside a transaction |
| `ROLLBACK TO name` | Undo changes only back to savepoint | To undo part of a transaction, keep rest |
| `RELEASE SAVEPOINT name` | Delete a savepoint | When a savepoint is no longer needed |

### 5.8.2 ACID Quick Reference

| Property | One-Line Summary | Key Command |
|----------|-----------------|-------------|
| **A**tomicity | All or nothing | `ROLLBACK` on error |
| **C**onsistency | Database stays valid | Constraints + FK checks |
| **I**solation | Transactions don't see each other's work | Isolation levels / Locking |
| **D**urability | Committed data persists forever | InnoDB redo log / WAL |

### 5.8.3 Concurrency Tools Reference

| Tool | Type | Effect |
|------|------|--------|
| `SELECT ... FOR UPDATE` | Pessimistic row lock | Blocks other `FOR UPDATE` reads on same rows |
| `LOCK TABLES ... WRITE` | Table write lock | Blocks all other sessions from table |
| `LOCK TABLES ... READ` | Table read lock | Allows reads; blocks writes from others |
| `UNLOCK TABLES` | Release all table locks | Restores normal concurrent access |
| `SET TRANSACTION ISOLATION LEVEL` | Isolation tuning | Controls dirty/phantom read behavior |

### 5.8.4 All Transactions Summary

**Section 5.4 — CCD Database Transactions:**

| # | Transaction | Key Commands Used | Tables Involved |
|---|-------------|------------------|-----------------|
| 1 | New student registration + enrollment | `START`, `SAVEPOINT`, `COMMIT` | `student`, `enrollment`, `courses` |
| 2 | Address update with partial rollback | `START`, `SAVEPOINT`, `ROLLBACK TO`, `COMMIT` | `student` |
| 3 | Course deletion with cascade cleanup | `START`, `SAVEPOINT`, `DELETE`, `COMMIT` | `enrollment`, `courses` |
| 4 | Course transfer (drop + re-enroll) | `START`, `SAVEPOINT`, `DELETE`, `INSERT`, `COMMIT` | `enrollment`, `student`, `courses` |
| 5 | Bulk duration update with validation | `START`, `SAVEPOINT`, `UPDATE`, `ROW_COUNT()`, `COMMIT` | `courses`, `department` |

**Section 5.5 — Real-World Course Enrollment Transactions:**

| # | Transaction | Key Commands Used | Tables Involved |
|---|-------------|------------------|-----------------|
| 1 | Successful course enrollment | `START`, `UPDATE`, `INSERT`, `COMMIT` | `Course`, `Enrollment` |
| 2 | Course full → rollback | `START`, `UPDATE`, `ROLLBACK` | `Course` |
| 3 | Partial update with SAVEPOINT | `START`, `SAVEPOINT`, `ROLLBACK TO`, `COMMIT` | `Course`, `Enrollment` |
| 4 | Delete enrollment with rollback | `START`, `DELETE`, `ROLLBACK` | `Enrollment` |
| 5 | Update enrollment (change course) | `START`, `UPDATE`, `COMMIT` | `Course`, `Enrollment` |

---

*End of Chapter 5 — Transactions and Concurrency Control*  
*Student Management System — Centralized College Database*  
*DBMS Mini Project Report*
