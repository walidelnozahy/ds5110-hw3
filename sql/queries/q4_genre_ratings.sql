-- Q4: per genre, number of ratings and mean rating; then the sum of the counts vs 100,000.
-- Predicted rows: TODO (your guess)
-- Actual rows: 19 (one per genre, including 'unknown') + 1 total row
-- Gap: a movie in several genres is counted once per genre, so the genre counts add up to more
--      than 100,000 ratings. The total row shows the sum and how far it overshoots.
WITH g AS (
  SELECT mg.genre, COUNT(*) AS n_ratings, ROUND(AVG(r.rating), 3) AS mean_rating
  FROM ratings r JOIN movie_genres mg USING (movie_id)
  GROUP BY mg.genre
)
SELECT genre, n_ratings, mean_rating FROM g ORDER BY n_ratings DESC;

-- Sum of the genre counts against the 100,000 real ratings.
SELECT SUM(n_ratings) AS sum_of_genre_counts, 100000 AS real_ratings,
       SUM(n_ratings) - 100000 AS extra
FROM (SELECT COUNT(*) AS n_ratings
      FROM ratings r JOIN movie_genres mg USING (movie_id)
      GROUP BY mg.genre);
