-- Reset only the dedicated teaching table; never run this in a business database.
CREATE DATABASE IF NOT EXISTS infra_index_lab;
USE infra_index_lab;
DROP TABLE IF EXISTS course_scores;

CREATE TABLE course_scores (
    id INT UNSIGNED NOT NULL,
    course_id INT UNSIGNED NOT NULL,
    score INT UNSIGNED NOT NULL,
    note VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Generate rows mechanically. The learner's task is to explain the query plans.
SET SESSION cte_max_recursion_depth = 20000;
INSERT INTO course_scores (id, course_id, score, note)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 20000
)
SELECT n, MOD(n, 1000), MOD(n, 101),
       RPAD(CONCAT('record-', n), 200, 'x')
FROM numbers;

ANALYZE TABLE course_scores;
SELECT COUNT(*) AS total_rows FROM course_scores;
SELECT COUNT(*) AS course_7_rows FROM course_scores WHERE course_id = 7;
SHOW INDEX FROM course_scores;
