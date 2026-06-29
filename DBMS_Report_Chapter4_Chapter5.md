
# DBMS Mini Project Report
## Student Management System (Centralized College Database)

---

# CHAPTER 4: NORMALIZATION

## 4.1 Introduction to Normalization

Normalization is the process of organizing a relational database to reduce data redundancy and improve data integrity. It involves decomposing tables into smaller, well-structured tables and defining relationships between them. The goals are:

- **Eliminate redundant (duplicate) data** — storing the same data in more than one table.
- **Ensure data dependencies make sense** — storing only related data in a table.
- **Avoid Insertion, Deletion, and Update Anomalies.**

The normalization process proceeds through successive normal forms:  
**UNF → 1NF → 2NF → 3NF → BCNF → 4NF → 5NF**

---

## 4.2 Unnormalized Form (UNF)

### Problem Statement

In the Student Management System, raw data collected from admission forms combines Student, Course, Enrollment, and Department information into a single flat table. This is the **unnormalized** state.

### UNF Table: `Student_Raw`

| StudentID | StudentName  | Age | Address         | CourseIDs    | CourseNames                                       | CourseDurations          | DeptID | DeptName           | InstructorID | InstructorName      | Year |
|-----------|--------------|-----|-----------------|--------------|---------------------------------------------------|--------------------------|--------|--------------------|--------------|---------------------|------|
| 101       | Rahul Sharma | 20  | 12 MG Road, Delhi | {1, 6}     | {Intro to CS, Data Structures}                    | {6 months, 6 months}     | 1      | Computer Science   | 1            | Prof. Alan Turing   | 2022 |
| 102       | Priya Patel  | 21  | 45 Lake Ave, Mumbai | {3, 8}   | {Calculus I, Linear Algebra}                      | {6 months, 6 months}     | 3      | Math               | 3            | Prof. Carl Gauss    | 2023 |
| 103       | Ankit Verma  | 19  | 7 Park St, Pune | {7, 12}      | {Power Systems, Electronics I}                    | {6 months, 6 months}     | 2      | Electrical Engg.   | 2            | Prof. Nikola Tesla  | 2022 |

### Issues in UNF:
1. **Repeating Groups** — `CourseIDs`, `CourseNames`, `CourseDurations` contain multiple values in a single cell (multi-valued attributes).
2. **No atomic values** — A single cell holds a set `{1, 6}` or `{Calculus I, Linear Algebra}`.
3. **Massive redundancy** — Department and Instructor data repeated for every student row.
4. **No valid primary key** — Cannot uniquely identify a row because of repeating course groups.

---

## 4.3 First Normal Form (1NF)

### Rule:
> A table is in **1NF** if:
> - All attributes contain **atomic (indivisible) values**.
> - There are **no repeating groups** or arrays.
> - Each record is uniquely identifiable.

### Issue Identified (Before 1NF)
The column `CourseIDs` contains sets like `{1, 6}` — violating atomicity. Each row must have exactly ONE value per column.

### Dependency Identified:
- `(StudentID, CourseID) → StudentName, Age, Address, CourseName, CourseDuration, DeptID, DeptName, InstructorID, InstructorName, Year`

### Pitfall (Problem):
| Anomaly | Description |
|---------|-------------|
| **Insertion** | Cannot insert a student without knowing at least one course. |
| **Deletion** | Deleting the only course of a student removes student info too. |
| **Update** | Changing a student's address requires updating every row for that student. |

### BEFORE (UNF — Violates 1NF):

| StudentID | StudentName  | CourseIDs | CourseNames                       |
|-----------|--------------|-----------|-----------------------------------|
| 101       | Rahul Sharma | {1, 6}    | {Intro to CS, Data Structures}    |
| 102       | Priya Patel  | {3, 8}    | {Calculus I, Linear Algebra}      |

### AFTER (1NF — Atomic values, one row per enrollment):

**Table: `Student_1NF`**

| StudentID | StudentName   | Age | Address               | CourseID | CourseName                   | CourseDuration | DeptID | DeptName         | InstructorID | InstructorName      | Year |
|-----------|---------------|-----|-----------------------|----------|------------------------------|----------------|--------|------------------|--------------|---------------------|------|
| 101       | Rahul Sharma  | 20  | 12 MG Road, Delhi     | 1        | Intro to Computer Science    | 6 months       | 1      | Computer Science | 1            | Prof. Alan Turing   | 2022 |
| 101       | Rahul Sharma  | 20  | 12 MG Road, Delhi     | 6        | Data Structures & Algorithms | 6 months       | 1      | Computer Science | 1            | Prof. Alan Turing   | 2022 |
| 102       | Priya Patel   | 21  | 45 Lake Ave, Mumbai   | 3        | Calculus I                   | 6 months       | 3      | Math             | 3            | Prof. Carl Gauss    | 2023 |
| 102       | Priya Patel   | 21  | 45 Lake Ave, Mumbai   | 8        | Linear Algebra               | 6 months       | 3      | Math             | 3            | Prof. Carl Gauss    | 2023 |
| 103       | Ankit Verma   | 19  | 7 Park St, Pune       | 7        | Power Systems                | 6 months       | 2      | Electrical Engg. | 2            | Prof. Nikola Tesla  | 2022 |
| 103       | Ankit Verma   | 19  | 7 Park St, Pune       | 12       | Electronics I                | 6 months       | 2      | Electrical Engg. | 2            | Prof. Nikola Tesla  | 2022 |

