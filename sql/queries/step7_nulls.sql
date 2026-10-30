-- Step 7a: Count NULL values per nullable column in the database.
-- Every column in users, ratings, genres, occupations, and movie_genres is NOT NULL.
-- Only movies.release_date (1 row: movie 267) and movies.imdb_url (3 rows: 267, 1358, 1359) allow NULL.
SELECT
    COUNT(*) - COUNT(movie_id)     AS movie_id_nulls,
    COUNT(*) - COUNT(title)        AS title_nulls,
    COUNT(*) - COUNT(release_date) AS release_date_nulls,
    COUNT(*) - COUNT(imdb_url)     AS imdb_url_nulls
FROM movies;

-- Inspect the specific rows with NULLs
SELECT movie_id, title, release_date, imdb_url
FROM movies
WHERE release_date IS NULL OR imdb_url IS NULL;

-- Step 7b: Three-valued logic and the NOT IN trap vs. NOT EXISTS fix.
-- 1. NOT IN trap: returns 0 rows because movie 267's NULL release_date makes x != NULL evaluate to UNKNOWN.
SELECT COUNT(*) AS not_in_count
FROM movies
WHERE release_date NOT IN (
    SELECT release_date FROM movies WHERE imdb_url IS NULL
);

-- 2. NOT EXISTS fix: returns 1,680 rows, the real answer.
SELECT COUNT(*) AS not_exists_count
FROM movies m
WHERE NOT EXISTS (
    SELECT 1 FROM movies x
    WHERE x.imdb_url IS NULL AND x.release_date = m.release_date
);
