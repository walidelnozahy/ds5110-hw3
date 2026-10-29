-- Q1: ten most-rated movies, ties handled deliberately.
-- Predicted rows: TODO (your guess)
-- Actual rows: 10
-- Gap: none. RANK() keeps every movie tied with 10th place, so ties could have given more than 10
--      rows, where LIMIT 10 would cut a tie arbitrarily. Here 10th place (429) is not tied.
WITH counts AS (
  SELECT m.movie_id, m.title, COUNT(*) AS n_ratings
  FROM ratings r JOIN movies m USING (movie_id)
  GROUP BY m.movie_id
), ranked AS (
  SELECT *, RANK() OVER (ORDER BY n_ratings DESC) AS rnk FROM counts
)
SELECT rnk, title, n_ratings FROM ranked WHERE rnk <= 10 ORDER BY rnk, title;
