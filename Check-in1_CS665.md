**CS 665 Semester Project**

Project Check-in 1: Scope, Schema, and Strategy

Sricharan Cherepally - C986X996 | Fall 2026 | Project: SkillSwap, a peer-to-peer student tutoring app (Android)

# **1\. Problem Definition and Mobile Scope**

**Platform:** Android app, with SQLite as the on-device database.

**Problem:** Students often struggle with one skill while being strong at another, but there is no easy way to find a classmate who can help. Tutoring centers have limited hours, and asking around in group chats is hit or miss. SkillSwap lets a student post skills they can teach (for example "SQL Basics" or "Python") and skills they want to learn, and then automatically matches tutors with learners who want the same skill.

**Scope for the semester:** The app focuses on three things: student profiles, posting skills to teach or learn, and an automatic match list that shows who can help whom. I am leaving out payments, ratings and reviews, in-app chat, video calls, and GPS-based search. Appointment scheduling is a stretch goal that I will only add if the core features are working. Keeping the scope small leaves time for the database work, which is the main goal of the course.

# **2\. Initial Database Design**

The first version uses two tables on purpose. I expect to expand and normalize it in Check-in 2, where I plan to split out a separate Skills table, a tutor-skill junction table, and later an Appointments table.

| **Table** | **Columns**                                                                               |
| --------- | ----------------------------------------------------------------------------------------- |
| Student   | student_id (PK), full_name, email, major                                                  |
| SkillPost | post_id (PK), student_id (FK), post_type, skill_name, skill_level, available_days, status |

- **Primary key of Student:** student_id
- **Primary key of SkillPost:** post_id
- **Foreign key:** SkillPost.student_id references Student.student_id. This is a one-to-many link: one student can make many skill posts. ON DELETE CASCADE removes a student's posts when the student is deleted.
- **How the two roles are stored:** post_type is either TEACH or LEARN, so a single table holds both what a student offers and what a student requests. Matching a tutor to a learner means joining SkillPost to itself on skill_name (a self-join), then joining to Student to get names.

## **SQL (CREATE TABLE statements)**

CREATE TABLE Student (

student_id INTEGER PRIMARY KEY AUTOINCREMENT,

full_name TEXT NOT NULL,

email TEXT NOT NULL UNIQUE,

major TEXT

);

CREATE TABLE SkillPost (

post_id INTEGER PRIMARY KEY AUTOINCREMENT,

student_id INTEGER NOT NULL,

post_type TEXT NOT NULL CHECK (post_type IN ('TEACH','LEARN')),

skill_name TEXT NOT NULL,

skill_level TEXT NOT NULL CHECK (skill_level IN ('Beginner','Intermediate','Advanced')),

available_days TEXT,

status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed')),

FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE

);

## **Sample data used for testing**

**Student**

| **student_id** | **full_name** | **email**                  | **major**        |
| -------------- | ------------- | -------------------------- | ---------------- |
| 1              | Aarav Mehta   | <aarav.mehta@example.edu>  | Computer Science |
| 2              | Priya Nair    | <priya.nair@example.edu>   | Mathematics      |
| 3              | Jordan Blake  | <jordan.blake@example.edu> | Business         |
| 4              | Maria Lopez   | <maria.lopez@example.edu>  | Mathematics      |
| 5              | Daniel Kim    | <daniel.kim@example.edu>   | Computer Science |

**SkillPost**

| **post_id** | **student_id** | **post_type** | **skill_name**  | **skill_level** | **available_days** | **status** |
| ----------- | -------------- | ------------- | --------------- | --------------- | ------------------ | ---------- |
| 1           | 1              | TEACH         | SQL Basics      | Advanced        | Mon,Wed            | open       |
| 2           | 2              | TEACH         | Python          | Intermediate    | Tue,Thu            | open       |
| 3           | 3              | LEARN         | SQL Basics      | Beginner        | Mon                | open       |
| 4           | 4              | LEARN         | Python          | Beginner        | Thu                | open       |
| 5           | 5              | LEARN         | SQL Basics      | Beginner        | Wed                | open       |
| 6           | 4              | TEACH         | Calculus I      | Advanced        | Fri                | open       |
| 7           | 3              | TEACH         | Excel           | Intermediate    | Tue                | open       |
| 8           | 2              | LEARN         | Calculus I      | Beginner        | Fri                | open       |
| 9           | 1              | LEARN         | Public Speaking | Beginner        | Thu                | open       |
| 10          | 5              | TEACH         | Python          | Beginner        | Mon                | closed     |
| 11          | 5              | LEARN         | Excel           | Beginner        | Tue                | open       |

