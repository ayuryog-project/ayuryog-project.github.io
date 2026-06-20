#!/usr/bin/env python3
"""
Fetches each blog post from ayuryog.org, extracts all YouTube video IDs,
compares with the local Jekyll post file, and appends any missing video
embeds at the correct position in the post.

Run from inside the ayuryog/ directory:
    python3 fix_videos.py

Requirements: python3, internet access to ayuryog.org
"""

import urllib.request, urllib.error, re, os, time, sys

POSTS_DIR = "_posts"
BASE = "https://www.ayuryog.org/blog/"

# (jekyll filename, url slug)
POSTS = [
    ("2023-02-15-making-rubies-part-three-tweaking-recipe.md",          "making-rubies-part-three-tweaking-recipe"),
    ("2023-02-04-making-gems-part-two-producing-rubies.md",             "making-gems-part-two-producing-rubies"),
    ("2023-01-27-making-gems-part-one-fish-black.md",                   "making-gems-part-one-fish-black-matsyakajjala"),
    ("2021-09-25-final-experiment-gold-imitation-chalcopyrite.md",      "final-experiment-gold-imitation-chalcopyrite"),
    ("2021-09-05-aurifiction-revisited.md",                             "aurifiction-revisited"),
    ("2021-07-26-making-silver-second-method.md",                       "reconstructing-indian-alchemy-making-silver-second-method"),
    ("2021-06-25-argentifaction-making-silver.md",                      "argentifaction-making-silver"),
    ("2021-06-02-aurifiction-imitating-gold.md",                        "aurifiction-imitating-gold"),
    ("2021-04-28-making-pearls.md",                                     "reconstructing-indian-alchemy-making-pearls"),
    ("2021-04-09-making-coral-second-third-try.md",                     "making-coral-second-and-third-try"),
    ("2021-04-08-making-coral-1.md",                                    "reconstructing-indian-alchemy-making-coral-1"),
    ("2020-08-19-stimulating-mercury-dipana.md",                        "final-procedure-stimulating-mercury-d%C4%ABpana"),
    ("2020-08-03-seventh-procedure-fixing-niyamana.md",                 "reconstructing-alchemical-procedures-seventh-procedure-fixing-niyamana"),
    ("2020-07-19-sixth-procedure-reviving-nirodha.md",                  "reconstructing-alchemical-procedures-sixth-procedure-reviving-nirodh%C4%81"),
    ("2020-07-12-fifth-procedure-letting-fall.md",                      "fifth-procedure-letting-fall"),
    ("2020-06-22-preparing-ingredients-fifth-procedure.md",             "preparing-ingredients-fifth-procedure"),
    ("2020-06-10-fourth-procedure-utthapana.md",                        "fourth-procedure-bringing-mercury-rise-utth%C4%81pana"),
    ("2020-06-02-third-procedure-thickening-murcha.md",                 "reconstructing-alchemical-procedures-third-procedure-thickening-m%C5%ABrch%C4%81"),
    ("2020-05-26-second-procedure-trituration-mardana.md",              "second-procedure-trituration-mardana"),
    ("2020-05-25-first-procedure-according-to-others.md",               "we-are-not-only-ones-first-procedure-according-others"),
    ("2020-05-18-philology-and-experimentation.md",                     "philology-and-experimentation-reconstructing-alchemical-procedures"),
    ("2020-02-20-recreating-alchemical-operations.md",                  "recreating-alchemical-operations"),
    ("2019-12-20-yogis-adepts-experts-who-were-alchemists.md",          "yogis-adepts-experts-who-were-alchemists"),
    ("2019-10-07-visualizing-alchemical-spaces.md",                     "visualizing-alchemical-spaces"),
    ("2019-06-25-ayurveda-and-alchemy.md",                              "ayurveda-and-alchemy"),
    ("2019-05-24-what-is-the-role-of-the-teacher.md",                   "what-role-teacher"),
    ("2019-04-03-yoga-daoism-and-alchemy.md",                           "yoga-daoism-and-alchemy"),
    ("2018-06-05-connecting-threads-yoga-ayurveda.md",                  "connecting-threads-convergence-yoga-and-ayurveda-1900-present"),
    ("2017-08-17-conference-videos-medicine-yoga.md",                   "videos-conference-medicine-and-yoga-south-and-inner-asia-august-1-3-2017"),
    ("2017-06-20-revival-yoga-contemporary-india.md",                   "revival-yoga-contemporary-india"),
    ("2017-03-13-how-to-respond-to-yogic-powers.md",                    "how-respond-yogic-powers"),
    ("2017-01-09-recipes-for-immortality.md",                           "recipes-immortality-and-intoxicating-alchemy-south-and-inner-asia"),
    ("2016-10-21-workshop-rasayana-kayakalpa.md",                       "ayuryog-workshop-rejuvenation-longevity-immortality-perspectives-ras%C4%81yana-k%C4%81yakalpa-and-bcud"),
    ("2016-07-04-what-is-tradition.md",                                 "what-%E2%80%98tradition%E2%80%99-%E2%80%93-entanglements-and-metaphors"),
    ("2016-04-20-a-word-on-resources.md",                               "word-resources"),
    ("2016-01-07-untangling-histories-commencing-the-project.md",       "untangling-histories-%E2%80%93-commencing-project"),
    ("2015-11-30-welcome.md",                                           "welcome"),
]

