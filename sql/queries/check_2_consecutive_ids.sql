-- Step 4, claim 2: users and movies are numbered consecutively from 1.
-- If true, min is 1, max equals the count, and no id is skipped (max - count = 0).
SELECT 'users' AS tbl, MIN(user_id) AS min_id, MAX(user_id) AS max_id, COUNT(*) AS n,
       MAX(user_id) - COUNT(*) AS gaps
FROM users
UNION ALL
SELECT 'movies', MIN(movie_id), MAX(movie_id), COUNT(*), MAX(movie_id) - COUNT(*)
FROM movies;