**Primary Key: `(StudentID, CourseID)`**  
✅ No repeating groups. All values are atomic. Table is now in **1NF**.

---

## 4.4 Second Normal Form (2NF)

### Rule:
> A table is in **2NF** if:
> - It is in **1NF**, AND
> - Every non-key attribute is **fully functionally dependent** on the **entire composite primary key** (no partial dependencies).

### Partial Dependencies Identified:

The composite key is `(StudentID, CourseID)`. Look at attributes:

| Attribute       | Depends on               | Type                 |
|----------------|--------------------------|----------------------|
| StudentName    | Only `StudentID`         | ⚠️ Partial Dependency |
| Age            | Only `StudentID`         | ⚠️ Partial Dependency |
| Address        | Only `StudentID`         | ⚠️ Partial Dependency |
| Year           | Only `StudentID`         | ⚠️ Partial Dependency |
| CourseName     | Only `CourseID`          | ⚠️ Partial Dependency |
| CourseDuration | Only `CourseID`          | ⚠️ Partial Dependency |
| DeptID         | Only `CourseID`          | ⚠️ Partial Dependency |
| DeptName       | Only `CourseID`          | ⚠️ Partial Dependency |
| InstructorID   | Only `CourseID`          | ⚠️ Partial Dependency |
| InstructorName | Only `CourseID`          | ⚠️ Partial Dependency |

### Pitfall (Problem):
- **Redundancy**: StudentName/Address repeats for every course a student enrolls in.
- **Update Anomaly**: Changing a student's address means updating multiple rows.
- **Deletion Anomaly**: Dropping all enrollments of a student loses all student data.

### BEFORE (1NF — Has partial dependencies):

| **StudentID** | **CourseID** | StudentName  | Age | Address             | CourseName     | CourseDuration | DeptID | DeptName         | ... |
|---------------|--------------|--------------|-----|---------------------|----------------|----------------|--------|------------------|-----|
| 101           | 1            | Rahul Sharma | 20  | 12 MG Road, Delhi   | Intro to CS    | 6 months       | 1      | Computer Science | ... |
| 101           | 6            | Rahul Sharma | 20  | 12 MG Road, Delhi   | Data Structures| 6 months       | 1      | Computer Science | ... |

### AFTER (2NF — Decomposed into 3 tables):

**Table 1: `Student_2NF`** (Depends only on `StudentID`)

| StudentID | StudentName   | Age | Address               | Year |
|-----------|---------------|-----|-----------------------|------|
| 101       | Rahul Sharma  | 20  | 12 MG Road, Delhi     | 2022 |
| 102       | Priya Patel   | 21  | 45 Lake Ave, Mumbai   | 2023 |
| 103       | Ankit Verma   | 19  | 7 Park St, Pune       | 2022 |

**Table 2: `Course_2NF`** (Depends only on `CourseID`)

| CourseID | CourseName                   | CourseDuration | DeptID | DeptName         | InstructorID | InstructorName     |
|----------|------------------------------|----------------|--------|------------------|--------------|--------------------|
| 1        | Intro to Computer Science    | 6 months       | 1      | Computer Science | 1            | Prof. Alan Turing  |
| 3        | Calculus I                   | 6 months       | 3      | Math             | 3            | Prof. Carl Gauss   |
| 6        | Data Structures & Algorithms | 6 months       | 1      | Computer Science | 1            | Prof. Alan Turing  |
| 7        | Power Systems                | 6 months       | 2      | Electrical Engg. | 2            | Prof. Nikola Tesla |

**Table 3: `Enrollment_2NF`** (Depends on full key `(StudentID, CourseID)`)

| StudentID | CourseID |
|-----------|----------|
| 101       | 1        |
| 101       | 6        |
| 102       | 3        |
| 102       | 8        |
| 103       | 7        |
| 103       | 12       |

✅ All partial dependencies removed. Table is now in **2NF**.

---

## 4.5 Third Normal Form (3NF)

### Rule:
> A table is in **3NF** if:
> - It is in **2NF**, AND
> - There are **no transitive dependencies** (non-key attribute depending on another non-key attribute).

### Transitive Dependencies Identified (in `Course_2NF`):

Functional dependencies chain:
```
CourseID → DeptID → DeptName
CourseID → InstructorID → InstructorName
```

