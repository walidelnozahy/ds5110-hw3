# DS5110 Homework 3: write-up

Our answers to every step, in order. For every query we give our guess, the real number of rows, and an explanation of any difference between the two.

## Step 0 – Describe the raw data

_Not written yet (issue #2)._

## Step 1 – Acquire the data reproducibly

`src/download.py` downloads `ml-100k.zip` from GroupLens and unzips it into `raw/ml-100k/`. `make` only runs it when the data isn't there yet, so a fresh clone downloads once and later runs reuse the same files.

- **Why we don't commit the data:** the dataset's README says it may not be shared without permission. So `raw/` is in `.gitignore`, and each of us downloads our own copy with the script.
- **How we know everyone has the same file:** GroupLens publishes an MD5 checksum (a fingerprint of the file) next to the zip. The script compares the download with it and stops if they differ. It also prints the SHA-256 checksum, which we wrote in the README together with the web address and the download date (2026-10-26, UTC).
- **We never edit the raw files.** Every fix happens in code, in `src/load.py`.

## Step 2 – Design the schema

The design is in `sql/schema.sql`: six tables, linked by keys. Every table is `STRICT`, which means SQLite refuses a value of the wrong type instead of quietly storing it. Foreign keys are switched on, so a rating can't point to a user or movie that doesn't exist. The diagram is in the [README](README.md#how-the-tables-connect).

**(a) The tables.** We made one table per kind of thing, so each fact is stored only once:

| Table | One row is | Identified by | Points to |
| --- | --- | --- | --- |
| `users` | one user (from `u.user`) | `user_id` | their occupation in `occupations` |
| `movies` | one movie (from `u.item`, without the genre columns) | `movie_id` | |
| `ratings` | one user's rating of one movie (from `u.data`) | `user_id` + `movie_id` together | the user in `users`, the movie in `movies` |
| `movie_genres` | one movie paired with one of its genres | `movie_id` + `genre` together | the movie in `movies`, the genre in `genres` |
| `genres` | one genre (from `u.genre`) | `genre` | |
| `occupations` | one occupation (from `u.occupation`) | `occupation` | |

**(b) Genres as rows, not 19 columns.** In `u.item`, the 19 genre names (Action, Comedy and so on) sit in the header row as separate yes/no columns. But they're really the values of one thing, the movie's genre. That breaks the tidy rule that each variable gets one column. So `movie_genres` has one row per movie and genre, only for the genres a movie actually has. A movie with three genres gets three rows. This helps in three ways:

- "Ratings per genre" becomes one `GROUP BY genre` instead of 19 separate sums.
- A new genre is just a new row. We don't have to change the table.
- Because `genre` points to the `genres` table, a misspelled genre is refused.

**(c) A rule for every promise the README makes about a single value or a single row.**

| What the README promises | The rule in our schema |
| --- | --- |
| Ratings are from 1 to 5 | `rating` must be a whole number between 1 and 5 |
| Users and movies are numbered from 1 | `user_id` and `movie_id` must be 1 or more |
| The user and movie numbers in `u.data` are the ones in `u.user` and `u.item` | `ratings` points to `users` and `movies` (foreign keys), so a rating for an unknown user or movie is refused |
| Timestamps are Unix seconds (seconds since 1970) | `timestamp` must be a whole number and can't be empty |
| Ratings were collected from September 19, 1997 to April 22, 1998 | `timestamp` must fall between those two days. We used UTC, because the README says the timestamps are in UTC |
| Users with incomplete information were removed | `age`, `gender`, `occupation` and `zip` can't be empty |
| Occupations come from `u.occupation`, genres from `u.genre` | `users` points to `occupations`, and `movie_genres` points to `genres` |

Some rules are our own choices, not promises from the README: gender must be `M` or `F`, age must be above 0, release dates are stored as `YYYY-MM-DD`, and a user can rate each movie only once. We also chose *not* to make movie titles unique, and we allow an empty release date, after checking the raw file: some titles appear twice, and one movie has no release date.

**Promises that no rule can check.** A rule like this only looks at one row at a time, so it can't check anything that needs several rows together:

- "100,000 ratings by 943 users on 1,682 movies": these are counts of whole tables.
- "Numbered from 1 *with no gaps*": to see a gap you need all the numbers at once.
- "Every user rated at least 20 movies": you need all of a user's ratings together.

We check each of these with its own query in [Step 4](#step-4--check-the-readmes-claims). The README also says the data is "randomly ordered". A database table has no row order at all, so that promise simply doesn't apply once the data is loaded. Finally, the "can't be empty" rules only work if `load.py` turns empty cells into real empty values (NULL). A blank piece of text would slip past them.

**(d) Zip codes are stored as text.** A zip code is a label, not an amount: nobody adds up or averages zip codes. Some zip codes start with 0, and storing them as numbers would silently drop that 0. Others contain letters, like the Canadian postal code `T8H1N`, and a `STRICT` number column would refuse them outright. Text keeps every zip code exactly as it is in the file.

## Step 3 – Load the data and keep what is refused

_Not written yet (issue #3)._

## Step 4 – Check the README's claims

_Not written yet (issue #4)._

## Step 5 – Answer questions in SQL

_Not written yet (issue #4)._

## Step 6 – Build a query from named steps

_Not written yet (issue #5)._

## Step 7 – Missing values in SQL and in pandas

_Not written yet (issue #5; part d in issue #4)._

## Step 8 – Where SQL earns its place

_Not written yet (issue #6)._
