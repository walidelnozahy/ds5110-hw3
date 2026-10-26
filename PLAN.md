# How we're splitting Homework 3

The work is split into six tasks. Each task is one GitHub issue and one pull request (PR). The issue has the full checklist for that task.

Track progress on the [task board](https://github.com/users/walidelnozahy/projects/2): move your card to **In progress** when you start, and to **In review** when you open your PR. It moves to **Done** by itself when the PR is merged.

## Who is who

- **A** is Walid.
- **B** and **C** are the other two of us. Decide between you who is who, then leave a comment on your two issues to claim them.

## The tasks

| PR | Who | What you do | Start |
| --- | --- | --- | --- |
| [PR 1](https://github.com/walidelnozahy/ds5110-hw3/issues/1) | A | Set up the repo, write the download script, and design the database tables | now |
| [PR 2](https://github.com/walidelnozahy/ds5110-hw3/issues/2) | C | Look at the three raw data files and make two charts | now (run `make download` to get the data) |
| [PR 3](https://github.com/walidelnozahy/ds5110-hw3/issues/3) | B | Load the data into the database and save every row it refuses | after PR 1 is merged |
| [PR 4](https://github.com/walidelnozahy/ds5110-hw3/issues/4) | C | Check the README's numbers and answer the six SQL questions | after PR 3 is merged (you can write your guesses before that) |
| [PR 5](https://github.com/walidelnozahy/ds5110-hw3/issues/5) | B | Write the long step-by-step query and look at missing values | after PR 3 is merged |
| [PR 6](https://github.com/walidelnozahy/ds5110-hw3/issues/6) | A | Final check: write the last paragraph, finish the README, and test a fresh copy | after PRs 2–5 are merged |

## How we work

1. Make a new branch from `main` for your task, and commit in small pieces under your own name. The professor checks that every one of us has commits.
2. Open a pull request and write `Closes #<issue number>` in it, so the issue closes when the PR is merged.
3. Someone else must approve your PR before it's merged. A reviews every PR, and B and C review each other's.
4. Only edit your own section of `WRITEUP.md`, so we don't get merge conflicts.
5. Never commit the `raw/` folder, the database file or a `.venv` folder.
6. Only use what the course taught: Python's `urllib`, `zipfile`, `hashlib` and `sqlite3`, plus pandas, matplotlib and `make`. If you really need something else, explain why in your PR.
7. For every query, write your guess down **before** you run it. Then run it, count the rows, and explain any difference. The professor grades this reasoning as much as the answers.
8. If you use AI, add a line to the "Use of AI" section of the README saying what you used it for. Any of us may be asked to explain any line in the repo, even one a teammate wrote.