| Dependency                  | Type                    |
|-----------------------------|-------------------------|
| `CourseID → InstructorID`   | Direct (OK)             |
| `InstructorID → InstructorName` | ⚠️ Transitive via InstructorID |
| `CourseID → DeptID`         | Direct (OK)             |
| `DeptID → DeptName`         | ⚠️ Transitive via DeptID        |

### Pitfall (Problem):
- **Redundancy**: `DeptName` repeats for every course in the same department.
- **Update Anomaly**: If the department name changes, all course rows must be updated.
- **Deletion Anomaly**: Deleting all courses removes department/instructor info.

### BEFORE (2NF — Has transitive dependencies in `Course_2NF`):

| **CourseID** | CourseName   | CourseDuration | **DeptID** | DeptName         | **InstructorID** | InstructorName     |
|--------------|--------------|----------------|------------|------------------|------------------|--------------------|
| 1            | Intro to CS  | 6 months       | 1          | Computer Science | 1                | Prof. Alan Turing  |
| 7            | Power Systems| 6 months       | 2          | Electrical Engg. | 2                | Prof. Nikola Tesla |

### AFTER (3NF — Transitive dependencies removed, 4 tables):

**Table 1: `Department_3NF`**

| DeptID | DeptName           |
|--------|--------------------|
| 1      | Computer Science   |
| 2      | Electrical Engg.   |
| 3      | Math               |
| 4      | English            |
| 5      | History            |

**Table 2: `Instructor_3NF`**

| InstructorID | InstructorName      | DeptID |
|--------------|---------------------|--------|
| 1            | Prof. Alan Turing   | 1      |
| 2            | Prof. Nikola Tesla  | 2      |
| 3            | Prof. Carl Gauss    | 3      |

**Table 3: `Course_3NF`**

| CourseID | CourseName                   | CourseDuration | DeptID | InstructorID |
|----------|------------------------------|----------------|--------|--------------|
| 1        | Intro to Computer Science    | 6 months       | 1      | 1            |
| 3        | Calculus I                   | 6 months       | 3      | 3            |
| 6        | Data Structures & Algorithms | 6 months       | 1      | 1            |
| 7        | Power Systems                | 6 months       | 2      | 2            |

**Table 4: `Student_3NF`** (unchanged from 2NF)

| StudentID | StudentName  | Age | Address             | Year |
|-----------|--------------|-----|---------------------|------|
| 101       | Rahul Sharma | 20  | 12 MG Road, Delhi   | 2022 |
| 102       | Priya Patel  | 21  | 45 Lake Ave, Mumbai | 2023 |

**Table 5: `Enrollment_3NF`** (unchanged)

| StudentID | CourseID |
|-----------|----------|
| 101       | 1        |
| 101       | 6        |
| 102       | 3        |

✅ All transitive dependencies removed. Tables are now in **3NF**.

---

## 4.6 Boyce-Codd Normal Form (BCNF)

### Rule:
> A table is in **BCNF** if:
> - It is in **3NF**, AND
> - For every functional dependency **X → Y**, **X must be a superkey** (a candidate key or a superset of a candidate key).

### BCNF Violation Identified:

Consider `Instructor_3NF`:

```
Functional Dependencies:
  InstructorID → InstructorName, DeptID     (InstructorID is key — OK)
  DeptID       → DeptName                   (But DeptID is not a candidate key in Instructor table — VIOLATION if DeptName is included)
```

More specifically, imagine a scenario where **one instructor can also determine the department** (i.e., `InstructorID → DeptID` and `DeptID → DeptName`). Since `DeptID` is not a candidate key in `Instructor_3NF` yet `DeptID → DeptName` forms a valid FD — this can violate BCNF if DeptName were kept in the Instructor table.

Our 3NF schema already avoided this by separating `Department` into its own table. Let's verify via the `Course_3NF` table:

**Candidate Keys of `Course_3NF`:** `{CourseID}`  
**All FDs:**
- `CourseID → CourseName, CourseDuration, DeptID, InstructorID` ✅ (CourseID is a superkey)

✅ `Course_3NF` is already in BCNF.

### Generalized BCNF Example for Student Management System

Suppose we introduce a rule: *"A student can only have one address per city"* — add `Email` which is also unique:

**Hypothetical `Student_BCNF` scenario:**
- Candidate Keys: `{StudentID}`, `{Email}` (both uniquely identify the student)
- FD: `StudentPhone → StudentCity` (Phone determines city, but Phone is not a candidate key)

**Before (BCNF violation):**

| StudentID | StudentName  | Email                | Phone       | City   |
|-----------|--------------|----------------------|-------------|--------|
| 101       | Rahul Sharma | rahul@example.com    | 9876543210  | Delhi  |
| 102       | Priya Patel  | priya@example.com    | 9123456789  | Mumbai |

