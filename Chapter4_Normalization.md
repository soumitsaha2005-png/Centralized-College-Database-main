# CHAPTER 4: ANALYZING THE PITFALLS, IDENTIFYING THE DEPENDENCIES, AND APPLYING NORMALIZATIONS

## 4.1 Analyse the Pitfalls in Relations

When data is collected and stored in an initial unnormalized format (UNF), it combines all related information into a single table. This causes several design pitfalls:

1. **Data Redundancy:** The same information (like department name or instructor details) is repeated multiple times, wasting storage space.
2. **Insertion Anomaly:** We cannot insert information about a new course until a student enrolls in it, or we cannot insert a new department until a course is assigned to it.
3. **Update Anomaly:** If a department changes its name, we must update multiple rows. Missing even one row leads to inconsistent data.
4. **Deletion Anomaly:** If the only student enrolled in a specific course is deleted, the information about that course and its instructor is also completely lost.

**Unnormalized Table (UNF): `Student_Raw`**

| StudentID | StudentName | CourseIDs | CourseNames | DeptID | DeptName | InstructorID | InstructorName |
|-----------|-------------|-----------|-------------|--------|----------|--------------|----------------|
| 101 | Rahul Sharma | 1, 2 | OS, DBMS | 10 | Comp. Sci | 501 | Dr. Alan |
| 102 | Priya Patel | 3 | Networks | 10 | Comp. Sci | 502 | Dr. Ada |
| 103 | Amit Kumar | 1, 4 | OS, AI | 10 | Comp. Sci | 501, 503 | Dr. Alan, Dr. John |

## 4.2 First Normal Form (1NF)

### 4.2.1 Identify Dependency
A table is in 1NF if it contains only atomic (indivisible) values and no repeating groups. 
In the UNF table, the `CourseIDs`, `CourseNames`, and instructor details contain multiple values in a single cell (e.g., "1, 2" for Rahul). 
- **Dependency Causing Problem:** Multi-valued attributes prevent us from uniquely identifying individual enrollments and extracting specific course data easily.

### 4.2.2 Apply Normalization

**BEFORE (UNF Table):**
Includes repeating groups like `1, 2` for `CourseIDs`.

**AFTER (1NF Table): `Student_1NF`**
We separate the repeating groups into individual rows.

| StudentID | StudentName | CourseID | CourseName | DeptID | DeptName | InstructorID | InstructorName |
|-----------|-------------|----------|------------|--------|----------|--------------|----------------|
| 101 | Rahul Sharma | 1 | OS | 10 | Comp. Sci | 501 | Dr. Alan |
| 101 | Rahul Sharma | 2 | DBMS | 10 | Comp. Sci | 501 | Dr. Alan |
| 102 | Priya Patel | 3 | Networks | 10 | Comp. Sci | 502 | Dr. Ada |
| 103 | Amit Kumar | 1 | OS | 10 | Comp. Sci | 501 | Dr. Alan |
| 103 | Amit Kumar | 4 | AI | 10 | Comp. Sci | 503 | Dr. John |

## 4.3 Second Normal Form (2NF)

### 4.3.1 Identify Dependency
A table is in 2NF if it is in 1NF and contains no partial dependencies. 
In `Student_1NF`, the primary key is a composite key: `{StudentID, CourseID}`.
- **Functional Dependencies:** 
  - `{StudentID} -> {StudentName}`
  - `{CourseID} -> {CourseName, DeptID, DeptName, InstructorID, InstructorName}`
- **Dependency Causing Problem:** The partial dependencies mean that attributes like `StudentName` only depend on part of the primary key (`StudentID`). This causes data redundancy (repeating student names) and update anomalies.

### 4.3.2 Apply Normalization

**BEFORE (1NF Table):**
A single table with partial dependencies on the composite key.

**AFTER (2NF Tables):**
We decompose the table into three separate tables based on the dependencies.

**Table 1: `Student`**
| StudentID | StudentName |
|-----------|-------------|
| 101 | Rahul Sharma |
| 102 | Priya Patel |
| 103 | Amit Kumar |

**Table 2: `Course`**
| CourseID | CourseName | DeptID | DeptName | InstructorID | InstructorName |
|----------|------------|--------|----------|--------------|----------------|
| 1 | OS | 10 | Comp. Sci | 501 | Dr. Alan |
| 2 | DBMS | 10 | Comp. Sci | 501 | Dr. Alan |
| 3 | Networks | 10 | Comp. Sci | 502 | Dr. Ada |
| 4 | AI | 10 | Comp. Sci | 503 | Dr. John |

**Table 3: `Enrollment`**
| StudentID | CourseID |
|-----------|----------|
| 101 | 1 |
| 101 | 2 |
| 102 | 3 |
| 103 | 1 |
| 103 | 4 |

## 4.4 Third Normal Form (3NF)

### 4.4.1 Identify Dependency
A table is in 3NF if it is in 2NF and contains no transitive dependencies (where a non-key attribute depends on another non-key attribute).
In the `Course` table, the primary key is `CourseID`.
- **Functional Dependencies:**
  - `{CourseID} -> {DeptID, InstructorID}`
  - `{DeptID} -> {DeptName}`
  - `{InstructorID} -> {InstructorName}`
- **Dependency Causing Problem:** The transitive dependencies (`CourseID -> DeptID -> DeptName` and `CourseID -> InstructorID -> InstructorName`) cause redundancy. For example, the department name "Comp. Sci" is repeated for every course in that department.

### 4.4.2 Apply Normalization

