-- CS665 Project Check-in 1: SkillSwap (peer-to-peer student tutoring, Android / SQLite)
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS SkillPost;
DROP TABLE IF EXISTS Student;

CREATE TABLE Student (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name  TEXT NOT NULL,
    email      TEXT NOT NULL UNIQUE,
    major      TEXT
);

CREATE TABLE SkillPost (
    post_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id     INTEGER NOT NULL,
    post_type      TEXT NOT NULL CHECK (post_type IN ('TEACH','LEARN')),
    skill_name     TEXT NOT NULL,
    skill_level    TEXT NOT NULL CHECK (skill_level IN ('Beginner','Intermediate','Advanced')),
    available_days TEXT,
    status         TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed')),
    FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE
);

-- Sample data
INSERT INTO Student (full_name, email, major) VALUES
 ('Aarav Mehta',  'aarav.mehta@example.edu',  'Computer Science'),
 ('Priya Nair',   'priya.nair@example.edu',   'Mathematics'),
 ('Jordan Blake', 'jordan.blake@example.edu', 'Business'),
 ('Maria Lopez',  'maria.lopez@example.edu',  'Mathematics'),
 ('Daniel Kim',   'daniel.kim@example.edu',   'Computer Science');

INSERT INTO SkillPost (student_id, post_type, skill_name, skill_level, available_days, status) VALUES
 (1,'TEACH','SQL Basics',      'Advanced',     'Mon,Wed', 'open'),
 (2,'TEACH','Python',          'Intermediate', 'Tue,Thu', 'open'),
 (3,'LEARN','SQL Basics',      'Beginner',     'Mon',     'open'),
 (4,'LEARN','Python',          'Beginner',     'Thu',     'open'),
 (5,'LEARN','SQL Basics',      'Beginner',     'Wed',     'open'),
 (4,'TEACH','Calculus I',      'Advanced',     'Fri',     'open'),
 (3,'TEACH','Excel',           'Intermediate', 'Tue',     'open'),
 (2,'LEARN','Calculus I',      'Beginner',     'Fri',     'open'),
 (1,'LEARN','Public Speaking', 'Beginner',     'Thu',     'open'),
 (5,'TEACH','Python',          'Beginner',     'Mon',     'closed'),
 (5,'LEARN','Excel',           'Beginner',     'Tue',     'open');

-- Q1: open posts offering to teach SQL Basics
SELECT post_id, student_id, skill_level, available_days
FROM SkillPost
WHERE post_type = 'TEACH' AND skill_name = 'SQL Basics' AND status = 'open';

-- Q2: names of students who can teach SQL Basics
SELECT s.full_name
FROM Student s JOIN SkillPost sp ON s.student_id = sp.student_id
WHERE sp.post_type = 'TEACH' AND sp.skill_name = 'SQL Basics' AND sp.status = 'open';

-- Q3: skills a given student wants to learn
SELECT sp.skill_name
FROM Student s JOIN SkillPost sp ON s.student_id = sp.student_id
WHERE s.full_name = 'Jordan Blake' AND sp.post_type = 'LEARN';

-- Q4: automatic matches (tutor, learner, skill) using a self-join on SkillPost
SELECT tutor.full_name AS tutor_name, learner.full_name AS learner_name, t.skill_name
FROM SkillPost t
JOIN SkillPost l   ON t.skill_name = l.skill_name AND t.student_id <> l.student_id
JOIN Student tutor   ON t.student_id = tutor.student_id
JOIN Student learner ON l.student_id = learner.student_id
WHERE t.post_type = 'TEACH' AND t.status = 'open'
  AND l.post_type = 'LEARN' AND l.status = 'open';

-- Q5: skills people want to learn that nobody is offering (set difference)
SELECT skill_name FROM SkillPost WHERE post_type = 'LEARN' AND status = 'open'
EXCEPT
SELECT skill_name FROM SkillPost WHERE post_type = 'TEACH' AND status = 'open';
