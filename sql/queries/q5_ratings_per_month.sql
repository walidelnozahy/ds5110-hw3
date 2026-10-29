-- Q5: ratings per calendar month (timestamps are Unix seconds, UTC).
-- Predicted rows: TODO (your guess)
-- Actual rows: 8
-- Gap: the data runs 1997-09-19 to 1998-04-22, so months Sep 1997 .. Apr 1998 appear (8 rows),
--      and months with no ratings do not appear at all, because GROUP BY only sees existing rows.
SELECT strftime('%Y-%m', timestamp, 'unixepoch') AS month, COUNT(*) AS n_ratings
FROM ratings
GROUP BY month
ORDER BY month;