> Here `Phone → City` but `Phone` is not a superkey → **BCNF Violation**

**After BCNF Decomposition:**

**Table: `Student_BCNF`**

| StudentID | StudentName  | Email                | Phone       |
|-----------|--------------|----------------------|-------------|
| 101       | Rahul Sharma | rahul@example.com    | 9876543210  |
| 102       | Priya Patel  | priya@example.com    | 9123456789  |

**Table: `PhoneCity_BCNF`**

| Phone       | City   |
|-------------|--------|
| 9876543210  | Delhi  |
| 9123456789  | Mumbai |

✅ Every determinant is now a candidate key. Tables are in **BCNF**.

> **Note:** Our actual CCD schema (Student, Course, Enrollment, Department, Instructor) is already in BCNF after 3NF decomposition, as every determinant in each table is its primary key.

---

## 4.7 Fourth Normal Form (4NF)

### Rule:
> A table is in **4NF** if:
> - It is in **BCNF**, AND
> - It has **no non-trivial multivalued dependencies** (MVDs) other than a candidate key.

### Definition:
A **Multivalued Dependency** `A →→ B` means that for each value of A, there is a set of values of B that is independent of other attributes.

### MVD Violation Identified:

Suppose students can have **multiple phone numbers** and also have **multiple hobbies**, and we store them in one table:

**Table: `Student_Extras`**

| StudentID | Phone       | Hobby      |
|-----------|-------------|------------|
| 101       | 9876543210  | Cricket    |
| 101       | 9876543210  | Chess      |
| 101       | 9998887770  | Cricket    |
| 101       | 9998887770  | Chess      |
| 102       | 9123456789  | Reading    |
| 102       | 9123456789  | Painting   |

**MVDs Present:**
- `StudentID →→ Phone`   (A student can have multiple phones)
- `StudentID →→ Hobby`   (A student can have multiple hobbies)
- These two sets are **independent** of each other → **4NF Violation**

### Pitfall (Problem):
- **Insertion Anomaly**: Adding a new hobby requires adding a new row for every phone number.
- **Deletion Anomaly**: Removing one hobby requires carefully deleting specific rows.
- **Redundancy**: Every combination of Phone × Hobby is stored.

### BEFORE (BCNF — Has multivalued dependency):

| **StudentID** | Phone       | Hobby   |
|---------------|-------------|---------|
| 101           | 9876543210  | Cricket |
| 101           | 9876543210  | Chess   |
| 101           | 9998887770  | Cricket |
| 101           | 9998887770  | Chess   |

### AFTER (4NF — Decomposed into two separate tables):

**Table 1: `Student_Phone_4NF`**

| StudentID | Phone       |
|-----------|-------------|
| 101       | 9876543210  |
| 101       | 9998887770  |
| 102       | 9123456789  |

**Table 2: `Student_Hobby_4NF`**

| StudentID | Hobby    |
|-----------|----------|
| 101       | Cricket  |
| 101       | Chess    |
| 102       | Reading  |
| 102       | Painting |

✅ Multivalued dependencies are now separated. Tables are in **4NF**.

---

## 4.8 Fifth Normal Form (5NF)

### Rule:
> A table is in **5NF** (also called **Project-Join Normal Form — PJNF**) if:
> - It is in **4NF**, AND
> - It cannot be decomposed further without **losing information** (every join dependency is implied by candidate keys).

### Definition:
A **Join Dependency** `*(R1, R2, ..., Rn)` on relation R means R can be reconstructed by joining R1, R2, ..., Rn without losing data.

### 5NF Violation Identified:

Consider a three-way relationship between **Student**, **Course**, and **Instructor** — where:
- A student is allowed to take a course only from a specific instructor.
- An instructor teaches a course only to specific students.

**Table: `Student_Course_Instructor_5NF_Before`**

| StudentID | CourseID | InstructorID |
|-----------|----------|--------------|
| 101       | 1        | 1            |
| 101       | 6        | 1            |
| 102       | 3        | 3            |
| 103       | 7        | 2            |

If this table has a **cyclic join dependency** (i.e., you cannot decompose it into two projections without losing data), it violates 5NF.

### Pitfall (Problem):
- Splitting into only two binary tables may produce spurious tuples on natural join.
- Data consistency is lost if the three-way constraint is not preserved.

### Decomposition Check:

Try decomposing into two tables:

**Projection 1:** `SC (StudentID, CourseID)`  
**Projection 2:** `CI (CourseID, InstructorID)`

Joining `SC ⋈ CI` on `CourseID`:

| StudentID | CourseID | InstructorID |
|-----------|----------|--------------|
| 101       | 1        | 1            |
| 101       | 6        | 1            |
| 102       | 3        | 3            |
| 103       | 7        | 2            |

In this case the join **does** reproduce the original table (no spurious tuples) — so our **Enrollment** table is safely in **5NF**.

