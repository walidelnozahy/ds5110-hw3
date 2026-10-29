-- Step 4, claim 1: 100,000 ratings by 943 users on 1,682 movies.
-- Expect one row: 100000 | 943 | 1682. Distinct counts show who actually appears in ratings.
SELECT (SELECT COUNT(*) FROM ratings)                  AS ratings,
       (SELECT COUNT(*) FROM users)                    AS users,
       (SELECT COUNT(*) FROM movies)                   AS movies,
       (SELECT COUNT(DISTINCT user_id)  FROM ratings)  AS users_who_rated,
       (SELECT COUNT(DISTINCT movie_id) FROM ratings)  AS movies_rated;
