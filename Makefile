PYTHON ?= python3

# `make` downloads the data if needed, rebuilds the database, and saves the query results.
all: data/movielens.db output/query_results.txt

# Download and unpack only when the raw files are missing. Never edit raw/ by hand.
raw/ml-100k/u.data:
	$(PYTHON) src/download.py raw

download: raw/ml-100k/u.data

# The database is derived from the raw files. Never edit it by hand.
data/movielens.db: sql/schema.sql src/load.py raw/ml-100k/u.data
	$(PYTHON) src/load.py raw/ml-100k $@

# Run every query in sql/queries/ against the database, in name order, and save the results.
# Written to a .tmp file first, so a failed query never leaves a half-written results file.
output/query_results.txt: data/movielens.db $(wildcard sql/queries/*.sql)
	@for f in sql/queries/*.sql; do echo "== $$f"; sqlite3 -header -column data/movielens.db < $$f || exit 1; done > $@.tmp
	@mv $@.tmp $@

# Show the query results in the terminal.
queries: output/query_results.txt
	@cat $<

clean:
	rm -f data/movielens.db output/rejected.csv output/query_results.txt

.PHONY: all download queries clean
