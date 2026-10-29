# DS5110 Homework 3: write-up

## Step 0 – Describe the raw data

## Step 1 – Acquire the data reproducibly

`src/download.py` downloads `ml-100k.zip` from GroupLens and unzips it into `raw/`. `make download` runs it only if the data isn't there yet.

- The dataset's terms say the data may not be shared, so `raw/` is in `.gitignore` and each of us downloads our own copy.
- GroupLens publishes an MD5 checksum (a fingerprint of the file) next to the zip. The script checks the download against it and stops if they differ, so everyone works from the exact same file. The checksum and download date are in the README.
- We never edit the raw files. Any fixes happen in code.

## Step 2 – Design the schema

The tables are in `sql/schema.sql`, and the diagram is in the README.

**(a) The tables.** One table per raw file: `users`, `movies` and `ratings`. Then `movie_genres`, with one row per movie and genre, and two short lookup lists, `genres` and `occupations`. Each rating points to a user and a movie, so a rating for a user or movie that doesn't exist is refused.

**(b) Genres as rows.** In `u.item`, the 19 genres are 19 yes/no columns. But they're all values of one thing, the movie's genre, which breaks the tidy rule that each variable gets one column. So `movie_genres` stores one row per movie and genre. "Ratings per genre" then becomes one `GROUP BY`, and a misspelled genre is refused because it must exist in `genres`.

**(c) A rule for each promise in the README.**

| The README says | Our rule |
| --- | --- |
| Ratings are 1 to 5 | `rating` must be between 1 and 5 |
| Users and movies are numbered from 1 | `user_id` and `movie_id` must be 1 or more |
| The ids in `u.data` are the ones in `u.user` and `u.item` | `ratings` points to `users` and `movies` |
| Timestamps are seconds since 1970 (UTC) | `timestamp` is a whole number, never empty |
| Ratings were collected from Sept 19, 1997 to April 22, 1998 | `timestamp` must fall between those two days |
| Users with missing information were removed | `age`, `gender`, `occupation` and `zip` can't be empty |

A rule only looks at one row at a time, so some promises can't be checked this way: the totals (100,000 ratings, 943 users, 1,682 movies), "numbered with no gaps", and "every user rated at least 20 movies". We check those with queries in Step 4.

**(d) Zip codes are text.** A zip code is a label, not a number you'd add up. Some start with 0, which a number column would drop. Some contain letters (Canadian codes like `T8H1N`), which a number column would refuse.

## Step 3 – Load the data and keep what is refused

`src/load.py` reads from `raw/ml-100k/` and creates `data/movielens.db`. Running `make` downloads the files if missing and builds the database from scratch.

**(a) What we predicted.** Before running the load, we expected the exact counts promised by the README: 943 users, 1,682 movies, 100,000 ratings, 19 genres, 21 occupations, and > 2,000 rows in `movie_genres` because movies have multiple genres. We expected potential refusals on movie 267 (blank fields), Canadian zip codes with letters, and the raw dates in `u.item` (`01-Jan-1995`) which don't match SQLite's ISO date format (`YYYY-MM-DD`).

**(b) The refused rows.** Any row that broke a rule was caught by SQLite and logged to `output/rejected.csv` with the table name, the raw line, and the error. Our final load produced 0 refused rows.

**(c) Decisions made in code.**
- **Dates to ISO format**: In `schema.sql`, `movies.release_date` checks that `release_date = date(release_date)`. The raw dates in `u.item` are `DD-Mon-YYYY` (like `01-Jan-1995`). Dropping 1,681 movies over date formatting would wreck the dataset, and editing the raw text files is forbidden. Instead, `load.py` converts valid dates into ISO strings (`YYYY-MM-DD`) in Python before inserting them.
- **Blank values to NULL**: In `u.item`, blank video release dates, IMDb URLs, and movie 267's missing release date were read as `None` (SQL `NULL`). The schema allows `NULL` for these columns, so movie 267 was inserted without being dropped.
- **Zip codes kept as text**: Users with Canadian postal codes (like `M4V1L5`) inserted cleanly because `zip` was set as `TEXT`, not `INTEGER`.
- **Order of operations**: We loaded `genres` and `occupations` first, then `users` and `movies`, and finally `movie_genres` and `ratings`. This ensured foreign keys always found their parent rows.

**(d) Makefile target.** We wired up the `Makefile` so that `make` depends on `data/movielens.db`. If the database is missing, it runs `src/download.py` if needed, then `src/load.py raw/ml-100k data/movielens.db`.

**(e) Expected vs actual counts.**

| Table | Expected | Actual | Refused | Why there's a difference |
| --- | --- | --- | --- | --- |
| `occupations` | 21 | 21 | 0 | Exact match. |
| `genres` | 19 | 19 | 0 | Exact match. |
| `users` | 943 | 943 | 0 | Exact match; `zip TEXT` handles non-digits. |
| `movies` | 1,682 | 1,682 | 0 | Exact match; dates were normalized in code. |
| `movie_genres` | > 2,000 | 2,893 | 0 | Exact match; captured all multi-genre flags. |
| `ratings` | 100,000 | 100,000 | 0 | Exact match; all timestamps were valid. |

## Step 4 – Check the README's claims

## Step 5 – Answer questions in SQL

## Step 6 – Build a query from named steps

## Step 7 – Missing values in SQL and in pandas

## Step 8 – Where SQL earns its place
