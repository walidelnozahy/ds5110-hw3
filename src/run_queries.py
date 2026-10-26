"""Run every .sql file in a folder, in name order, and print each result
with its row count. Compare each count with the prediction in the file.

Usage:
    python3 src/run_queries.py data/movielens.db sql/queries
"""
import sqlite3
import sys
from pathlib import Path

db, folder = sys.argv[1], Path(sys.argv[2])
con = sqlite3.connect(db)
con.execute("PRAGMA foreign_keys = ON")

for path in sorted(folder.glob("*.sql")):
    sql = path.read_text()
    print(f"\n=== {path.name} ===")
    try:
        cur = con.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        print(" | ".join(cols))
        for row in rows:
            print(" | ".join("NULL" if v is None else str(v) for v in row))
        print(f"-- {len(rows)} row(s)")
    except sqlite3.Error as err:
        print(f"-- ERROR: {err}")
