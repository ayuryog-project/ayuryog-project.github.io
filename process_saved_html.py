#!/usr/bin/env python3
"""
Process locally-saved HTML files from ayuryog.org blog posts into Jekyll markdown.

Usage:
    python3 process_saved_html.py <htmlfile> <jekyll-post-filename>

Example:
    python3 process_saved_html.py coral-1.html _posts/2021-04-08-making-coral-1.md

Save each page from your browser (Ctrl+U → Save As) or from the Wayback Machine.
Works correctly with HTML saved from either source.
Run from inside the ayuryog/ directory.

The 13 posts to process and their filenames:

  URL slug (append to ayuryog.org/blog/)                  Jekyll _posts/ filename
  -------------------------------------------------------  ------------------------------------------------
  reconstructing-indian-alchemy-making-coral-1             2021-04-08-making-coral-1.md
  final-procedure-stimulating-mercury-dipana               2020-08-19-stimulating-mercury-dipana.md
  reconstructing-alchemical-procedures-seventh-...         2020-08-03-seventh-procedure-fixing-niyamana.md
  reconstructing-alchemical-procedures-third-...           2020-06-02-third-procedure-thickening-murcha.md
  medical-treatment-context-yoga-practice-...              2020-05-26-dharmaputrika-chapter-ten.md
  how-think-about-life-after-death-beliefs                 2019-09-05-life-after-death-beliefs.md
  exploring-immortality                                    2019-07-05-exploring-immortality.md
  roots-ayurveda-erccomics-about-ayuryog                   2018-09-18-erccomics-roots-ayurveda.md
  philology-through-experiment                             2017-09-14-philology-through-experiment.md
  videos-conference-medicine-and-yoga-...                  2017-08-17-conference-videos-medicine-yoga.md
  revival-yoga-contemporary-india                          2017-06-20-revival-yoga-contemporary-india.md
  krishnamacharya-yoga-indigenous-medicine                 2017-02-14-krishnamacharya-yoga-indigenous-medicine.md
  untangling-histories-commencing-project                  2016-01-07-untangling-histories-commencing-the-project.md
"""

import re, sys, os, urllib.request, urllib.parse

IMG_DIR = "assets/images/posts"

# ---------------------------------------------------------------------------
# Wayback Machine URL unwrapping
# ---------------------------------------------------------------------------

def unwrap_wayback(url):
    """Strip https://web.archive.org/web/TIMESTAMP[im_]/ prefix from a URL."""
    m = re.match(r'https?://web\.archive\.org/web/\d+(?:im_)?/(https?://.*)', url)
    return m.group(1) if m else url

def unwrap_wayback_in_text(text):
    """Remove Wayback wrappers from all URLs in a block of text."""
    return re.sub(
        r'https?://web\.archive\.org/web/\d+(?:im_)?/(https?://[^\s\)\]"\']+)',
        r'\1', text)

# ---------------------------------------------------------------------------
# Image downloading
# ---------------------------------------------------------------------------

def download_image(url, local_path):
    if os.path.exists(local_path):
        return True
    # Strip Drupal image style paths
    url = re.sub(r'/sites/default/files/styles/[^/]+/public/', '/sites/default/files/', url)
    # Normalise scheme
    url = re.sub(r'^http://((?:www\.)?ayuryog\.org)', r'https://\1', url)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=30) as r:
            with open(local_path, 'wb') as f:
                f.write(r.read())
        return True
    except Exception as e:
        print(f"    IMG FAIL {os.path.basename(local_path)}: {e}", file=sys.stderr)
        return False

def localise_images(md):
    os.makedirs(IMG_DIR, exist_ok=True)
    def replace_img(m):
        alt, url = m.group(1), m.group(2)
        # Unwrap Wayback first
        url = unwrap_wayback(url)
        # Only localise ayuryog.org images
        if 'ayuryog.org' not in url:
            return f'![{alt}]({url})'
        # Strip Drupal image style prefix
        url = re.sub(r'/sites/default/files/styles/[^/]+/public/', '/sites/default/files/', url)
        fname = urllib.parse.unquote(url.split('/')[-1])
        fname = re.sub(r'\?.*$', '', fname)   # strip query string
        local_path = os.path.join(IMG_DIR, fname)
        if download_image(url, local_path):
            print(f"    image: {fname}")
            return f'![{alt}](/{IMG_DIR}/{fname})'
        else:
            return f'![{alt}]({url})'
    return re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', replace_img, md)

# ---------------------------------------------------------------------------
# HTML → Markdown
# ---------------------------------------------------------------------------

