-- Q2: mean rating per occupation, only occupations with at least 50 raters.
-- Predicted rows: TODO (your guess)
-- Actual rows: 7
-- Gap: 21 occupations exist, but only 7 have at least 50 raters; the other 14 are dropped.
-- WHERE filters individual ratings before grouping; here it has no row filter at all.
-- HAVING filters whole groups after aggregating, so "at least 50 raters" (a property of a
-- group, computed with COUNT(DISTINCT)) must be in HAVING. WHERE cannot see aggregates.
SELECT u.occupation, COUNT(DISTINCT r.user_id) AS raters, ROUND(AVG(r.rating), 3) AS mean_rating
FROM ratings r JOIN users u USING (user_id)
GROUP BY u.occupation
HAVING COUNT(DISTINCT r.user_id) >= 50
ORDER BY mean_rating DESC;
