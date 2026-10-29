-- Q6: movies rated by at least one student but by no programmer.
-- Predicted rows: TODO (your guess)
-- Actual rows: 268
-- EXCEPT fits because the question is "set A minus set B": A = movies a student rated,
-- B = movies a programmer rated. UNION would give A or B, INTERSECT would give A and B.
SELECT movie_id FROM ratings JOIN users USING (user_id) WHERE occupation = 'student'
EXCEPT
SELECT movie_id FROM ratings JOIN users USING (user_id) WHERE occupation = 'programmer';
