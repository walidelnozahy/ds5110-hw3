# DS5110 Homework 3: write-up

Every step in order. For every query: the prediction, the actual row count, and an explanation of any gap.

## Step 0 – Describe the raw data

_To do (PR 2)._

## Step 1 – Acquire the data reproducibly

`src/download.py` fetches `ml-100k.zip` from GroupLens and unpacks it into `raw/ml-100k/`. `make` runs it only when `raw/ml-100k/u.data` is missing, so a fresh clone downloads once and later runs reuse the files.

- **Not committed:** the dataset README says the data may not be redistributed without permission. So `raw/` is in `.gitignore` and every member downloads their own copy.
- **Same bytes for everyone:** GroupLens publishes an MD5 next to the zip. The script checks the download against it and stops on a mismatch. It also prints the SHA-256, which we record in the README with the source URL and download date (2026-10-26, UTC).
- **Raw files are never edited.** Every fix happens in code, in `src/load.py`.

## Step 2 – Design the schema

`sql/schema.sql` has six `STRICT` tables with foreign keys on. The diagram is in the [README](README.md#schema).

**(a) Tables and keys.** One table per kind of thing, so each fact is stored once:

| Table | One row is | Primary key | Foreign keys |
| --- | --- | --- | --- |
| `users` | a user (`u.user`) | `user_id` | `occupation` → `occupations` |
| `movies` | a movie (`u.item`, without the genre flags) | `movie_id` | |
| `ratings` | one user's rating of one movie (`u.data`) | `(user_id, movie_id)` | `user_id` → `users`, `movie_id` → `movies` |
| `movie_genres` | one (movie, genre) pair | `(movie_id, genre)` | `movie_id` → `movies`, `genre` → `genres` |
| `genres` | a genre (`u.genre`) | `genre` | |
| `occupations` | an occupation (`u.occupation`) | `occupation` | |

**(b) Genres in tidy form.** In `u.item` the 19 genre names (Action, Comedy, …) are column headers, but they are really values of one variable, `genre`. That breaks the tidy rule that each variable is a column. `movie_genres` stores one row per (movie, genre) pair, and only for the flags that are 1. This means:

- "ratings per genre" is one `GROUP BY genre`, not 19 separate sums
- a new genre is a new row, not a schema change
- the foreign key to `genres` refuses a misspelled genre

**(c) A constraint for every single-column or single-row claim in the README.**

| README claim | Constraint |
| --- | --- |
| Ratings are 1 to 5 | `rating INTEGER CHECK (rating BETWEEN 1 AND 5)` |
| Users and items are numbered from 1 | `CHECK (user_id >= 1)`, `CHECK (movie_id >= 1)` |
| The user and movie ids in `u.data` are the ones in `u.user` and `u.item` | foreign keys from `ratings` to `users` and `movies` |
| Timestamps are Unix seconds | `timestamp INTEGER NOT NULL` |
| Ratings were collected from 1997-09-19 to 1998-04-22 | `CHECK (timestamp BETWEEN 874627200 AND 893289599)`, those two days in UTC, because the README says the timestamps are UTC |
| Users with incomplete demographics were removed | `NOT NULL` on `age`, `gender`, `occupation`, `zip` |
| Occupations come from `u.occupation`, genres from `u.genre` | foreign keys to `occupations` and `genres` |

Choices of our own, not README claims: `gender IN ('M','F')`, `age > 0`, `release_date` stored as an ISO date (`YYYY-MM-DD`), and one rating per user per movie (the primary key of `ratings`). `title` is deliberately not `UNIQUE`, and `release_date` may be NULL. We checked both against the raw file before deciding.

**Claims no constraint can enforce**, because a `CHECK` sees one row at a time:

- 100,000 ratings, 943 users, 1,682 movies: these are counts of whole tables.
- Numbered *consecutively*: needs every id at once.
- Every user rated at least 20 movies: needs a group of rows per user.

Each gets its own query in [Step 4](#step-4--check-the-readmes-claims). The README also says the data is "randomly ordered". A table has no row order, so this claim does not carry into the database at all. And `NOT NULL` only works if `load.py` turns blank cells into NULL; a blank string would pass it.

**(d) `zip` is `TEXT`.** A zip code is a label, not a quantity: nobody adds or averages them. Some zip codes start with 0, which an `INTEGER` would silently drop. Some contain letters (Canadian postal codes such as `T8H1N`), which a `STRICT` `INTEGER` column would refuse outright. `TEXT` keeps every value exactly as the file has it.

## Step 3 – Load the data and keep what is refused

_To do (PR 3)._

## Step 4 – Check the README's claims

_To do (PR 4)._

## Step 5 – Answer questions in SQL

_To do (PR 4)._

## Step 6 – Build a query from named steps

_To do (PR 5)._

## Step 7 – Missing values in SQL and in pandas

_To do (PR 5; 7d in PR 4)._

## Step 8 – Where SQL earns its place

_To do (PR 6)._
