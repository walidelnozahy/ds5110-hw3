"""Step 7d: answer Q6 (movies rated by a student but no programmer) in pandas."""

import sqlite3
import sys
from pathlib import Path

import pandas as pd

DB = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/movielens.db")

with sqlite3.connect(DB) as conn:
    df = pd.read_sql(
        "SELECT r.movie_id, u.occupation FROM ratings r JOIN users u USING (user_id)", conn
    )

students = set(df.loc[df.occupation == "student", "movie_id"])
programmers = set(df.loc[df.occupation == "programmer", "movie_id"])
only_students = sorted(students - programmers)

print(f"movies rated by a student:    {len(students)}")
print(f"movies rated by a programmer: {len(programmers)}")
print(f"students but no programmer:   {len(only_students)}")
