-- Step 6: Movies rated >= 0.5 stars above their genre's overall average rating (20+ ratings).
-- Predicted rows: 100 to 200 movie-genre pairs.
-- Row counts after each step (20+ ratings):
--   movie_stats             939   movies with 20+ ratings
--   genre_stats              19   one row per genre
--   movie_genre_comparison 1837   each movie paired with each of its genres (~2 genres per movie)
--   final SELECT            151   pairs at least 0.5 above their genre = 99 different movies

WITH movie_stats AS (
    -- Step 1: Calculate count and mean rating for every movie with >= 20 ratings
    SELECT 
        m.movie_id,
        m.title,
        COUNT(r.rating) AS num_ratings,
        AVG(r.rating) AS movie_mean
    FROM movies m
    JOIN ratings r ON m.movie_id = r.movie_id
    GROUP BY m.movie_id, m.title
    HAVING COUNT(r.rating) >= 30
),
genre_stats AS (
    -- Step 2: Calculate overall mean rating per genre across all associated ratings
    SELECT 
        mg.genre,
        AVG(r.rating) AS genre_mean
    FROM movie_genres mg
    JOIN ratings r ON mg.movie_id = r.movie_id
    GROUP BY mg.genre
),
movie_genre_comparison AS (
    -- Step 3: Pair qualifying movies with each of their genres and compute delta
    SELECT 
        ms.movie_id,
        ms.title,
        mg.genre,
        ROUND(ms.movie_mean, 3) AS movie_mean,
        ROUND(gs.genre_mean, 3) AS genre_mean,
        ROUND(ms.movie_mean - gs.genre_mean, 3) AS diff_from_genre,
        ms.num_ratings
    FROM movie_stats ms
    JOIN movie_genres mg ON ms.movie_id = mg.movie_id
    JOIN genre_stats gs ON mg.genre = gs.genre
)
-- Step 4: Extract movie-genre pairs outperforming their genre by at least 0.5 stars
SELECT 
    movie_id,
    title,
    genre,
    movie_mean,
    genre_mean,
    diff_from_genre,
    num_ratings
FROM movie_genre_comparison
WHERE diff_from_genre >= 0.5
ORDER BY diff_from_genre DESC, title ASC;

-- Step 6(c): Equivalent nested subquery version (without CTEs):
-- SELECT
--     ms.movie_id,
--     ms.title,
--     mg.genre,
--     ROUND(ms.movie_mean, 3) AS movie_mean,
--     ROUND(gs.genre_mean, 3) AS genre_mean,
--     ROUND(ms.movie_mean - gs.genre_mean, 3) AS diff_from_genre,
--     ms.num_ratings
-- FROM (
--     SELECT m.movie_id, m.title, COUNT(r.rating) AS num_ratings, AVG(r.rating) AS movie_mean
--     FROM movies m JOIN ratings r ON m.movie_id = r.movie_id
--     GROUP BY m.movie_id, m.title
--     HAVING COUNT(r.rating) >= 20
-- ) ms
-- JOIN movie_genres mg ON ms.movie_id = mg.movie_id
-- JOIN (
--     SELECT mg2.genre, AVG(r2.rating) AS genre_mean
--     FROM movie_genres mg2 JOIN ratings r2 ON mg2.movie_id = r2.movie_id
--     GROUP BY mg2.genre
-- ) gs ON mg.genre = gs.genre
-- WHERE ROUND(ms.movie_mean - gs.genre_mean, 3) >= 0.5
-- ORDER BY diff_from_genre DESC, ms.title ASC;