**Known weaknesses:** This first design has problems that I am keeping on purpose and plan to fix when I normalize in Check-in 2. The skill_name is typed as free text and repeats across posts, so a typo like "Pyton" would break matching, and renaming a skill means updating many rows. The available_days column holds several values in one cell ("Mon,Wed"), which breaks first normal form. Teaching and learning requests are also mixed in one table even though they behave differently.

# **3\. Relational Algebra Queries**

Notation: S = Student, SP = SkillPost, and the usual join condition is S.student_id = SP.student_id. σ is selection, π is projection, ⋈ is join, ρ is rename, and − is set difference.

## **Q1. Open posts offering to teach SQL Basics**

π post_id, student_id, skill_level, available_days ( σ post_type = 'TEACH' ∧ skill_name = 'SQL Basics' ∧ status = 'open' (SP) )

**Result on sample data:** Returns post 1 (student 1, Advanced, Mon and Wed).

## **Q2. Names of students who can teach SQL Basics**

π full_name ( σ post_type = 'TEACH' ∧ skill_name = 'SQL Basics' ∧ status = 'open' ( S ⋈ SP ) )

**Result on sample data:** Returns Aarav Mehta.

## **Q3. Skills a given student wants to learn**

π skill_name ( σ full_name = 'Jordan Blake' ∧ post_type = 'LEARN' ( S ⋈ SP ) )

**Result on sample data:** Returns SQL Basics.

## **Q4. Automatic matches between tutors and learners (self-join)**

T = ρ T ( σ post_type = 'TEACH' ∧ status = 'open' (SP) )

L = ρ L ( σ post_type = 'LEARN' ∧ status = 'open' (SP) )

M = T ⋈ T.skill_name = L.skill_name ∧ T.student_id ≠ L.student_id L

π A.full_name, B.full_name, T.skill_name ( M ⋈ T.student_id = A.student_id ρ A (S) ⋈ L.student_id = B.student_id ρ B (S) )

**Result on sample data:** Returns five matches: Aarav→Jordan (SQL Basics), Aarav→Daniel (SQL Basics), Priya→Maria (Python), Maria→Priya (Calculus I), and Jordan→Daniel (Excel). Daniel's Python teaching post is closed, so it is not matched.

## **Q5. Skills people want to learn that nobody is offering (set difference)**

π skill_name ( σ post_type = 'LEARN' ∧ status = 'open' (SP) ) − π skill_name ( σ post_type = 'TEACH' ∧ status = 'open' (SP) )

**Result on sample data:** Returns Public Speaking, since Aarav wants to learn it but no open post teaches it.

Q2 and Q3 use the join through the foreign key. Q4 is the core feature of the app: it joins SkillPost to itself to pair a tutor's TEACH post with a learner's LEARN post for the same skill, then joins to Student twice to get both names. Q5 uses set difference to find unmet demand, which could later drive a "skills needed" screen. The complete SQL, including the sample data inserts and the SQL version of all five queries, is in the Appendix at the end of this document.

# **4\. AI Utilization Plan**

**Agents I plan to use:** Claude as my main tutor for concepts and for checking my reasoning, and an in-IDE assistant only for small syntax-level help while I write Android and SQL code.

## **Ground rules I am setting for myself**

1. For the schema and queries in later check-ins, I write the first draft myself and then ask AI to critique it, instead of asking AI to generate it.
2. I ask for explanations and hints before asking for full solutions.
3. I run and test every SQL query myself against sample data instead of trusting AI output.
4. I keep a log of my prompts and what I learned from each one, so I can show my process.

## **Example prompts**

- "Explain what a self-join is using a small table of employees and managers, then give me 3 practice problems without answers until I try them."
- "I wrote this relational algebra expression to match tutors with learners on the same skill. Can you tell me whether the rename and the join condition are correct without rewriting it? Give me a hint if it is wrong."
- "My SQL self-join returns a student matched with themselves. Walk me through how to figure out why instead of just fixing it."
- "Here is my two-table schema. What data problems could appear as more students and skills are added? Ask me guiding questions so I can find them myself."
- "Quiz me on primary keys, foreign keys, and one-to-many versus many-to-many relationships, and explain when a junction table is needed."

