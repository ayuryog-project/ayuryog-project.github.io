#!/usr/bin/env bash
# Fetches full content of all AyurYog blog posts and rewrites the Jekyll files.
# Also downloads all images to assets/images/posts/
# Run from the ayuryog/ directory: bash fetch_posts.sh
# Requirements: python3 (standard library only)

python3 - << 'PYEOF'
import urllib.request, urllib.error, re, os, time, sys

BASE = "https://www.ayuryog.org/blog/"
POSTS_DIR = "_posts"
IMG_DIR = "assets/images/posts"
os.makedirs(IMG_DIR, exist_ok=True)

POSTS = [
    ("2023-02-15-making-rubies-part-three-tweaking-recipe.md",             "making-rubies-part-three-tweaking-recipe"),
    ("2023-02-04-making-gems-part-two-producing-rubies.md",                "making-gems-part-two-producing-rubies"),
    ("2023-01-27-making-gems-part-one-fish-black.md",                      "making-gems-part-one-fish-black-matsyakajjala"),
    ("2021-09-25-final-experiment-gold-imitation-chalcopyrite.md",         "final-experiment-gold-imitation-chalcopyrite"),
    ("2021-09-05-aurifiction-revisited.md",                                "aurifiction-revisited"),
    ("2021-07-26-making-silver-second-method.md",                          "reconstructing-indian-alchemy-making-silver-second-method"),
    ("2021-06-25-argentifaction-making-silver.md",                         "argentifaction-making-silver"),
    ("2021-06-02-aurifiction-imitating-gold.md",                           "aurifiction-imitating-gold"),
    ("2021-04-28-making-pearls.md",                                        "reconstructing-indian-alchemy-making-pearls"),
    ("2021-04-09-making-coral-second-third-try.md",                        "making-coral-second-and-third-try"),
    ("2021-04-08-making-coral-1.md",                                       "reconstructing-indian-alchemy-making-coral-1"),
    ("2020-08-19-stimulating-mercury-dipana.md",                           "final-procedure-stimulating-mercury-d%C4%ABpana"),
    ("2020-08-03-seventh-procedure-fixing-niyamana.md",                    "reconstructing-alchemical-procedures-seventh-procedure-fixing-niyamana"),
    ("2020-07-19-sixth-procedure-reviving-nirodha.md",                     "reconstructing-alchemical-procedures-sixth-procedure-reviving-nirodh%C4%81"),
    ("2020-07-12-fifth-procedure-letting-fall.md",                         "fifth-procedure-letting-fall"),
    ("2020-06-22-preparing-ingredients-fifth-procedure.md",                "preparing-ingredients-fifth-procedure"),
    ("2020-06-10-fourth-procedure-utthapana.md",                           "fourth-procedure-bringing-mercury-rise-utth%C4%81pana"),
    ("2020-06-02-third-procedure-thickening-murcha.md",                    "reconstructing-alchemical-procedures-third-procedure-thickening-m%C5%ABrch%C4%81"),
    ("2020-05-26-mapping-alchemical-manuscripts.md",                       "mapping-alchemical-manuscripts"),
    ("2020-05-26-dharmaputrika-chapter-ten.md",                            "medical-treatment-context-yoga-practice-yogacikits%C4%81-chapter-ten-dharmaputrik%C4%81"),
    ("2020-05-26-second-procedure-trituration-mardana.md",                 "second-procedure-trituration-mardana"),
    ("2020-05-25-first-procedure-according-to-others.md",                  "we-are-not-only-ones-first-procedure-according-others"),
    ("2020-05-18-philology-and-experimentation.md",                        "philology-and-experimentation-reconstructing-alchemical-procedures"),
    ("2020-03-27-epidemics-isolation-prevention.md",                       "epidemics-isolation-and-prevention"),
    ("2020-02-20-recreating-alchemical-operations.md",                     "recreating-alchemical-operations"),
    ("2019-12-20-yogis-adepts-experts-who-were-alchemists.md",             "yogis-adepts-experts-who-were-alchemists"),
    ("2019-12-02-avoiding-fundamentalist-histories.md",                    "avoiding-fundamentalist-histories-%E2%80%93-ayuryog-and-launch-yoga-britain"),
    ("2019-10-07-visualizing-alchemical-spaces.md",                        "visualizing-alchemical-spaces"),
    ("2019-09-05-life-after-death-beliefs.md",                             "how-think-about-life-after-death-beliefs"),
    ("2019-07-05-exploring-immortality.md",                                "exploring-immortality"),
    ("2019-06-25-ayurveda-and-alchemy.md",                                 "ayurveda-and-alchemy"),
    ("2019-05-24-what-is-the-role-of-the-teacher.md",                      "what-role-teacher"),
    ("2019-04-03-yoga-daoism-and-alchemy.md",                              "yoga-daoism-and-alchemy"),
    ("2018-11-16-yoga-ayurveda-sahapedia.md",                              "yoga-and-%C4%81yurveda-article-sahapedia-0"),
    ("2018-09-18-erccomics-roots-ayurveda.md",                             "roots-ayurveda-erccomics-about-ayuryog"),
    ("2018-08-08-postdoc-position-alberta.md",                             "history-south-asian-alchemy-post-doctoral-position-department-history-and-classics"),
    ("2018-06-05-connecting-threads-yoga-ayurveda.md",                     "connecting-threads-convergence-yoga-and-ayurveda-1900-present"),
    ("2018-04-03-transmutations-publication.md",                           "publication-announcement-transmutations-rejuvenation-longevity-and-immortality-practices-south"),
    ("2017-11-20-ayurveda-to-biomedicine.md",                              "ayurveda-biomedicine-understanding-human-body"),
    ("2017-10-03-seeds-of-modern-yoga-ayurvedasutra.md",                   "seeds-modern-yoga-confluence-yoga-and-ayurveda-%C4%81yurvedas%C5%ABtra"),
    ("2017-09-14-philology-through-experiment.md",                         "philology-through-experiment"),
    ("2017-08-17-conference-videos-medicine-yoga.md",                      "videos-conference-medicine-and-yoga-south-and-inner-asia-august-1-3-2017"),
    ("2017-06-20-revival-yoga-contemporary-india.md",                      "revival-yoga-contemporary-india"),
    ("2017-03-31-conference-programme-medicine-yoga.md",                   "conference-programme-medicine-and-yoga-south-and-inner-asia-body-cultivation-therapeutic"),
    ("2017-03-13-how-to-respond-to-yogic-powers.md",                       "how-respond-yogic-powers"),
    ("2017-02-14-krishnamacharya-yoga-indigenous-medicine.md",             "krishnamacharya-yoga-indigenous-medicine"),
    ("2017-01-19-eight-yoga-postures-dharmaputrika.md",                    "eight-yoga-postures-dharmaputrik%C4%81"),
    ("2017-01-09-recipes-for-immortality.md",                              "recipes-immortality-and-intoxicating-alchemy-south-and-inner-asia"),
    ("2016-10-21-workshop-rasayana-kayakalpa.md",                          "ayuryog-workshop-rejuvenation-longevity-immortality-perspectives-ras%C4%81yana-k%C4%81yakalpa-and-bcud"),
    ("2016-07-04-what-is-tradition.md",                                    "what-%E2%80%98tradition%E2%80%99-%E2%80%93-entanglements-and-metaphors"),
    ("2016-04-20-a-word-on-resources.md",                                  "word-resources"),
    ("2016-02-29-arion-rosu-collection.md",                                "arion-ro%C5%9Fu-collection-institute-indian-studies-coll%C3%A8ge-de-france"),
    ("2016-01-07-untangling-histories-commencing-the-project.md",          "untangling-histories-%E2%80%93-commencing-project"),
    ("2015-12-29-mercury-in-medicine-publication.md",                      "publication-announcement-mercury-medicine-across-asia-and-beyond"),
    ("2015-12-16-ayurveda-influence-medieval-yoga.md",                     "did-ayurveda-influence-medieval-yoga-traditions-preliminary-remarks-their-shared-terminology"),
    ("2015-11-30-welcome.md",                                              "welcome"),
]