### AFTER (5NF — Three separate relation tables when a cyclic constraint exists):

When a true three-way constraint exists (student-course-instructor rule), decompose into:

**Table 1: `SC_5NF`** (Student-Course)

| StudentID | CourseID |
|-----------|----------|
| 101       | 1        |
| 101       | 6        |
| 102       | 3        |

**Table 2: `CI_5NF`** (Course-Instructor)

| CourseID | InstructorID |
|----------|--------------|
| 1        | 1            |
| 3        | 3            |
| 6        | 1            |

**Table 3: `SI_5NF`** (Student-Instructor)

| StudentID | InstructorID |
|-----------|--------------|
| 101       | 1            |
| 102       | 3            |

The original relation can be reconstructed losslessly:  
`SC_5NF ⋈ CI_5NF ⋈ SI_5NF = Original Table` ✅

✅ All join dependencies are now implied by candidate keys. Tables are in **5NF**.

---

## 4.9 Summary of Normalization Steps

| Normal Form | Rule Applied                              | Tables After Decomposition                              |
|-------------|-------------------------------------------|---------------------------------------------------------|
| **UNF**     | Raw data, repeating groups                | `Student_Raw` (1 flat table)                            |
| **1NF**     | Atomic values, no repeating groups        | `Student_1NF` (one row per enrollment)                  |
| **2NF**     | Remove partial dependencies               | `Student_2NF`, `Course_2NF`, `Enrollment_2NF`           |
| **3NF**     | Remove transitive dependencies            | `Student_3NF`, `Course_3NF`, `Instructor_3NF`, `Department_3NF`, `Enrollment_3NF` |
| **BCNF**    | Every determinant is a candidate key      | Same as 3NF (already BCNF in our schema)                |
| **4NF**     | Remove multivalued dependencies           | `Student_Phone_4NF`, `Student_Hobby_4NF`                |
| **5NF**     | Remove join dependencies                  | `SC_5NF`, `CI_5NF`, `SI_5NF`                            |

### Final Normalized Schema (Matches Actual CCD Implementation):

```
department   (department_id PK, department_name)
instructor   (instructor_id PK, instructor_name, department_id FK→department)
courses      (course_id PK, course_name, course_duration, department_id FK→department, instructor_id FK→instructor)
student      (student_id PK, student_name, age, address, year)
enrollment   (student_id FK→student, course_id FK→courses)  — composite PK
```

---

---

# CHAPTER 5: TRANSACTIONS AND CONCURRENCY CONTROL

## 5.1 Introduction to Transactions

A **transaction** is a logical unit of work that consists of one or more SQL operations (INSERT, UPDATE, DELETE, SELECT) that are executed as a **single atomic unit**. A transaction either **completely succeeds** or **completely fails** — there is no in-between state.

### Why Transactions Are Needed:
- **Bank transfer**: Debit from one account, credit to another — both must succeed together.
- **Student enrollment**: Insert enrollment record + update seat count — must be atomic.
- **Grade update**: Academic integrity requires that grade changes are fully logged or fully rolled back.

### Transaction Syntax in MySQL:

```sql
START TRANSACTION;
  -- SQL statements
SAVEPOINT sp_name;
  -- More SQL statements
ROLLBACK TO sp_name;  -- OR ROLLBACK; OR COMMIT;
COMMIT;
```

---

## 5.2 ACID Properties

ACID stands for the four fundamental properties that guarantee database transactions are processed reliably:

### 5.2.1 Atomicity

> **"All or Nothing"**  
> A transaction is treated as a single unit. Either ALL operations succeed and are committed, or NONE of them are applied.

**Example in Student Management System:**  
Enrolling a student involves inserting into `enrollment` AND updating the course capacity. If the capacity update fails, the enrollment insert must also be rolled back.

```sql
START TRANSACTION;
  INSERT INTO enrollment (student_id, course_id) VALUES (101, 16);
  UPDATE courses SET seats_available = seats_available - 1 WHERE course_id = 16;
  -- If UPDATE fails → entire transaction is rolled back
COMMIT;
```

---

### 5.2.2 Consistency

> **"Data must remain valid before and after a transaction"**  
> A transaction brings the database from one valid state to another. All integrity constraints, rules, and cascades must hold.

**Example:**  
If a constraint says `age BETWEEN 16 AND 100`, any transaction that tries to insert `age = 5` must be rejected, keeping the database consistent.

```sql
-- This will fail due to CHECK constraint → database stays consistent
INSERT INTO student (student_id, student_name, age, address, year)
VALUES (999, 'Test Student', 5, 'Unknown', 2024);
-- ERROR: CHECK constraint violation — transaction rolled back
```

---

### 5.2.3 Isolation

> **"Concurrent transactions do not interfere with each other"**  
> Changes made by a transaction are not visible to other transactions until it is committed.

