# DS5110 Homework 3: write-up

## Step 0 – Describe the raw data

`src/describe.py` prints everything below and saves the two charts to `figures/`.

| File | Size | One row is | First row |
| --- | --- | --- | --- |
| `u.user` | 943 rows, 5 columns | one user | `1\|24\|M\|technician\|85711` |
| `u.item` | 1,682 rows, 24 columns | one movie | `1\|Toy Story (1995)\|01-Jan-1995\|\|http://us.imdb.com/...\|0\|0\|0\|1\|1\|1\|0...` |
| `u.data` | 100,000 rows, 4 columns | one rating, by one user of one movie | `196  242  3  881250949` |

None of the files has a header row. `u.user` and `u.item` are separated by `|`, and `u.data` by tabs.

**Is it tidy?**
- `u.user` and `u.data` are tidy: one row per observation, one column per variable.
- `u.item` is not. The last 19 columns (`unknown`, `Action`, ... `Western`) are all values of one variable, the genre, spread over 19 yes/no columns. A movie can have several. This is why `movie_genres` has one row per movie and genre.
- `u.data` has no repeated (user, movie) pair, so each user rated each movie at most once.

**What the README leaves out**
- It says every file is "tab separated", but `u.user` and `u.item` use `|`.
- `u.item` is not UTF-8. Titles with accents only read correctly as latin-1.
- The "video release date" column is empty in all 1,682 rows.
- One movie (id 267) is named `unknown` and has no release date and no IMDb URL. Two more movies have no IMDb URL.
- 36 movies share a title with another id (for example "Body Snatchers (1993)" is ids 573 and 670), so the title can't identify a movie.
- 18 of the 943 zip codes are not 5 digits (for example `T8H1N`, a Canadian postal code), so `zip` has to be text.
- The README says the data starts on Sept 19, 1997. The first timestamp is 1997-09-20 03:05 UTC, so the README is probably using US time. The last is 1998-04-22 23:10 UTC.

**Chart 1: `figures/ratings_by_score.png`.** Ratings lean positive: 4 is the most common score (34,174 ratings) and 3 is next (27,145), while 1 is the rarest (6,110). Nobody gave a half score.

**Chart 2: `figures/ratings_per_user.png`.** Activity is very uneven. The README guarantees at least 20 ratings per user, and the median user gave 65, but the most active gave 737, so the histogram has a long right tail.

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

**(b) The refused rows.** Any row that broke a rule was caught by SQLite and logged to `output/rejected.csv` with the table name, the raw line, and the error. Our final load produced 0 refused rows, because `load.py` fixes the dates before inserting them (see (c)). Without that fix, the schema refuses 1,681 movies (every movie except 267) for a bad date. Then it refuses 99,991 ratings, because the movies they point to are missing.

**(c) Decisions made in code.**
- **Dates to ISO format**: In `schema.sql`, `movies.release_date` checks that `release_date IS date(release_date)`. We use `IS`, not `=`: for a bad date, `date()` gives NULL, and SQLite lets a row through when a check comes out NULL, so with `=` a bad date would slip in. The raw dates in `u.item` are `DD-Mon-YYYY` (like `01-Jan-1995`). Dropping 1,681 movies over date formatting would wreck the dataset, and editing the raw text files is forbidden. Instead, `load.py` converts valid dates into ISO strings (`YYYY-MM-DD`) in Python before inserting them.
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

File: `sql/queries/step6_genre_relative_ratings.sql`

**(a) The named steps and row counts.**
We found movies that outperform their genre average by at least 0.5 stars (among movies with >= 30 ratings) using four steps:

| Step | Name | Row Count | What it does |
| --- | --- | --- | --- |
| 1 | `movie_stats` | 806 | Mean rating and rating count per movie, filtered to `HAVING COUNT(*) >= 30`. |
| 2 | `genre_stats` | 19 | Overall mean rating for each of the 19 genres. |
| 3 | `movie_genre_comparison` | 1,610 | Joins qualifying movies to each of their genres and computes `diff_from_genre = movie_mean - genre_mean`. |
| 4 | Final `SELECT` | 147 | Filters to `diff_from_genre >= 0.5` (147 movie-genre pairs across 96 different movies). |

*A Close Shave (1995)* has the largest gap, beating the Comedy average (3.394) by 1.097 stars (4.491 across 112 ratings).

**(b) Comparing against each genre vs. one genre.**
A movie can belong to several genres, so we had to decide whether to compare a movie with each of its genres or collapse them into one. We chose to compare each movie with **each of its genres** separately:
- `u.item` does not mark a "primary" genre—all genre flags have equal weight, so picking one would be arbitrary.
- Genre averages vary (Film-Noir is 3.922 while Horror is 3.290). A movie tagged as both Drama (3.687) and Comedy (3.394) might beat the Comedy mean by 0.5 stars without beating Drama by 0.5. Keeping one row per `(movie, genre)` pair shows specifically which genre benchmark the movie cleared.

**(c) CTEs vs. nested subqueries.**
Here is the same query written with nested subqueries in `FROM`:
```sql
SELECT
    ms.movie_id, ms.title, mg.genre,
    ROUND(ms.movie_mean, 3) AS movie_mean,
    ROUND(gs.genre_mean, 3) AS genre_mean,
    ROUND(ms.movie_mean - gs.genre_mean, 3) AS diff_from_genre,
    ms.num_ratings
FROM (
    SELECT m.movie_id, m.title, COUNT(r.rating) AS num_ratings, AVG(r.rating) AS movie_mean
    FROM movies m JOIN ratings r ON m.movie_id = r.movie_id
    GROUP BY m.movie_id, m.title HAVING COUNT(r.rating) >= 30
) ms
JOIN movie_genres mg ON ms.movie_id = mg.movie_id
JOIN (
    SELECT mg2.genre, AVG(r2.rating) AS genre_mean
    FROM movie_genres mg2 JOIN ratings r2 ON mg2.movie_id = r2.movie_id
    GROUP BY mg2.genre
) gs ON mg.genre = gs.genre
WHERE ROUND(ms.movie_mean - gs.genre_mean, 3) >= 0.5
ORDER BY diff_from_genre DESC, ms.title ASC;
```
We chose the `WITH` (CTE) version because it reads top-to-bottom in the order the data is transformed (`movie_stats` -> `genre_stats` -> `movie_genre_comparison` -> filter). The nested version has to be read from the inside out, repeats the `ROUND(ms.movie_mean - gs.genre_mean, 3)` calculation in both `SELECT` and `WHERE`, and is harder to test step-by-step.

## Step 7 – Missing values in SQL and in pandas

**(d) Q6 again in pandas.** `src/q6_pandas.py` reads the ratings joined to users with `read_sql` and takes the difference of two Python sets. It finds 1,339 movies rated by a student, 1,133 by a programmer, and 268 for students but no programmer, the same as the SQL. The counts match, so there is nothing to explain.

## Step 8 – Where SQL earns its place