def fetch(url, retries=5, delay=4):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read().decode('utf-8', errors='replace')
        except urllib.error.HTTPError as e:
            if e.code == 502 and attempt < retries - 1:
                wait = delay * (attempt + 1)
                print(f"\n  502 error, retrying in {wait}s (attempt {attempt+2}/{retries})...",
                      end=' ', flush=True)
                time.sleep(wait)
            else:
                print(f"\n  ERROR {e.code}: {url}", file=sys.stderr)
                return None
        except Exception as e:
            print(f"\n  ERROR: {e}", file=sys.stderr)
            return None

def download_image(url, local_path):
    """Download an image if not already present."""
    if os.path.exists(local_path):
        return True
    # Strip Drupal image style prefixes to get originals
    url = re.sub(r'/sites/default/files/styles/[^/]+/public/', '/sites/default/files/', url)
    # Normalise to www.ayuryog.org
    url = re.sub(r'https?://ayuryog\.org/', 'https://www.ayuryog.org/', url)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=30) as r:
            with open(local_path, 'wb') as f:
                f.write(r.read())
        return True
    except Exception as e:
        print(f"\n    IMG FAIL {os.path.basename(local_path)}: {e}", file=sys.stderr)
        return False

def localise_images(md, img_dir):
    """Download all images referenced in markdown and rewrite URLs to local paths."""
    def replace_img(m):
        alt = m.group(1)
        url = m.group(2)
        # Only download from ayuryog.org
        if 'ayuryog.org' not in url and not url.startswith('/sites/'):
            return m.group(0)
        # Normalise URL
        if url.startswith('/sites/'):
            url = 'https://www.ayuryog.org' + url
        url = re.sub(r'https?://ayuryog\.org/', 'https://www.ayuryog.org/', url)
        url = re.sub(r'/sites/default/files/styles/[^/]+/public/', '/sites/default/files/', url)
        # Derive local filename
        fname = re.sub(r'\?.*$', '', url.split('/')[-1])  # strip query string
        fname = urllib.parse.quote(fname, safe='._-')
        # Remove itok= style suffixes that sometimes appear in filenames
        fname = re.sub(r'\?itok=.*', '', fname)
        local_path = os.path.join(img_dir, fname)
        if download_image(url, local_path):
            return f'![{alt}](/{img_dir}/{fname})'
        else:
            return f'![{alt}]({url})'  # fall back to remote URL

    import urllib.parse
    md = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', replace_img, md)
    return md

