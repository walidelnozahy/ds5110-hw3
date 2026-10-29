-- Q3: users whose zip does not start with a digit.
-- Predicted rows: 1 (a single count row; the count itself is 18)
-- Actual rows: 1 (the count is 18)
-- Gap: none in rows; the answer is 18 users. GLOB '[0-9]*' matches zips starting with a digit; NOT GLOB finds the rest (Canadian codes).
-- If zip were INTEGER: a STRICT INTEGER column refuses text like 'T8H1N', so those users would
-- be rejected at load time and the count would be 0 (and zips like '02139' would lose their zero).
SELECT COUNT(*) AS users_with_non_digit_start FROM users WHERE zip NOT GLOB '[0-9]*';
