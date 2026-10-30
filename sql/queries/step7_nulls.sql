-- Step 7a: Three-valued logic and NULL behavior in SQLite.
-- Demonstrates comparisons (=, !=, IS) and aggregations (COUNT(*), COUNT(col), AVG(col)).

-- 1. Three-valued logic: equality and inequality against NULL both yield UNKNOWN (falsy in WHERE).
-- Notice that both queries return 0 rows for movie 267.
SELECT movie_id, title, release_date
FROM movies
WHERE release_date = NULL;

SELECT movie_id, title, release_date
FROM movies
WHERE release_date != NULL;

-- 2. Only IS NULL and IS NOT NULL properly handle NULL in boolean evaluation.
SELECT movie_id, title, release_date
FROM movies
WHERE release_date IS NULL;

-- 3. Aggregations: COUNT(*) counts rows; COUNT(column) ignores NULLs; AVG ignores NULLs.
SELECT
    COUNT(*) AS total_movies,
    COUNT(release_date) AS movies_with_release_date,
    COUNT(*) - COUNT(release_date) AS null_release_dates
FROM movies;