def html_to_md(html):
    """Light HTML -> Markdown conversion."""
    html = re.sub(r'<br\s*/?>', '  \n', html)
    html = re.sub(r'</?p[^>]*>', '\n\n', html)
    html = re.sub(r'<h([1-6])[^>]*>(.*?)</h\1>',
                  lambda m: '\n' + '#'*int(m.group(1)) + ' ' + re.sub('<[^>]+>','',m.group(2)) + '\n',
                  html, flags=re.DOTALL)
    html = re.sub(r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>(.*?)</a>',
                  r'[\2](\1)', html, flags=re.DOTALL)
    html = re.sub(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*/?>',
                  r'![\2](\1)', html)
    html = re.sub(r'<img[^>]+alt=["\']([^"\']*)["\'][^>]+src=["\']([^"\']+)["\'][^>]*/?>',
                  r'![\1](\2)', html)
    html = re.sub(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*/?>',
                  r'![](\1)', html)
    html = re.sub(r'<em>(.*?)</em>', r'*\1*', html, flags=re.DOTALL)
    html = re.sub(r'<i>(.*?)</i>',  r'*\1*', html, flags=re.DOTALL)
    html = re.sub(r'<strong>(.*?)</strong>', r'**\1**', html, flags=re.DOTALL)
    html = re.sub(r'<b>(.*?)</b>',  r'**\1**', html, flags=re.DOTALL)
    html = re.sub(r'<blockquote[^>]*>(.*?)</blockquote>',
                  lambda m: '\n> ' + re.sub(r'\n', '\n> ', m.group(1).strip()) + '\n',
                  html, flags=re.DOTALL)
    html = re.sub(r'<[^>]+>', '', html)
    for ent, ch in [('&amp;','&'),('&lt;','<'),('&gt;','>'),('&nbsp;',' '),
                    ('&#039;',"'"),('&quot;','"'),('&ldquo;','\u201c'),
                    ('&rdquo;','\u201d'),('&lsquo;','\u2018'),('&rsquo;','\u2019'),
                    ('&ndash;','\u2013'),('&mdash;','\u2014'),('&hellip;','\u2026')]:
        html = html.replace(ent, ch)
    return html

def extract_body_html(raw_html):
    """Pull the article body out of Drupal HTML."""
    # Try field-name-body first (most reliable in Drupal 7)
    m = re.search(r'<div[^>]+class="[^"]*field-name-body[^"]*"[^>]*>.*?<div[^>]+class="[^"]*field-items[^"]*"[^>]*>(.*?)</div>\s*</div>\s*</div>',
                  raw_html, re.DOTALL)
    if m:
        return m.group(1)
    # Fallback: content between article h1 and footer/tag div
    m = re.search(r'<h1[^>]+class="[^"]*page-header[^"]*"[^>]*>.*?</h1>(.*?)(?:<div[^>]+class="[^"]*field-name-field-tags|<footer|<div[^>]+class="[^"]*block-views)',
                  raw_html, re.DOTALL)
    if m:
        return m.group(1)
    # Last resort
    m = re.search(r'<article[^>]*>(.*?)</article>', raw_html, re.DOTALL)
    if m:
        return m.group(1)
    return raw_html

