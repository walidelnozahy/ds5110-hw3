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

# Run every query in sql/queries/ and print each result with its row count.
queries: data/movielens.db
	$(PYTHON) src/run_queries.py $< sql/queries

clean:
	rm -f data/movielens.db output/rejected.csv

.PHONY: all download queries clean
