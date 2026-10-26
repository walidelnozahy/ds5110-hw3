"""Download MovieLens 100K from GroupLens and unpack it into raw/.

Usage:
    python3 src/download.py raw

The GroupLens terms do not allow us to redistribute the data, so the repo
downloads it instead of committing it. The zip is checked against the MD5
that GroupLens publishes next to it, so everyone works from the same bytes.
Files in raw/ are never edited.
"""
import hashlib
import sys
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

URL = "https://files.grouplens.org/datasets/movielens/ml-100k.zip"
MD5 = "0e33842e24a9c977be4e0107933c0723"    # published at URL + ".md5"
HEADERS = {"User-Agent": "DS5110-coursework"}

raw_dir = Path(sys.argv[1])
zip_path = raw_dir / "ml-100k.zip"
raw_dir.mkdir(parents=True, exist_ok=True)

# Download once. A zip that is already there is kept unchanged.
if zip_path.exists():
    print("exists, kept unchanged:", zip_path)
else:
    req = urllib.request.Request(URL, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as r:
        zip_path.write_bytes(r.read())
    retrieved = datetime.now(timezone.utc).isoformat(timespec="seconds")
    print("saved", zip_path, f"{zip_path.stat().st_size:,} bytes, retrieved {retrieved}")

# Record what we have, and stop if it is not the file GroupLens published.
data = zip_path.read_bytes()
md5 = hashlib.md5(data).hexdigest()
if md5 != MD5:
    sys.exit(f"MD5 {md5} does not match GroupLens's {MD5}. Delete {zip_path} and run again.")
print("md5   ", md5, "(matches GroupLens)")
print("sha256", hashlib.sha256(data).hexdigest())

with zipfile.ZipFile(zip_path) as z:
    z.extractall(raw_dir)
print("unpacked into", raw_dir / "ml-100k")