def process(raw_html, filepath, img_dir):
    body_html = extract_body_html(raw_html)

    # Remove Drupal image style paths (get originals)
    body_html = re.sub(r'(https?://(?:www\.)?ayuryog\.org)/sites/default/files/styles/[^/]+/public/',
                       r'\1/sites/default/files/', body_html)
    body_html = re.sub(r'(http://ayuryog\.org)/sites/default/files/styles/[^/]+/public/',
                       r'https://www.ayuryog.org/sites/default/files/', body_html)

    # Convert YouTube iframes to placeholder markers before stripping tags
    body_html = re.sub(
        r'<iframe[^>]+src=["\']https://www\.youtube\.com/embed/([A-Za-z0-9_\-]+)[^"\']*["\'][^>]*>.*?</iframe>',
        r'YOUTUBE_EMBED_\1',
        body_html, flags=re.DOTALL)
    # Also bare URL lines
    body_html = re.sub(
        r'<a[^>]+href=["\']https://www\.youtube\.com/embed/([A-Za-z0-9_\-]+)[^"\']*["\'][^>]*>https://www\.youtube\.com/embed/\1[^<]*</a>',
        r'YOUTUBE_EMBED_\1',
        body_html)

    md = html_to_md(body_html)

    # Restore YouTube embeds
    md = re.sub(
        r'YOUTUBE_EMBED_([A-Za-z0-9_\-]+)',
        lambda m: '\n<div class="video-wrap"><iframe src="https://www.youtube.com/embed/{}" allowfullscreen loading="lazy"></iframe></div>\n'.format(m.group(1)),
        md)

    # Also catch any bare YouTube embed URLs left as markdown links or plain text
    md = re.sub(
        r'(?m)^\[?(https://www\.youtube\.com/embed/([A-Za-z0-9_\-]+))[^\]]*\]?(?:\(\1\))?\s*$',
        lambda m: '\n<div class="video-wrap"><iframe src="{}" allowfullscreen loading="lazy"></iframe></div>\n'.format(m.group(1)),
        md)

    # Fix internal links
    md = re.sub(r'https?://(?:www\.)?ayuryog\.org/blog/', '/blog/', md)
    md = re.sub(r'https?://(?:www\.)?ayuryog\.org/content/', '/', md)
    md = re.sub(r'https?://(?:www\.)?ayuryog\.org/sites/', 'https://www.ayuryog.org/sites/', md)

    # Remove boilerplate that leaks through
    md = re.sub(r'\n+©\s*Ayuryog.*$', '', md, flags=re.DOTALL)
    md = re.sub(r'\n+## Latest Blogposts.*$', '', md, flags=re.DOTALL)
    md = re.sub(r'\n+Title:\s*\n.*$', '', md, flags=re.DOTALL)
    md = re.sub(r'\[Skip to main content\]\(.*?\)\n', '', md)

    # Download images and rewrite to local paths
    print(f" (downloading images)", end='', flush=True)
    md = localise_images(md, img_dir)

    # Remove trailing duplicate bare image blocks
    md = re.sub(r'(\n!\[[^\]]*\]\(/assets/images/posts/[^)]+\)\n){3,}$', '\n', md)

    # Tidy whitespace
    md = re.sub(r'\n{4,}', '\n\n', md)
    md = md.strip()

    # Preserve frontmatter
    with open(filepath) as f:
        existing = f.read()
    fm = re.match(r'^(---\n.*?\n---\n)', existing, re.DOTALL)
    fm = fm.group(1) if fm else '---\n---\n'

    with open(filepath, 'w') as f:
        f.write(fm + '\n' + md + '\n')
    return len(md)

ok, failed, skipped = 0, [], []
for filename, slug in POSTS:
    filepath = os.path.join(POSTS_DIR, filename)
    if not os.path.exists(filepath):
        print(f"SKIP (no file): {filename}")
        skipped.append(filename)
        continue

    url = BASE + slug
    print(f"Fetching {slug[:55]}...", end=' ', flush=True)
    html = fetch(url)
    if html is None:
        print("FAILED")
        failed.append(slug)
        continue
    n = process(html, filepath, IMG_DIR)
    print(f" OK ({n} chars)")
    ok += 1
    time.sleep(0.5)

print(f"\nDone: {ok} OK, {len(failed)} failed, {len(skipped)} skipped")
if failed:
    print("\nFailed posts (re-run script to retry):")
    for s in failed:
        print(f"  {s}")
PYEOF
