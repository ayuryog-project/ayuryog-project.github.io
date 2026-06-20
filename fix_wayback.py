#!/usr/bin/env python3
"""
Strip web.archive.org URL wrappers from all Jekyll post files in _posts/.

Run from inside the ayuryog/ directory:
    python3 fix_wayback.py
"""

import re, os

POSTS_DIR = "_posts"

pattern = re.compile(
    r'https?://web\.archive\.org/web/\d+(?:im_)?/(https?://[^\s\)\]"\']+)'
)

fixed, clean = [], []

for fname in sorted(os.listdir(POSTS_DIR)):
    if not fname.endswith(".md"):
        continue
    path = os.path.join(POSTS_DIR, fname)
    with open(path, encoding="utf-8") as f:
        original = f.read()
    cleaned = pattern.sub(r'\1', original)
    if cleaned != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(cleaned)
        count = len(pattern.findall(original))
        print(f"Fixed {count:3d} URL(s): {fname}")
        fixed.append(fname)
    else:
        clean.append(fname)

print(f"\n{len(fixed)} files fixed, {len(clean)} already clean.")
