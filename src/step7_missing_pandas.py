"""Step 7c: Compare column types and missing value counts between SQLite and pandas."""

import sqlite3
import sys
from pathlib import Path
import pandas as pd

DB = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/movielens.db")

with sqlite3.connect(DB) as conn:
    sql_types = pd.read_sql("PRAGMA table_info(movies);", conn)[
        ["name", "type", "notnull"]
    ]
    movies_df = pd.read_sql("SELECT * FROM movies", conn)

print("=== 1. SQLite Schema (PRAGMA table_info) ===")
print(sql_types.to_string(index=False))

print("\n=== 2. Pandas DataFrame dtypes ===")
print(movies_df.dtypes)

print("\n=== 3. Pandas Missing Counts per Column (isna().sum()) ===")
print(movies_df.isna().sum())
