# Contributions

We split the homework into six GitHub issues, two each, and did each part in its own pull request.

**Walid Elnozahy.** Set up the repository and split the work into issues. Wrote the download script, the `Makefile` and the database schema (Steps 1 and 2), and later fixed the release date rule so that bad dates are refused. Reviewed the other pull requests by re-running their numbers. Did the final check: Step 8, this file, the README, a last pass over the write-up, made `make` also save the query results, and tested a fresh clone.

**Max Goldmuntz.** Wrote `src/load.py`, which builds the database and records refused rows (Step 3). Wrote the Step 6 query as named `WITH` steps and as one nested query, and the Step 7 work on missing values: where `NULL` appears, the `NOT IN` trap and its `NOT EXISTS` fix, and how types change in pandas.

**Sandeep Samuel Jayakumar.** Described the raw files and made the two charts (Step 0). Wrote the queries that check the README's claims (Step 4), the six questions Q1 to Q6 (Step 5), Q6 again in pandas (Step 7d), and the first `make queries` target.