| Isolation Level     | Dirty Read | Non-Repeatable Read | Phantom Read |
|---------------------|------------|---------------------|--------------|
| READ UNCOMMITTED    | Possible   | Possible            | Possible     |
| READ COMMITTED      | Prevented  | Possible            | Possible     |
| REPEATABLE READ     | Prevented  | Prevented           | Possible     |
| SERIALIZABLE        | Prevented  | Prevented           | Prevented    |

**MySQL Default:** `REPEATABLE READ`

```sql
-- Session A: Begins a transaction
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
  SELECT * FROM student WHERE student_id = 101;
  -- Session B updates student 101 age here
  SELECT * FROM student WHERE student_id = 101;
  -- Same result as first SELECT (isolation prevents dirty reads)
COMMIT;
```

---

### 5.2.4 Durability

> **"Committed data persists even after system failure"**  
> Once a transaction is committed, its effects are permanently recorded (written to disk via write-ahead logging). Even a power failure cannot undo a committed transaction.

```sql
START TRANSACTION;
  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (201, 'Sneha Roy', 22, '8 Civil Lines, Jaipur', 2024);
COMMIT;
-- Even if the server crashes NOW, Sneha Roy's record is permanently saved.
```

---

## 5.3 Transaction States

The lifecycle of a transaction passes through the following states:

```
[Active] ──→ [Partially Committed] ──→ [Committed]
   │                                         ↑
   │              [Failed] ──────────→ [Aborted/Rolled Back]
   └────────────────────────────────────────→
```

| State                  | Description                                                             |
|------------------------|-------------------------------------------------------------------------|
| **Active**             | Transaction has started and SQL operations are being executed.          |
| **Partially Committed**| Last operation executed; changes not yet written to disk.               |
| **Committed**          | All operations complete; changes permanently saved to database.         |
| **Failed**             | An error occurred during execution; normal execution cannot proceed.    |
| **Aborted / Rolled Back** | Transaction failed; all changes undone; database restored to prior state. |
| **Terminated**         | Transaction either committed or aborted; ends its lifecycle.            |

---

## 5.4 SQL Transactions — Practical Examples

### Transaction 1: Enroll a New Student

**Scenario:** Add a new student (Meera Joshi) and enroll her in Database Systems (course_id = 16).

```sql
-- ================================================================
-- TRANSACTION 1: Student Registration and Course Enrollment
-- ================================================================
START TRANSACTION;

  -- Step 1: Insert the new student
  INSERT INTO student (student_id, student_name, age, address, year)
  VALUES (201, 'Meera Joshi', 20, '22 Brigade Road, Bangalore', 2024);

  -- Step 2: Save progress after student insertion
  SAVEPOINT after_student_insert;

  -- Step 3: Enroll the student in Database Systems
  INSERT INTO enrollment (student_id, course_id)
  VALUES (201, 16);

  -- Step 4: Verify the enrollment
  SELECT s.student_name, c.course_name
  FROM student s
  JOIN enrollment e ON s.student_id = e.student_id
  JOIN courses c ON e.course_id = c.course_id
  WHERE s.student_id = 201;

COMMIT;
```

**Sample Output:**

| student_name | course_name      |
|--------------|------------------|
| Meera Joshi  | Database Systems |

---

### Transaction 2: Update Student Address with Savepoint and Partial Rollback

**Scenario:** Update address for student 101. Midway, an erroneous second update is made and rolled back using SAVEPOINT.

```sql
-- ================================================================
-- TRANSACTION 2: Update with SAVEPOINT and ROLLBACK TO SAVEPOINT
-- ================================================================
START TRANSACTION;

  -- Step 1: Correct address update
  UPDATE student
  SET address = '55 Nehru Place, New Delhi'
  WHERE student_id = 101;

  SAVEPOINT address_checkpoint;

  -- Step 2: Erroneous additional update (wrong student)
  UPDATE student
  SET address = 'WRONG ADDRESS'
  WHERE student_id = 102;

  -- Step 3: Rollback only to the savepoint (undo step 2)
  ROLLBACK TO address_checkpoint;

  -- Step 4: Verify the correct state
  SELECT student_id, student_name, address
  FROM student
  WHERE student_id IN (101, 102);

COMMIT;
```

**Sample Output:**

| student_id | student_name | address                    |
|------------|--------------|----------------------------|
| 101        | Rahul Sharma | 55 Nehru Place, New Delhi  |
| 102        | Priya Patel  | 45 Lake Ave, Mumbai        |

> ✅ Student 101's address is updated. Student 102's address is **unchanged** because ROLLBACK TO SAVEPOINT undid only the erroneous step.

---

### Transaction 3: Delete a Course and Handle Enrollment Cascade

**Scenario:** Remove an outdated course (World History II, course_id = 20) and simultaneously remove all related enrollments.

