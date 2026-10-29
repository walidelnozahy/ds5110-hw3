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

One query per claim, in `sql/queries/check_*.sql`. All three claims hold.

| Claim | Query | Result |
| --- | --- | --- |
| 100,000 ratings, 943 users, 1,682 movies | `check_1_counts.sql` | 100,000 / 943 / 1,682. All 943 users and all 1,682 movies appear in `ratings`. |
| Numbered consecutively from 1 | `check_2_consecutive_ids.sql` | Users run 1 to 943 and movies 1 to 1,682. Max equals count, so there are no gaps. |
| Every user rated at least 20 movies | `check_3_min_20_ratings.sql` | The fewest ratings by any user is 20, and 0 users have fewer. |

## Step 5 – Answer questions in SQL

Each query is in `sql/queries/`, with the predicted and actual row counts in a comment at the top. `make queries` runs them all. The predicted counts were drafted with AI after the queries had been run, so they are not blind guesses; they record the reasoning for each expected count.

- **Q1** returns 10 rows. Star Wars (1977) is first with 583 ratings. I used `RANK()` so that movies tied with 10th place would all be kept, but 10th place (429) is not tied.
- **Q2** returns 7 rows out of 21 occupations. Educators rate highest (3.671) and students lowest (3.515). The raters condition goes in `HAVING` because it is about a whole group, and `WHERE` runs before the groups exist.
- **Q3** is 18 users, all with Canadian-style codes like `T8H1N`. With `zip` as `INTEGER`, a STRICT table would refuse those rows, so the answer would be 0 and the 18 users would be missing.
- **Q4** has 19 rows (18 genres plus `unknown`). The genre counts add up to 212,595, which is 112,595 more than 100,000, because a rating of a multi-genre movie is counted once per genre. Drama is the biggest genre (39,895 ratings) and Film-Noir has the highest mean (3.922).
- **Q5** returns 8 rows, September 1997 to April 1998. November 1997 is the busiest month (23,980). A month with no ratings would not appear, because `GROUP BY` only sees rows that exist.
- **Q6** returns 268 movies. `EXCEPT` fits because the question is "in set A but not in set B", where A is the movies a student rated and B is the movies a programmer rated. `UNION` gives A or B, and `INTERSECT` gives both.

## Step 6 – Build a query from named steps

## Step 7 – Missing values in SQL and in pandas

**(d) Q6 again in pandas.** `src/q6_pandas.py` reads the ratings joined to users with `read_sql` and takes the difference of two Python sets. It finds 1,339 movies rated by a student, 1,133 by a programmer, and 268 for students but no programmer, the same as the SQL. The counts match, so there is nothing to explain.

## Step 8 – Where SQL earns its place
