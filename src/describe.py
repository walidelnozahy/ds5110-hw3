"""Step 0: describe the three raw files and save two charts.

Usage: python3 src/describe.py [raw_dir] [figures_dir]
"""
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

raw = Path(sys.argv[1] if len(sys.argv) > 1 else "raw/ml-100k")
figures = Path(sys.argv[2] if len(sys.argv) > 2 else "figures")
figures.mkdir(exist_ok=True)

# u.item is not UTF-8 (accented titles), so it is read as latin-1.
users = pd.read_csv(raw / "u.user", sep="|", header=None, dtype={4: str},
                    names=["user_id", "age", "gender", "occupation", "zip"])
movies = pd.read_csv(raw / "u.item", sep="|", header=None, encoding="latin-1")
ratings = pd.read_csv(raw / "u.data", sep="\t", header=None,
                      names=["user_id", "movie_id", "rating", "timestamp"])

for name, df in [("u.user", users), ("u.item", movies), ("u.data", ratings)]:
    print(f"\n== {name}: {len(df)} rows x {df.shape[1]} columns")
    print(df.head(3).to_string(index=False, header=False))
    print("missing cells per column:", {c: int(n) for c, n in df.isna().sum().items() if n})

print("\nmovies with no release date:", int(movies[2].isna().sum()))
print("movies with an empty video release date:", int(movies[3].isna().sum()))
print("movies with no IMDb URL:", int(movies[4].isna().sum()))
print("movies sharing a title with another id:", int(movies[1].duplicated(keep=False).sum()))
print("zips that are not 5 digits:", int((~users["zip"].str.fullmatch(r"\d{5}")).sum()))
print("repeat (user, movie) pairs:", int(ratings.duplicated(["user_id", "movie_id"]).sum()))
print("timestamp range (UTC):",
      pd.to_datetime(ratings["timestamp"], unit="s").agg(["min", "max"]).tolist())

# Chart 1: how many ratings of each score.
counts = ratings["rating"].value_counts().sort_index()
fig, ax = plt.subplots(figsize=(6, 4))
ax.bar(counts.index, counts.values, color="#4C72B0")
ax.set_xlabel("Rating")
ax.set_ylabel("Number of ratings")
ax.set_title("Ratings by score")
fig.tight_layout()
fig.savefig(figures / "ratings_by_score.png", dpi=150)
plt.close(fig)

# Chart 2: how many ratings each user gave.
per_user = ratings.groupby("user_id").size()
print("\nratings per user: min", per_user.min(), "median", per_user.median(),
      "max", per_user.max())
fig, ax = plt.subplots(figsize=(6, 4))
ax.hist(per_user, bins=40, color="#4C72B0")
ax.set_xlabel("Ratings given by one user")
ax.set_ylabel("Number of users")
ax.set_title("Ratings per user")
fig.tight_layout()
fig.savefig(figures / "ratings_per_user.png", dpi=150)
plt.close(fig)