```sql
-- ================================================================
-- TRANSACTION 3: Cascade Delete of Course and its Enrollments
-- ================================================================
START TRANSACTION;

  SAVEPOINT before_deletion;

  -- Step 1: Delete all enrollments for the course first (to avoid FK violation)
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
```

**Sample Output after Transaction:**

| (enrollment query) |
|---------------------|
| (Empty set — no orphan enrollments) |

| (courses query) |
|-----------------|
| (Empty set — course deleted) |

> ⚠️ If any error occurs in Step 2, use `ROLLBACK TO before_deletion` to undo both deletes.

---

### Transaction 4: Transfer a Student from One Course to Another

**Scenario:** Student 103 wants to drop Electronics I (course_id = 12) and enroll in Computer Networks (course_id = 11).

```sql
-- ================================================================
-- TRANSACTION 4: Course Transfer (Drop + Re-enroll)
-- ================================================================
START TRANSACTION;

  -- Step 1: Save state before any change
  SAVEPOINT before_transfer;

  -- Step 2: Drop the old course enrollment
  DELETE FROM enrollment
  WHERE student_id = 103 AND course_id = 12;

  -- Step 3: Add new course enrollment
  INSERT INTO enrollment (student_id, course_id)
  VALUES (103, 11);

  -- Step 4: Verify the transfer
  SELECT s.student_name, c.course_name
  FROM student s
  JOIN enrollment e ON s.student_id = e.student_id
  JOIN courses c ON e.course_id = c.course_id
  WHERE s.student_id = 103;

  -- Step 5: If anything is wrong, rollback everything
  -- ROLLBACK TO before_transfer;

COMMIT;
```

**Sample Output (After Transfer):**

| student_name | course_name       |
|--------------|-------------------|
| Ankit Verma  | Power Systems     |
| Ankit Verma  | Computer Networks |

> ✅ The student is now enrolled in Computer Networks instead of Electronics I.

---

### Transaction 5: Bulk Update of Course Duration with Rollback on Error

**Scenario:** Update all CS department courses (dept_id = 1) to 12-month duration. If any affected course count is unexpected, rollback.

```sql
-- ================================================================
-- TRANSACTION 5: Bulk Update with Validation and Conditional Rollback
-- ================================================================
START TRANSACTION;

  -- Step 1: Record original state for audit
  SELECT course_id, course_name, course_duration
  FROM courses
  WHERE department_id = 1;

  SAVEPOINT before_bulk_update;

  -- Step 2: Perform bulk update
  UPDATE courses
  SET course_duration = '12 months'
  WHERE department_id = 1;

  -- Step 3: Check how many rows were affected
  SELECT ROW_COUNT() AS rows_updated;

  -- Step 4: Verify results
  SELECT course_id, course_name, course_duration
  FROM courses
  WHERE department_id = 1;

  -- Step 5: If rows_updated is unexpected, rollback
  -- ROLLBACK TO before_bulk_update;

  -- Otherwise, commit the changes
COMMIT;
```

**Sample Output (Before Update):**

| course_id | course_name                  | course_duration |
|-----------|------------------------------|-----------------|
| 1         | Intro to Computer Science    | 6 months        |
| 2         | Digital Logic Design         | 6 months        |
| 6         | Data Structures & Algorithms | 6 months        |
| 11        | Computer Networks            | 6 months        |
| 16        | Database Systems             | 6 months        |

**Sample Output (After Update):**

| course_id | course_name                  | course_duration |
|-----------|------------------------------|-----------------|
| 1         | Intro to Computer Science    | 12 months       |
| 2         | Digital Logic Design         | 12 months       |
| 6         | Data Structures & Algorithms | 12 months       |
| 11        | Computer Networks            | 12 months       |
| 16        | Database Systems             | 12 months       |

---

## 5.5 Concurrency Control

### 5.5.1 What is Concurrency?

When multiple transactions execute **simultaneously** (concurrently), problems can arise if they access the same data without proper control:

| Problem               | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| **Dirty Read**        | T1 reads uncommitted data written by T2; if T2 rolls back, T1 has wrong data. |
| **Lost Update**       | T1 and T2 both read a value, each modifies it; one update overwrites the other. |
| **Non-Repeatable Read** | T1 reads a row twice; T2 modifies it in between — T1 sees different values. |
| **Phantom Read**      | T1 reads a set of rows twice; T2 inserts/deletes rows in between — T1 sees ghosts. |

### 5.5.2 Concurrency Control Techniques

| Technique            | Mechanism                                                      |
|----------------------|----------------------------------------------------------------|
| **Locking**          | Transactions acquire locks before reading/writing data.       |
| **Timestamp Ordering** | Transactions ordered by timestamp; older transactions go first. |
| **MVCC**             | Multiple versions of data kept simultaneously (MySQL InnoDB). |

---

### 5.5.3 Example: Pessimistic Locking with SELECT ... FOR UPDATE

