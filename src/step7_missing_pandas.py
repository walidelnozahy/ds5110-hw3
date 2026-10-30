"""Step 7b: Demonstrate missing value semantics in pandas vs SQL."""

import sqlite3
import sys
from pathlib import Path
import pandas as pd

DB = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/movielens.db")

with sqlite3.connect(DB) as conn:
    movies_df = pd.read_sql("SELECT movie_id, title, release_date FROM movies", conn)

print("=== 1. Inspecting Missing Values in Pandas ===")
null_mask = movies_df["release_date"].isna()
null_movies = movies_df[null_mask]
print(f"Total rows in DataFrame: {len(movies_df)}")
print(f"Rows with null release_date (isna()): {len(null_movies)}")
print(null_movies)

print("\n=== 2. Equality Comparison with None / NaN in Python ===")
# In Python/Pandas, float('nan') == float('nan') is False, matching SQL's UNKNOWN semantics.
# However, filtering using df['col'] == None is bad practice and emits warnings.
print("Count matching via '== None':", (movies_df["release_date"] == None).sum())
print("Count matching via isna():", movies_df["release_date"].isna().sum())

print("\n=== 3. Summary Aggregations ===")
print("count() [non-null count]:", movies_df["release_date"].count())
print("size [total row count]:   ", movies_df["release_date"].size)