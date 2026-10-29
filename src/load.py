"""Load raw MovieLens 100K data into SQLite.

Enforces schema constraints, converts raw dates to ISO-8601 strings,
populates lookup tables, and logs any rows refused by constraints to output/rejected.csv.
"""

import csv
from datetime import datetime
from pathlib import Path
import sqlite3
import sys

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_RAW_DIR = ROOT / "raw" / "ml-100k"
DEFAULT_DB_PATH = ROOT / "data" / "movielens.db"
OUTPUT_DIR = ROOT / "output"
SCHEMA_PATH = ROOT / "sql" / "schema.sql"
REJECTED_PATH = OUTPUT_DIR / "rejected.csv"


def format_iso_date(date_str: str):
    """Convert raw date format (e.g., '01-Jan-1995') to ISO 'YYYY-MM-DD'."""
    if not date_str or not date_str.strip():
        return None
    try:
        return datetime.strptime(date_str.strip(), "%d-%b-%Y").strftime("%Y-%m-%d")
    except ValueError:
        return date_str.strip()


def log_rejection(writer, table_name, raw_line, reason):
    """Log refused row details into output/rejected.csv."""
    writer.writerow({
        "table_name": table_name,
        "raw_data": str(raw_line).strip(),
        "error_message": str(reason).strip(),
    })


def load_lookups(conn, raw_dir: Path, rej_writer):
    cur = conn.cursor()
    genre_names = []

    genre_file = raw_dir / "u.genre"
    if genre_file.exists():
        with open(genre_file, "r", encoding="latin-1") as f:
            for line in f:
                line_str = line.strip()
                if not line_str:
                    continue
                parts = line_str.split("|")
                if len(parts) >= 1 and parts[0]:
                    gname = parts[0].strip()
                    genre_names.append(gname)
                    try:
                        cur.execute("INSERT INTO genres (genre) VALUES (?);", (gname,))
                    except sqlite3.Error as e:
                        log_rejection(rej_writer, "genres", line_str, e)

    occ_file = raw_dir / "u.occupation"
    if occ_file.exists():
        with open(occ_file, "r", encoding="latin-1") as f:
            for line in f:
                occ = line.strip()
                if not occ:
                    continue
                try:
                    cur.execute("INSERT INTO occupations (occupation) VALUES (?);", (occ,))
                except sqlite3.Error as e:
                    log_rejection(rej_writer, "occupations", occ, e)

    conn.commit()
    return genre_names


def load_users(conn, raw_dir: Path, rej_writer):
    user_file = raw_dir / "u.user"
    cur = conn.cursor()
    with open(user_file, "r", encoding="latin-1") as f:
        for line in f:
            line_str = line.strip()
            if not line_str:
                continue
            parts = line_str.split("|")
            if len(parts) != 5:
                log_rejection(rej_writer, "users", line_str, "Malformed column count")
                continue

            uid, age, gender, occupation, zip_code = parts
            try:
                cur.execute(
                    """
                    INSERT INTO users (user_id, age, gender, occupation, zip)
                    VALUES (?, ?, ?, ?, ?);
                    """,
                    (int(uid), int(age), gender, occupation, zip_code),
                )
            except (sqlite3.Error, ValueError) as e:
                log_rejection(rej_writer, "users", line_str, e)
    conn.commit()


def load_movies_and_genres(conn, raw_dir: Path, genre_names, rej_writer):
    item_file = raw_dir / "u.item"
    cur = conn.cursor()
    with open(item_file, "r", encoding="latin-1") as f:
        for line in f:
            line_str = line.strip()
            if not line_str:
                continue
            parts = line_str.split("|")
            if len(parts) < 24:
                log_rejection(rej_writer, "movies", line_str, "Malformed column count")
                continue

            mid = int(parts[0])
            title = parts[1]
            raw_release = parts[2]
            iso_release = format_iso_date(raw_release)
            imdb_url = parts[4] if parts[4].strip() != "" else None
            genre_flags = parts[5:24]

            movie_inserted = False
            try:
                cur.execute(
                    """
                    INSERT INTO movies (movie_id, title, release_date, imdb_url)
                    VALUES (?, ?, ?, ?);
                    """,
                    (mid, title, iso_release, imdb_url),
                )
                movie_inserted = True
            except (sqlite3.Error, ValueError) as e:
                log_rejection(rej_writer, "movies", line_str, e)

            if movie_inserted:
                for idx, flag in enumerate(genre_flags):
                    if flag == "1" and idx < len(genre_names):
                        gname = genre_names[idx]
                        try:
                            cur.execute(
                                """
                                INSERT INTO movie_genres (movie_id, genre)
                                VALUES (?, ?);
                                """,
                                (mid, gname),
                            )
                        except sqlite3.Error as e:
                            log_rejection(
                                rej_writer, "movie_genres", f"{mid}|{gname}", e
                            )
    conn.commit()


def load_ratings(conn, raw_dir: Path, rej_writer):
    data_file = raw_dir / "u.data"
    cur = conn.cursor()
    with open(data_file, "r", encoding="latin-1") as f:
        for line in f:
            line_str = line.strip()
            if not line_str:
                continue
            parts = line_str.split("\t")
            if len(parts) != 4:
                log_rejection(rej_writer, "ratings", line_str, "Malformed column count")
                continue

            uid, mid, rating, timestamp = parts
            try:
                cur.execute(
                    """
                    INSERT INTO ratings (user_id, movie_id, rating, timestamp)
                    VALUES (?, ?, ?, ?);
                    """,
                    (int(uid), int(mid), int(rating), int(timestamp)),
                )
            except (sqlite3.Error, ValueError) as e:
                log_rejection(rej_writer, "ratings", line_str, e)
    conn.commit()


def main():
    # Parse CLI positional arguments passed by Makefile, or fallback to defaults
    raw_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_RAW_DIR
    db_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_DB_PATH

    db_path.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    if db_path.exists():
        db_path.unlink()

    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON;")

    with open(REJECTED_PATH, "w", newline="", encoding="utf-8") as rej_file:
        fieldnames = ["table_name", "raw_data", "error_message"]
        rej_writer = csv.DictWriter(rej_file, fieldnames=fieldnames)
        rej_writer.writeheader()

        with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
            conn.executescript(f.read())
        conn.commit()

        genre_names = load_lookups(conn, raw_dir, rej_writer)
        load_users(conn, raw_dir, rej_writer)
        load_movies_and_genres(conn, raw_dir, genre_names, rej_writer)
        load_ratings(conn, raw_dir, rej_writer)

    conn.close()
    print(f"Database build complete -> {db_path}")
    print(f"Rejected rows recorded -> {REJECTED_PATH}")


if __name__ == "__main__":
    main()