**Scenario:** Two administrators try to enroll students in the same course simultaneously. We use `SELECT ... FOR UPDATE` to prevent a **Lost Update** on the enrollment count.

```sql
-- ================================================================
-- CONCURRENCY CONTROL: Pessimistic Lock using SELECT FOR UPDATE
-- Session A: Admin enrolling Student 201 in course 16
-- ================================================================
-- SESSION A starts first and acquires a row-level lock
START TRANSACTION;  -- Session A

  -- Acquire exclusive lock on course row (prevents Session B from modifying it)
  SELECT course_id, course_name, seats_available
  FROM courses
  WHERE course_id = 16
  FOR UPDATE;

  -- Session B tries same SELECT FOR UPDATE here → it WAITS (blocked by lock)

  -- Session A proceeds with enrollment
  INSERT INTO enrollment (student_id, course_id)
  VALUES (201, 16);

  -- Update available seats
  UPDATE courses
  SET seats_available = seats_available - 1
  WHERE course_id = 16;

COMMIT;  -- Lock is released; Session B can now proceed

-- ================================================================
-- SESSION B: Admin enrolling Student 202 in course 16 (runs after A commits)
-- ================================================================
START TRANSACTION;  -- Session B

  SELECT course_id, course_name, seats_available
  FROM courses
  WHERE course_id = 16
  FOR UPDATE;

  -- Now Session B sees the UPDATED seats_available (after Session A committed)
  INSERT INTO enrollment (student_id, course_id)
  VALUES (202, 16);

  UPDATE courses
  SET seats_available = seats_available - 1
  WHERE course_id = 16;

COMMIT;
```

**Why This Works:**
- `SELECT ... FOR UPDATE` places an **exclusive row-level lock** on the selected rows.
- Session B cannot proceed until Session A commits and releases the lock.
- This prevents the **Lost Update** problem where both sessions read the same `seats_available`, both decrement it independently, resulting in only one decrement persisted.

---

### 5.5.4 Example: Table-Level Locking with LOCK TABLE

**Scenario:** During batch grade processing (end of semester), we want to **lock the entire enrollment table** to prevent any student from adding/dropping courses while grades are being finalized.

```sql
-- ================================================================
-- CONCURRENCY CONTROL: Table-Level Lock using LOCK TABLES
-- ================================================================

-- Acquire exclusive WRITE lock on enrollment and READ lock on student/courses
LOCK TABLES
  enrollment WRITE,
  student    READ,
  courses    READ;

  -- Only this session can read/write enrollment during this block
  -- All other sessions attempting to access enrollment will WAIT

  -- Example batch operation: Finalize all enrollments for 2024
  UPDATE enrollment
  SET status = 'FINALIZED'
  WHERE YEAR(enrollment_date) = 2024;

  -- Audit log: Count finalized enrollments
  SELECT COUNT(*) AS finalized_count
  FROM enrollment
  WHERE status = 'FINALIZED';

-- Release all locks
UNLOCK TABLES;
```

**Sample Output:**

| finalized_count |
|-----------------|
| 47              |

> ⚠️ `LOCK TABLES` bypasses the transaction manager in MySQL. It is best used for administrative maintenance tasks. For application-level concurrency, prefer `SELECT ... FOR UPDATE` within transactions.

**Key Differences:**

| Feature               | `SELECT ... FOR UPDATE`        | `LOCK TABLE`                          |
|-----------------------|--------------------------------|---------------------------------------|
| **Lock Granularity**  | Row-level lock                 | Table-level lock                      |
| **Used With**         | Inside a transaction           | Outside transaction (session-level)   |
| **Performance**       | Higher concurrency             | Lower concurrency (blocks all users)  |
| **Use Case**          | OLTP — frequent small updates  | Batch/admin operations                |
| **Automatic Release** | On COMMIT / ROLLBACK           | On UNLOCK TABLES or session end       |

---

## 5.6 Summary — Transactions & Concurrency

| Concept             | Description                                                              |
|---------------------|--------------------------------------------------------------------------|
| **Transaction**     | A logical unit of work; group of SQL statements executed atomically.    |
| **ACID**            | Atomicity, Consistency, Isolation, Durability — guarantee reliability.  |
| **START TRANSACTION** | Marks the beginning of a transaction.                                 |
| **SAVEPOINT**       | Creates a named checkpoint within a transaction for partial rollback.   |
| **ROLLBACK**        | Undoes all changes made since the transaction started (or a savepoint). |
| **COMMIT**          | Permanently saves all changes made in the transaction.                  |
| **SELECT FOR UPDATE** | Acquires an exclusive row-level lock for concurrency control.         |
| **LOCK TABLE**      | Acquires a table-level lock for administrative/batch operations.        |

---

*End of Chapter 4 and Chapter 5*  
*Student Management System — Centralized College Database*  
*DBMS Mini Project Report*