## **How this builds self-reliance**

I want to use AI to understand why something works, so that I can write and debug queries on my own later, including when I have to bypass the ORM layer in Check-in 3 and read the underlying SQL.

# **Appendix: Complete SQL (schema, sample data, and queries)**

\-- CS665 Project Check-in 1: SkillSwap (peer-to-peer student tutoring, Android / SQLite)

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS SkillPost;

DROP TABLE IF EXISTS Student;

CREATE TABLE Student (

student_id INTEGER PRIMARY KEY AUTOINCREMENT,

full_name TEXT NOT NULL,

email TEXT NOT NULL UNIQUE,

major TEXT

);

CREATE TABLE SkillPost (

post_id INTEGER PRIMARY KEY AUTOINCREMENT,

student_id INTEGER NOT NULL,

post_type TEXT NOT NULL CHECK (post_type IN ('TEACH','LEARN')),

skill_name TEXT NOT NULL,

skill_level TEXT NOT NULL CHECK (skill_level IN ('Beginner','Intermediate','Advanced')),

available_days TEXT,

status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed')),

FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE

);

\-- Sample data

INSERT INTO Student (full_name, email, major) VALUES

('Aarav Mehta', '<aarav.mehta@example.edu>', 'Computer Science'),

('Priya Nair', '<priya.nair@example.edu>', 'Mathematics'),

('Jordan Blake', '<jordan.blake@example.edu>', 'Business'),

('Maria Lopez', '<maria.lopez@example.edu>', 'Mathematics'),

('Daniel Kim', '<daniel.kim@example.edu>', 'Computer Science');

INSERT INTO SkillPost (student_id, post_type, skill_name, skill_level, available_days, status) VALUES

(1,'TEACH','SQL Basics', 'Advanced', 'Mon,Wed', 'open'),

(2,'TEACH','Python', 'Intermediate', 'Tue,Thu', 'open'),

(3,'LEARN','SQL Basics', 'Beginner', 'Mon', 'open'),

(4,'LEARN','Python', 'Beginner', 'Thu', 'open'),

(5,'LEARN','SQL Basics', 'Beginner', 'Wed', 'open'),

(4,'TEACH','Calculus I', 'Advanced', 'Fri', 'open'),

(3,'TEACH','Excel', 'Intermediate', 'Tue', 'open'),

(2,'LEARN','Calculus I', 'Beginner', 'Fri', 'open'),

(1,'LEARN','Public Speaking', 'Beginner', 'Thu', 'open'),

(5,'TEACH','Python', 'Beginner', 'Mon', 'closed'),

(5,'LEARN','Excel', 'Beginner', 'Tue', 'open');

\-- Q1: open posts offering to teach SQL Basics

SELECT post_id, student_id, skill_level, available_days

FROM SkillPost

WHERE post_type = 'TEACH' AND skill_name = 'SQL Basics' AND status = 'open';

\-- Q2: names of students who can teach SQL Basics

SELECT s.full_name

FROM Student s JOIN SkillPost sp ON s.student_id = sp.student_id

WHERE sp.post_type = 'TEACH' AND sp.skill_name = 'SQL Basics' AND sp.status = 'open';

\-- Q3: skills a given student wants to learn

SELECT sp.skill_name

FROM Student s JOIN SkillPost sp ON s.student_id = sp.student_id

WHERE s.full_name = 'Jordan Blake' AND sp.post_type = 'LEARN';

\-- Q4: automatic matches (tutor, learner, skill) using a self-join on SkillPost

SELECT tutor.full_name AS tutor_name, learner.full_name AS learner_name, t.skill_name

FROM SkillPost t

JOIN SkillPost l ON t.skill_name = l.skill_name AND t.student_id <> l.student_id

JOIN Student tutor ON t.student_id = tutor.student_id

JOIN Student learner ON l.student_id = learner.student_id

WHERE t.post_type = 'TEACH' AND t.status = 'open'

AND l.post_type = 'LEARN' AND l.status = 'open';

\-- Q5: skills people want to learn that nobody is offering (set difference)

SELECT skill_name FROM SkillPost WHERE post_type = 'LEARN' AND status = 'open'

EXCEPT

SELECT skill_name FROM SkillPost WHERE post_type = 'TEACH' AND status = 'open';