EMBED_TMPL = '\n<div class="video-wrap"><iframe src="https://www.youtube.com/embed/{vid}" allowfullscreen loading="lazy"></iframe></div>\n'

def fetch_html(url, retries=4, delay=5):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read().decode('utf-8', errors='replace')
        except urllib.error.HTTPError as e:
            if e.code == 502 and attempt < retries - 1:
                print(f"\n  502, retrying in {delay*(attempt+1)}s...", end='', flush=True)
                time.sleep(delay * (attempt + 1))
            else:
                print(f"\n  HTTP {e.code}", file=sys.stderr)
                return None
        except Exception as e:
            print(f"\n  ERROR: {e}", file=sys.stderr)
            return None

def get_yt_ids_from_html(html):
    """Extract YouTube video IDs in document order from raw HTML."""
    return list(dict.fromkeys(  # deduplicate preserving order
        re.findall(r'youtube\.com/embed/([A-Za-z0-9_\-]+)', html)
    ))

def get_yt_ids_from_md(text):
    return list(dict.fromkeys(
        re.findall(r'youtube\.com/embed/([A-Za-z0-9_\-]+)', text)
    ))

def make_embed(vid):
    return EMBED_TMPL.format(vid=vid)

fixed_count = 0
skipped = []

for filename, slug in POSTS:
    filepath = os.path.join(POSTS_DIR, filename)
    if not os.path.exists(filepath):
        print(f"  FILE NOT FOUND: {filename}")
        continue

    url = BASE + slug
    print(f"Checking {slug[:55]}...", end=' ', flush=True)

    html = fetch_html(url)
    if html is None:
        print("FETCH FAILED - skipping")
        skipped.append(slug)
        time.sleep(1)
        continue

    live_ids = get_yt_ids_from_html(html)
    if not live_ids:
        print("no videos")
        time.sleep(0.3)
        continue

    with open(filepath, encoding='utf-8') as f:
        md = f.read()

    local_ids = get_yt_ids_from_md(md)
    local_set = set(local_ids)
    missing = [vid for vid in live_ids if vid not in local_set]

    if not missing:
        print(f"OK ({len(live_ids)} video(s))")
        time.sleep(0.3)
        continue

    print(f"MISSING {len(missing)}/{len(live_ids)} video(s): {missing}")

    # Append missing videos at end of post (before any trailing newlines)
    appended = md.rstrip('\n')
    appended += '\n'
    for vid in missing:
        appended += make_embed(vid)
    appended += '\n'

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(appended)

    fixed_count += 1
    time.sleep(0.5)

print(f"\n{'='*60}")
print(f"Fixed: {fixed_count} posts")
if skipped:
    print(f"Skipped (fetch failed): {len(skipped)}")
    for s in skipped:
        print(f"  {s}")
    print("\nRe-run the script to retry skipped posts.")
