-- Step 4, claim 3: every user has rated at least 20 movies.
-- LEFT JOIN so that a user with zero ratings would show up as 0, not vanish.
-- Expect: fewer_than_20 = 0.
SELECT MIN(n) AS fewest_ratings, SUM(n < 20) AS fewer_than_20
FROM (SELECT u.user_id, COUNT(r.movie_id) AS n
      FROM users u LEFT JOIN ratings r ON r.user_id = u.user_id
      GROUP BY u.user_id);
