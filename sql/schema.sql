-- MovieLens 100K schema. Every constraint is a claim about the data:
-- the README's claims are tagged "README:", the rest are our own choices.
-- Claims no single-row constraint can check are tested by queries (WRITEUP Step 4).
PRAGMA foreign_keys = ON;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS occupations;

-- lookup tables (u.genre, u.occupation)
CREATE TABLE genres (
  genre TEXT PRIMARY KEY
) STRICT;
CREATE TABLE occupations (
  occupation TEXT PRIMARY KEY
) STRICT;

-- u.user
CREATE TABLE users (
  user_id    INTEGER PRIMARY KEY CHECK (user_id >= 1),           -- README: numbered from 1
  age        INTEGER NOT NULL CHECK (age > 0),                   -- README: incomplete demographics removed
  gender     TEXT    NOT NULL CHECK (gender IN ('M','F')),
  occupation TEXT    NOT NULL REFERENCES occupations(occupation),
  zip        TEXT    NOT NULL                                    -- TEXT: leading zeros + Canadian codes
) STRICT;

-- u.item, minus the 19 genre flags (they move to movie_genres)
CREATE TABLE movies (
  movie_id     INTEGER PRIMARY KEY CHECK (movie_id >= 1),        -- README: numbered from 1
  title        TEXT NOT NULL,                                    -- not UNIQUE: 18 titles repeat
  release_date TEXT CHECK (release_date = date(release_date)),   -- ISO date; NULL allowed (movie 267)
  imdb_url     TEXT
) STRICT;

-- one row per (movie, genre): one variable per column
CREATE TABLE movie_genres (
  movie_id INTEGER NOT NULL REFERENCES movies(movie_id),
  genre    TEXT    NOT NULL REFERENCES genres(genre),
  PRIMARY KEY (movie_id, genre)
) STRICT;

-- u.data
CREATE TABLE ratings (
  user_id   INTEGER NOT NULL REFERENCES users(user_id),
  movie_id  INTEGER NOT NULL REFERENCES movies(movie_id),
  rating    INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),     -- README: ratings 1-5
  timestamp INTEGER NOT NULL                                     -- README: unix seconds, UTC
            CHECK (timestamp BETWEEN 874627200 AND 893289599),   -- README: 1997-09-19 to 1998-04-22
  PRIMARY KEY (user_id, movie_id)
) STRICT;
