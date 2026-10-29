PYTHON ?= python3

# `make` downloads the data if needed, then rebuilds the database from scratch.
all: data/movielens.db

# Download and unpack only when the raw files are missing. Never edit raw/ by hand.
raw/ml-100k/u.data:
	$(PYTHON) src/download.py raw

download: raw/ml-100k/u.data

# The database is derived from the raw files. Never edit it by hand.
data/movielens.db: sql/schema.sql src/load.py raw/ml-100k/u.data
	$(PYTHON) src/load.py raw/ml-100k $@

# Run every query in sql/queries/ against the database, in name order.
queries: data/movielens.db
	@for f in sql/queries/*.sql; do echo "== $$f"; sqlite3 -header -column data/movielens.db < $$f || exit 1; done

clean:
	rm -f data/movielens.db output/rejected.csv

.PHONY: all download queries clean