def html_to_md(html):
    html = re.sub(r'<br\s*/?>', '  \n', html)
    html = re.sub(r'</?p[^>]*>', '\n\n', html)
    html = re.sub(r'<h([1-6])[^>]*>(.*?)</h\1>',
                  lambda m: '\n' + '#'*int(m.group(1)) + ' ' +
                  re.sub('<[^>]+>', '', m.group(2)) + '\n',
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
    html = re.sub(r'<i>(.*?)</i>',   r'*\1*', html, flags=re.DOTALL)
    html = re.sub(r'<strong>(.*?)</strong>', r'**\1**', html, flags=re.DOTALL)
    html = re.sub(r'<b>(.*?)</b>',   r'**\1**', html, flags=re.DOTALL)
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

# ---------------------------------------------------------------------------
# Article body extraction
# ---------------------------------------------------------------------------

def extract_body_html(raw_html):
    # Drupal 7 field-name-body div
    m = re.search(
        r'<div[^>]+class="[^"]*field-name-body[^"]*"[^>]*>.*?'
        r'<div[^>]+class="[^"]*field-items[^"]*"[^>]*>(.*?)'
        r'</div>\s*</div>\s*</div>',
        raw_html, re.DOTALL)
    if m:
        return m.group(1)
    # Between page-header h1 and tags/footer
    m = re.search(
        r'<h1[^>]+class="[^"]*page-header[^"]*"[^>]*>.*?</h1>(.*?)'
        r'(?:<div[^>]+class="[^"]*field-name-field-tags|<footer)',
        raw_html, re.DOTALL)
    if m:
        return m.group(1)
    # Whole article element
    m = re.search(r'<article[^>]*>(.*?)</article>', raw_html, re.DOTALL)
    if m:
        return m.group(1)
    return raw_html

# ---------------------------------------------------------------------------
# Main processing
# ---------------------------------------------------------------------------

def process(html_file, post_file):
    with open(html_file, encoding='utf-8', errors='replace') as f:
        raw_html = f.read()

    # Unwrap Wayback URLs in the raw HTML before any processing
    raw_html = re.sub(
        r'(href|src)=["\']https?://web\.archive\.org/web/\d+(?:im_)?/(https?://[^"\']+)["\']',
        r'\1="\2"', raw_html)

    body_html = extract_body_html(raw_html)

    # Normalise image URLs (strip Drupal style paths)
    body_html = re.sub(
        r'(https?://(?:www\.)?ayuryog\.org)/sites/default/files/styles/[^/]+/public/',
        r'\1/sites/default/files/', body_html)

    # Mark YouTube iframes before stripping tags
    body_html = re.sub(
        r'<iframe[^>]+src=["\']https://www\.youtube\.com/embed/([A-Za-z0-9_\-]+)[^"\']*["\'][^>]*>.*?</iframe>',
        r'YOUTUBE_EMBED_\1', body_html, flags=re.DOTALL)

    md = html_to_md(body_html)

    # Restore YouTube embeds
    md = re.sub(
        r'YOUTUBE_EMBED_([A-Za-z0-9_\-]+)',
        lambda m: '\n<div class="video-wrap"><iframe src="https://www.youtube.com/embed/{}"'
                  ' allowfullscreen loading="lazy"></iframe></div>\n'.format(m.group(1)),
        md)

    # Catch any bare YouTube embed URLs
    md = re.sub(
        r'(?m)^\[?(https://www\.youtube\.com/embed/([A-Za-z0-9_\-]+))[^\]]*\]?(?:\(\1\))?\s*$',
        lambda m: '\n<div class="video-wrap"><iframe src="{}"'
                  ' allowfullscreen loading="lazy"></iframe></div>\n'.format(m.group(1)),
        md)

    # Fix internal ayuryog links
    md = re.sub(r'https?://(?:www\.)?ayuryog\.org/blog/', '/blog/', md)
    md = re.sub(r'https?://(?:www\.)?ayuryog\.org/content/', '/', md)

    # Final safety pass: strip any remaining Wayback wrappers in link URLs
    md = unwrap_wayback_in_text(md)

    # Remove boilerplate
    md = re.sub(r'\n+©\s*Ayuryog.*$', '', md, flags=re.DOTALL)
    md = re.sub(r'\n+## Latest Blogposts.*$', '', md, flags=re.DOTALL)
    md = re.sub(r'\n+Title:\s*\n.*$', '', md, flags=re.DOTALL)
    md = re.sub(r'\[Skip to main content\]\(.*?\)\n', '', md)

    # Download ayuryog.org images and rewrite to local paths
    print("  Downloading images...")
    md = localise_images(md)

    # Remove trailing duplicate image blocks
    md = re.sub(r'(\n!\[[^\]]*\]\(/assets/images/posts/[^)]+\)\n){3,}$', '\n', md)

    # Tidy whitespace
    md = re.sub(r'\n{4,}', '\n\n', md)
    md = md.strip()

    # Preserve frontmatter from existing Jekyll file
    with open(post_file, encoding='utf-8') as f:
        existing = f.read()
    fm = re.match(r'^(---\n.*?\n---\n)', existing, re.DOTALL)
    fm = fm.group(1) if fm else '---\n---\n'

    with open(post_file, 'w', encoding='utf-8') as f:
        f.write(fm + '\n' + md + '\n')

    print(f"  Written {len(md)} chars to {post_file}")

# ---------------------------------------------------------------------------

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    html_file, post_file = sys.argv[1], sys.argv[2]
    if not os.path.exists(html_file):
        print(f"Error: HTML file not found: {html_file}"); sys.exit(1)
    if not os.path.exists(post_file):
        print(f"Error: Jekyll post not found: {post_file}"); sys.exit(1)
    print(f"Processing {html_file} -> {post_file}")
    process(html_file, post_file)
    print("Done.")