**BEFORE (2NF Course Table):**
Contains transitive dependencies for Department and Instructor names.

**AFTER (3NF Tables):**
We decompose the `Course` table further.

**Table 1: `Course_3NF`**
| CourseID | CourseName | DeptID | InstructorID |
|----------|------------|--------|--------------|
| 1 | OS | 10 | 501 |
| 2 | DBMS | 10 | 501 |
| 3 | Networks | 10 | 502 |
| 4 | AI | 10 | 503 |

**Table 2: `Department`**
| DeptID | DeptName |
|--------|----------|
| 10 | Comp. Sci |

**Table 3: `Instructor`**
| InstructorID | InstructorName | DeptID |
|--------------|----------------|--------|
| 501 | Dr. Alan | 10 |
| 502 | Dr. Ada | 10 |
| 503 | Dr. John | 10 |

*(The `Student` and `Enrollment` tables remain the same, as they are already in 3NF).*

## 4.5 Boyce-Codd Normal Form (BCNF)

### 4.5.1 Identify Dependency
A table is in BCNF if it is in 3NF, and for every functional dependency `X -> Y`, `X` is a candidate key (a superkey). BCNF is a stricter version of 3NF.
Let's assume a new rule: Students have Advisors, and each Advisor belongs exclusively to one Department. We have a table `Student_Advisor`.
- **Primary Key:** `{StudentID, DeptID}` (Assuming a student can have multiple advisors, but only one per department).
- **Functional Dependencies:** 
  - `{AdvisorID} -> {DeptID}` (An advisor determines the department).
- **Dependency Causing Problem:** The determinant `AdvisorID` is NOT a candidate key for the relation. This causes redundancy if the same advisor advises multiple students in the same department.

### 4.5.2 Apply Normalization

**BEFORE (3NF Table violating BCNF): `Student_Advisor`**
| StudentID | DeptID | AdvisorID |
|-----------|--------|-----------|
| 101 | 10 | A1 |
| 102 | 10 | A1 |

**AFTER (BCNF Tables):**

**Table 1: `Advises`**
| StudentID | AdvisorID |
|-----------|-----------|
| 101 | A1 |
| 102 | A1 |

**Table 2: `Advisor`**
| AdvisorID | DeptID |
|-----------|--------|
| A1 | 10 |

## 4.6 Fourth Normal Form (4NF)

### 4.6.1 Identify Dependency
A table is in 4NF if it is in BCNF and has no multivalued dependencies. A multivalued dependency occurs when there are two or more independent multi-valued facts about an entity.
Suppose we track a student's Phone Numbers and Hobbies in a single table `Student_Details`.
- **Primary Key:** `{StudentID, Phone, Hobby}`
- **Dependencies:** 
  - `{StudentID} ->> {Phone}`
  - `{StudentID} ->> {Hobby}`
- **Dependency Causing Problem:** Phone and Hobby are entirely independent of each other, but storing them together requires creating all possible combinations of phones and hobbies for a single student, leading to severe data redundancy and update anomalies.

### 4.6.2 Apply Normalization

**BEFORE (BCNF Table violating 4NF): `Student_Details`**
| StudentID | Phone | Hobby |
|-----------|-------|-------|
| 101 | 9876543210 | Reading |
| 101 | 9876543210 | Coding |
| 101 | 1234567890 | Reading |
| 101 | 1234567890 | Coding |

**AFTER (4NF Tables):**
We separate the independent multivalued attributes.

**Table 1: `Student_Phone`**
| StudentID | Phone |
|-----------|-------|
| 101 | 9876543210 |
| 101 | 1234567890 |

**Table 2: `Student_Hobby`**
| StudentID | Hobby |
|-----------|-------|
| 101 | Reading |
| 101 | Coding |

## 4.7 Fifth Normal Form (5NF)

### 4.7.1 Identify Dependency
A table is in 5NF (Project-Join Normal Form) if it is in 4NF and cannot be losslessly decomposed into smaller tables. It specifically addresses Join Dependencies, where joining smaller tables creates spurious (fake) records that didn't exist in the original table.
Suppose an Instructor teaches a Course, and a Student is assigned to that Instructor for that Course. 
- **Rule:** If a student takes a course, and an instructor teaches that course, the student must be taking it from that specific instructor. It forms a cyclical dependency between Student, Course, and Instructor.
- **Dependency Causing Problem:** Keeping them in one table or decomposing them incorrectly into two tables might lead to data loss or the creation of false relationships when joined back together (spurious tuples).

### 4.7.2 Apply Normalization

**BEFORE (4NF Table violating 5NF): `Student_Course_Instructor`**
| StudentID | CourseID | InstructorID |
|-----------|----------|--------------|
| 101 | 1 | 501 |

**AFTER (5NF Tables):**
We decompose the relationship into three distinct binary tables so that no spurious data is generated when rejoined.

**Table 1: `Student_Course` (Enrollment)**
| StudentID | CourseID |
|-----------|----------|
| 101 | 1 |

**Table 2: `Course_Instructor` (Teaches)**
| CourseID | InstructorID |
|----------|--------------|
| 1 | 501 |

**Table 3: `Student_Instructor` (Guides)**
| StudentID | InstructorID |
|-----------|--------------|
| 101 | 501 |

## Conclusion

Normalization is a crucial step in database design. By methodically applying these rules from 1NF to 5NF, we transformed an inefficient, error-prone flat file into a robust relational database. This process eliminates data redundancy, prevents insertion, update, and deletion anomalies, and ultimately ensures the data integrity, accuracy, and efficiency of the Student Management System.
