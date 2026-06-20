#!/usr/bin/env bash
# Comprehensive AyurYog archive script.
#
# What it does:
#   1. Fetches each blog post from ayuryog.org and saves the RAW HTML to _raw_html/posts/
#   2. Converts the HTML to Markdown (for Jekyll) and writes _posts/*.md
#   3. Fetches each past event detail page, saves RAW HTML to _raw_html/events/
#   4. Creates a full Jekyll page for each event under events/
#   5. Downloads all images from ayuryog.org to assets/images/posts/
#
# Run from inside the ayuryog/ directory:
#   bash fetch_all.sh
#
# Requirements: python3 (standard library only), internet access to ayuryog.org
#
# Re-running is safe: already-downloaded images are skipped; raw HTML and
# Jekyll files are overwritten with fresh content on each run.

python3 - << 'PYEOF'
import urllib.request, urllib.error, re, os, time, sys, urllib.parse, html as html_mod

# ── Directory setup ───────────────────────────────────────────────────────────
for d in ("_raw_html/posts", "_raw_html/events", "_posts",
          "events", "assets/images/posts"):
    os.makedirs(d, exist_ok=True)

BASE_BLOG  = "https://www.ayuryog.org/blog/"
BASE_EVENT = "https://www.ayuryog.org/event/"

# ── Blog posts: (jekyll filename, url slug) ───────────────────────────────────
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
    ("2020-05-26-mapping-alchemical-manuscripts.md",                    "mapping-alchemical-manuscripts"),
    ("2020-05-26-dharmaputrika-chapter-ten.md",                         "medical-treatment-context-yoga-practice-yogacikits%C4%81-chapter-ten-dharmaputrik%C4%81"),
    ("2020-05-26-second-procedure-trituration-mardana.md",              "second-procedure-trituration-mardana"),
    ("2020-05-25-first-procedure-according-to-others.md",               "we-are-not-only-ones-first-procedure-according-others"),
    ("2020-05-18-philology-and-experimentation.md",                     "philology-and-experimentation-reconstructing-alchemical-procedures"),
    ("2020-03-27-epidemics-isolation-prevention.md",                    "epidemics-isolation-and-prevention"),
    ("2020-02-20-recreating-alchemical-operations.md",                  "recreating-alchemical-operations"),
    ("2019-12-20-yogis-adepts-experts-who-were-alchemists.md",          "yogis-adepts-experts-who-were-alchemists"),
    ("2019-12-02-avoiding-fundamentalist-histories.md",                 "avoiding-fundamentalist-histories-%E2%80%93-ayuryog-and-launch-yoga-britain"),
    ("2019-10-07-visualizing-alchemical-spaces.md",                     "visualizing-alchemical-spaces"),
    ("2019-09-05-life-after-death-beliefs.md",                          "how-think-about-life-after-death-beliefs"),
    ("2019-07-05-exploring-immortality.md",                             "exploring-immortality"),
    ("2019-06-25-ayurveda-and-alchemy.md",                              "ayurveda-and-alchemy"),
    ("2019-05-24-what-is-the-role-of-the-teacher.md",                   "what-role-teacher"),
    ("2019-04-03-yoga-daoism-and-alchemy.md",                           "yoga-daoism-and-alchemy"),
    ("2018-11-16-yoga-ayurveda-sahapedia.md",                           "yoga-and-%C4%81yurveda-article-sahapedia-0"),
    ("2018-09-18-erccomics-roots-ayurveda.md",                          "roots-ayurveda-erccomics-about-ayuryog"),
    ("2018-08-08-postdoc-position-alberta.md",                          "history-south-asian-alchemy-post-doctoral-position-department-history-and-classics"),
    ("2018-06-05-connecting-threads-yoga-ayurveda.md",                  "connecting-threads-convergence-yoga-and-ayurveda-1900-present"),
    ("2018-04-03-transmutations-publication.md",                        "publication-announcement-transmutations-rejuvenation-longevity-and-immortality-practices-south"),
    ("2017-11-20-ayurveda-to-biomedicine.md",                           "ayurveda-biomedicine-understanding-human-body"),
    ("2017-10-03-seeds-of-modern-yoga-ayurvedasutra.md",                "seeds-modern-yoga-confluence-yoga-and-ayurveda-%C4%81yurvedas%C5%ABtra"),
    ("2017-09-14-philology-through-experiment.md",                      "philology-through-experiment"),
    ("2017-08-17-conference-videos-medicine-yoga.md",                   "videos-conference-medicine-and-yoga-south-and-inner-asia-august-1-3-2017"),
    ("2017-06-20-revival-yoga-contemporary-india.md",                   "revival-yoga-contemporary-india"),
    ("2017-03-31-conference-programme-medicine-yoga.md",                "conference-programme-medicine-and-yoga-south-and-inner-asia-body-cultivation-therapeutic"),
    ("2017-03-13-how-to-respond-to-yogic-powers.md",                    "how-respond-yogic-powers"),
    ("2017-02-14-krishnamacharya-yoga-indigenous-medicine.md",          "krishnamacharya-yoga-indigenous-medicine"),
    ("2017-01-19-eight-yoga-postures-dharmaputrika.md",                 "eight-yoga-postures-dharmaputrik%C4%81"),
    ("2017-01-09-recipes-for-immortality.md",                           "recipes-immortality-and-intoxicating-alchemy-south-and-inner-asia"),
    ("2016-10-21-workshop-rasayana-kayakalpa.md",                       "ayuryog-workshop-rejuvenation-longevity-immortality-perspectives-ras%C4%81yana-k%C4%81yakalpa-and-bcud"),
    ("2016-07-04-what-is-tradition.md",                                 "what-%E2%80%98tradition%E2%80%99-%E2%80%93-entanglements-and-metaphors"),
    ("2016-04-20-a-word-on-resources.md",                               "word-resources"),
    ("2016-02-29-arion-rosu-collection.md",                             "arion-ro%C5%9Fu-collection-institute-indian-studies-coll%C3%A8ge-de-france"),
    ("2016-01-07-untangling-histories-commencing-the-project.md",       "untangling-histories-%E2%80%93-commencing-project"),
    ("2015-12-29-mercury-in-medicine-publication.md",                   "publication-announcement-mercury-medicine-across-asia-and-beyond"),
    ("2015-12-16-ayurveda-influence-medieval-yoga.md",                  "did-ayurveda-influence-medieval-yoga-traditions-preliminary-remarks-their-shared-terminology"),
    ("2015-11-30-welcome.md",                                           "welcome"),
]

# Past event URL slugs → Jekyll filename stem
EVENTS = [
    ("conference-history-science-and-philosophy-premodern-india",           "conference-history-science-philosophy-premodern-india"),
    ("book-launch",                                                          "book-launch-sauthoff-2022"),
    ("let-vaidyas-speak-translating-usman-report",                          "let-vaidyas-speak-usman-report"),
    ("launch-rasa%C5%9B%C4%81stra-timeline-sanskrit-alchemical-literature", "launch-rasashastra-timeline"),
    ("exhibition-longevity-timeline-yoga-and-ayurveda",                     "exhibition-longevity-timeline"),
    ("untangling-traditions-yoga-ayurveda-and-alchemy",                     "untangling-traditions-conference-2020"),
    ("inform-ayuryog-seminar-immortality-beliefs-and-practices",            "inform-seminar-immortality-2020"),
    ("christ%C3%A8le-barois-m%C4%81rga-dharmaputrik%C4%81-path-bodily-winds-archery-metaphor", "barois-marga-dharmaputrika-2019"),
    ("water-elixir-longevity-ras%C4%81yana-practice-%C4%81nandakanda",      "sauthoff-water-elixir-rasayana-2019"),
    ("yoga-britain-book-launch-and-reception-dialogue-suzanne-newcombe-and-mark-singleton", "yoga-in-britain-book-launch-2019"),
    ("femininities-and-masculinities-medieval-south-asia-translating-terminology-intersectional", "sauthoff-femininities-masculinities-2019"),
    ("alchemical-spaces-and-tantric-traditions",                             "sauthoff-alchemical-spaces-2019"),
    ("usman-report-resource-siddha-medicine-yoga-and-alchemy",              "barois-usman-report-siddha-2019"),
    ("suzanne-newcombe-speaks-between-worlds-yogis-body-jumping-immortality-and-kayakalpa-practices", "newcombe-inbetween-worlds-yogis-2019"),
    ("alchemy-daoism-and-ha%E1%B9%ADha-yoga-discussion-professor-louis-komjathy-university-san-diego-and-dr", "alchemy-daoism-hatha-yoga-2019"),
    ("guest-lecture-yoga-and-health-modern-india-0",                        "newcombe-yoga-health-modern-india-2019"),
    ("presentation-dagmar-wujastyk-old-substances-new-understandings-iron-tonics-and-roots-ayurvedic", "wujastyk-old-substances-iron-tonics-2019"),
    ("ayuryog-and-ha%E1%B9%ADha-yoga-project-erccomics-event",              "erccomics-event-2018"),
    ("suzanne-newcombe-speaks-immortality-and-miracle-cures-stretching-language-yoga-and-ayurveda", "newcombe-immortality-miracle-cures-2018"),
    ("suzanne-newcombe-speaks-body-contemporary-yoga-and-ayurveda",         "newcombe-body-contemporary-yoga-2018"),
    ("lecture-christ%C3%A8le-barois-la-production-de-la-couleur-selon-la-m%C3%A9decine-classique-indienne", "barois-production-couleur-2018"),
    ("suzanne-newcombe-presents-%E2%80%98-status-indigenous-medicine-india-colonial-period-present%E2%80%99", "newcombe-indigenous-medicine-status-2018"),
    ("doctor-india-film-screening-and-discussion-soas-university-london",    "doctor-from-india-film-2018"),
    ("public-discussion-what-yoga-london-23-september-2018",                 "newcombe-what-is-yoga-2018"),
    ("presentation-dagmar-wujastyk-medicine-and-alchemy-kaly%C4%81%E1%B9%87ak%C4%81raka", "wujastyk-kalyanakara-wsc-2018"),
    ("presentation-christ%C3%A8le-barois-list-sixty-four-yoga-powers-%C5%9Baiva-pur%C4%81%E1%B9%87ic-literature", "barois-sixty-four-yoga-powers-wsc-2018"),
    ("yoga-and-ayurveda-panel-17th-world-sanskrit-conference",               "wsc-yoga-ayurveda-panel-2018"),
    ("suzanne-newcombe-speaking-1923-usman-report-indigenous-medicine",      "newcombe-usman-report-yoga-day-2018"),
    ("presentation-dagmar-wujastyk-verj%C3%BCngungskuren-im-ayurveda-fragen-zu-autorit%C3%A4t-authentizit%C3%A4t", "wujastyk-verjuengungskuren-2018"),
    ("ayuryog-opening-soas-centre-yoga-studies",                             "ayuryog-soas-centre-yoga-studies-2018"),
    ("images-indian-gods-and-objects-immortality",                           "newcombe-british-museum-2018"),
    ("guest-lecture-yoga-and-health-modern-india",                           "newcombe-yoga-health-modern-india-2018"),
    ("presentation-dagmar-wujastyk-ayuryog-entangled-histories-yoga-ayurveda-and-alchemy-south-asia", "wujastyk-ayuryog-presentation-2018"),
    ("interview-suzanne-newcombe-authenticity-and-transformations-yoga-traditions-online-conference", "newcombe-authenticity-transformations-2018"),
    ("presentation-dagmar-wujastyk-healthcare-and-longevity-practices-yoga-ayurveda-and-rasa%C5%9B%C4%81stra", "wujastyk-healthcare-longevity-2018"),
    ("medical-practices-yogins-medieval-india-case-dharmaputrik%C4%81",      "barois-medical-practices-yogins-2017"),
    ("yoga-ayurveda-magic-and-alchemy",                                      "newcombe-yoga-ayurveda-magic-alchemy-2017"),
    ("presentation-dagmar-wujastyk-potent-panaceas-tracing-development-plant%E2%80%90based-medicine", "wujastyk-potent-panaceas-2017"),
    ("presentation-suzanne-newcombe-longevity-practices-india-during-modern-period-public-health", "newcombe-longevity-modern-india-2017"),
    ("conference-medicine-and-yoga-south-and-inner-asia-body-cultivation-therapeutic-intervention", "conference-medicine-yoga-south-inner-asia-2017"),
    ("presentation-dagmar-wujastyk-ras%C4%81yana-sanskrit-alchemical-literature", "wujastyk-rasayana-alchemical-lit-2017"),
    ("presentation-christ%C3%A8le-barois-longevity-practices-ch%C4%81ndogya-upani%E1%B9%A3ad-onwards", "barois-longevity-chandogya-2017"),
    ("presentation-suzanne-newcombe-historical-overview-yoga-medical-intervention", "newcombe-yoga-medical-intervention-2017"),
    ("panel-discussion-vienna-international-centre-international-yoga-day",  "newcombe-vienna-yoga-day-2017"),
    ("philosophy-contemporary-yoga-symposium-triyoga-london",                "philosophy-yoga-triyoga-2017"),
    ("christ%C3%A8le-barois-dharmaputrik%C4%81-textual-apparatus-yoga",      "barois-dharmaputrika-pondicherry-2017"),
    ("guest-lecture-suzanne-newcombe-yoga-modern-period",                    "newcombe-yoga-modern-period-soas-2017"),
    ("presentation-suzanne-newcombe-immortality-and-medical-interventions-sadhus", "newcombe-immortality-sadhus-2017"),
    ("presentation-christ%C3%A8le-barois-medical-practices-and-yoga-case-dharmaputrik%C4%81-pratiques", "barois-dharmaputrika-strasbourg-2016"),
    ("ayuryog-workshop-rejuvenation-longevity-immortality-perspectives-ras%C4%81yana-k%C4%81yakalpa-and-bcud", "workshop-rasayana-kayakalpa-2016"),
    ("presentation-christ%C3%A8le-barois-dharmaputrik%C4%81-sept-12-1630-1730", "barois-dharmaputrika-soas-2016"),
    ("dagmar-wujastyk-herbal-based-medicine-iatrochemistry-system-changes-classical-indian-medicine", "wujastyk-iatrochemistry-shot-2016"),
    ("bbc-radio-4-secret-history-yoga",                                      "bbc-secret-history-yoga-2016"),
    ("suzanne-newcombe-relaxation-20th-century-yoga-key-health-beauty-and-eternal-youth", "newcombe-relaxation-yoga-2016"),
    ("conference-yogadar%C5%9Bana-yogas%C4%81dhana-traditions-transmissions-transformations", "conference-yogadarsana-krakow-2016"),
    ("presentation-suzanne-newcombe-entangled-histories-yoga-ayurveda-and-rasa%C5%9B%C4%81stra", "newcombe-entangled-histories-cambridge-2016"),
    ("presentation-suzanne-newcombe-yoga-ayurveda-and-alchemy-modern-period", "newcombe-yoga-ayurveda-alchemy-ou-2016"),
    ("radio-interview-dagmar-wujastyk-radiodoktor-das-%C3%B61-gesundheitsmagazin", "wujastyk-radiodoktor-2016"),
    ("lecture-christ%C3%A8le-barois-few-remarks-textual-organization-yoga-and-ayurveda-materials", "barois-textual-organization-ehess-2015"),
    ("suzanne-newcombe-%E2%80%98yoga-ayurveda-and-immortality-case-swami-ramdev%E2%80%99", "newcombe-swami-ramdev-basr-2015"),
]

# ── Network helper ────────────────────────────────────────────────────────────

def fetch_html(url, retries=5, delay=4):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as e:
            if e.code == 502 and attempt < retries - 1:
                wait = delay * (attempt + 1)
                print(f"\n  502, retrying in {wait}s...", end="", flush=True)
                time.sleep(wait)
            else:
                print(f"\n  HTTP {e.code}: {url}", file=sys.stderr)
                return None
        except Exception as e:
            print(f"\n  ERROR: {e}", file=sys.stderr)
            return None

# ── Image downloader ──────────────────────────────────────────────────────────

def download_image(src):
    """Download an ayuryog.org image to assets/images/posts/. Returns local path or None."""
    if not src or "ayuryog.org" not in src:
        return None
    src = re.sub(r"/sites/default/files/styles/[^/]+/public/", "/sites/default/files/", src)
    src = re.sub(r"^http://", "https://", src)
    fname = urllib.parse.unquote(src.split("/")[-1].split("?")[0])
    local = os.path.join("assets/images/posts", fname)
    if os.path.exists(local):
        return local
    try:
        req = urllib.request.Request(src, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            with open(local, "wb") as f:
                f.write(r.read())
        return local
    except Exception as e:
        print(f"\n    IMG FAIL {fname}: {e}", file=sys.stderr)
        return None

# ── HTML → Markdown ───────────────────────────────────────────────────────────

def html_to_md(body_html):
    """Convert a Drupal body HTML fragment to Markdown, preserving all content."""
    h = body_html

    # Strip Drupal image style prefixes before anything else
    h = re.sub(
        r"(https?://(?:www\.)?ayuryog\.org)/sites/default/files/styles/[^/]+/public/",
        r"\1/sites/default/files/", h)

    # YouTube iframes → marker
    h = re.sub(
        r'<iframe[^>]+src=["\']https://www\.youtube\.com/embed/([A-Za-z0-9_\-]+)[^"\']*["\'][^>]*>.*?</iframe>',
        r"YOUTUBE_EMBED_\1", h, flags=re.DOTALL)

    # Block elements
    h = re.sub(r"<br\s*/?>", "  \n", h)
    h = re.sub(r"<hr[^>]*/?>", "\n---\n", h)
    h = re.sub(r"</?p[^>]*>", "\n\n", h)
    h = re.sub(r"</?div[^>]*>", "\n", h)
    h = re.sub(r"</?blockquote[^>]*>", "\n> ", h)
    h = re.sub(r"</?li[^>]*>", "\n- ", h)
    h = re.sub(r"</?[uo]l[^>]*>", "\n", h)
    h = re.sub(r"<h([1-6])[^>]*>(.*?)</h\1>",
               lambda m: "\n" + "#" * int(m.group(1)) + " " +
               re.sub("<[^>]+>", "", m.group(2)).strip() + "\n",
               h, flags=re.DOTALL)

    # Inline elements
    h = re.sub(r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>(.*?)</a>',
               r"[\2](\1)", h, flags=re.DOTALL)
    # Images: try alt before src, then src only
    h = re.sub(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*/?>',
               r"![\2](\1)", h)
    h = re.sub(r'<img[^>]+alt=["\']([^"\']*)["\'][^>]+src=["\']([^"\']+)["\'][^>]*/?>',
               r"![\1](\2)", h)
    h = re.sub(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*/?>',
               r"![](\1)", h)
    h = re.sub(r"<(?:em|i)[^>]*>(.*?)</(?:em|i)>", r"*\1*", h, flags=re.DOTALL)
    h = re.sub(r"<(?:strong|b)[^>]*>(.*?)</(?:strong|b)>", r"**\1**", h, flags=re.DOTALL)
    h = re.sub(r"<(?:code)[^>]*>(.*?)</code>", r"`\1`", h, flags=re.DOTALL)

    # Strip remaining tags
    h = re.sub(r"<[^>]+>", "", h)

    # Decode entities
    h = html_mod.unescape(h)

    # Restore YouTube embeds
    h = re.sub(
        r"YOUTUBE_EMBED_([A-Za-z0-9_\-]+)",
        lambda m: '\n<div class="video-wrap"><iframe src="https://www.youtube.com/embed/{}" allowfullscreen loading="lazy"></iframe></div>\n'.format(m.group(1)),
        h)

    # Fix internal links
    h = re.sub(r"https?://(?:www\.)?ayuryog\.org/blog/", "/blog/", h)
    h = re.sub(r"https?://(?:www\.)?ayuryog\.org/content/", "/", h)
    h = re.sub(r"https?://(?:www\.)?ayuryog\.org/event/", "/events/", h)

    # Tidy whitespace
    h = re.sub(r"\n{4,}", "\n\n", h)
    return h.strip()

# ── Content extraction ────────────────────────────────────────────────────────

def extract_teaser_image_src(html):
    m = re.search(
        r'class="[^"]*field-name-field-teaser-image[^"]*".*?<img[^>]+src=["\']([^"\']+)["\']',
        html, re.DOTALL)
    return m.group(1) if m else None

def extract_body_html(html):
    """Return the raw inner HTML of the Drupal body field, unchanged."""
    # Drupal 7 field-name-body → field-items → field-item
    m = re.search(
        r'class="[^"]*field-name-body[^"]*".*?'
        r'class="[^"]*field-items[^"]*".*?'
        r'class="[^"]*field-item[^"]*"[^>]*>(.*?)'
        r'</div>\s*</div>\s*</div>',
        html, re.DOTALL)
    if m:
        return m.group(1)
    # Fallback: article body between h1.page-header and tags/footer
    m = re.search(
        r'<h1[^>]+class="[^"]*page-header[^"]*"[^>]*>.*?</h1>(.*?)'
        r'(?:<div[^>]+class="[^"]*field-name-field-tags|<footer)',
        html, re.DOTALL)
    if m:
        return m.group(1)
    # Last resort
    m = re.search(r'<article[^>]*>(.*?)</article>', html, re.DOTALL)
    return m.group(1) if m else html

def localise_images_in_md(md):
    """Download all ayuryog.org images referenced in md, rewrite to local paths."""
    def replace(m):
        alt, src = m.group(1), m.group(2)
        local = download_image(src)
        return f"![{alt}](/{local})" if local else m.group(0)
    return re.sub(r"!\[([^\]]*)\]\(([^)]+)\)", replace, md)

BOILERPLATE = re.compile(
    r"\n+©\s*Ayuryog.*$"
    r"|\n+## Latest Blogposts.*$"
    r"|\n+Title:\s*\n.*$"
    r"|\[Skip to main content\]\(.*?\)\n?",
    re.DOTALL)

def clean(md):
    return BOILERPLATE.sub("", md).strip()

def get_frontmatter(filepath):
    if not os.path.exists(filepath):
        return None
    with open(filepath, encoding="utf-8") as f:
        content = f.read()
    m = re.match(r"^(---\n.*?\n---\n)", content, re.DOTALL)
    return m.group(1) if m else None

# ── Extract page title ────────────────────────────────────────────────────────

def extract_title(html):
    m = re.search(r'<h1[^>]*class="[^"]*page-header[^"]*"[^>]*>(.*?)</h1>', html, re.DOTALL)
    if m:
        return re.sub(r"<[^>]+>", "", m.group(1)).strip()
    m = re.search(r'<title>(.*?)(?:\s*\|.*?)?</title>', html)
    return re.sub(r"<[^>]+>", "", m.group(1)).strip() if m else "Event"

# ─────────────────────────────────────────────────────────────────────────────
# 1. BLOG POSTS
# ─────────────────────────────────────────────────────────────────────────────

print("=" * 60)
print("BLOG POSTS")
print("=" * 60)

ok, failed = 0, []

for filename, slug in POSTS:
    post_path = os.path.join("_posts", filename)
    raw_path  = os.path.join("_raw_html/posts", slug.replace("%", "_") + ".html")

    print(f"  {slug[:58]}...", end=" ", flush=True)

    html = fetch_html(BASE_BLOG + slug)
    if html is None:
        print("FAILED")
        failed.append((filename, slug))
        time.sleep(1)
        continue

    # Save raw HTML backup
    with open(raw_path, "w", encoding="utf-8") as f:
        f.write(html)

    # Extract teaser image
    teaser_src = extract_teaser_image_src(html)
    teaser_md = ""
    if teaser_src:
        local = download_image(teaser_src)
        if local:
            teaser_md = f"![](/{local})\n\n"

    # Extract body and convert
    body_html = extract_body_html(html)
    md = html_to_md(body_html)
    md = localise_images_in_md(md)
    md = clean(md)

    # Preserve existing frontmatter
    fm = get_frontmatter(post_path)
    if fm is None:
        print(f"WARN: no frontmatter in {filename}")
        fm = "---\n---\n"

    with open(post_path, "w", encoding="utf-8") as f:
        f.write(fm + "\n" + teaser_md + md + "\n")

    print(f"OK ({len(md)} chars)")
    ok += 1
    time.sleep(0.5)

print(f"\nBlog posts: {ok} OK, {len(failed)} failed")
if failed:
    print("Failed (re-run to retry):")
    for fn, sl in failed:
        print(f"  {sl}")

# ─────────────────────────────────────────────────────────────────────────────
# 2. PAST EVENT DETAIL PAGES
# ─────────────────────────────────────────────────────────────────────────────

print("\n" + "=" * 60)
print("PAST EVENT PAGES")
print("=" * 60)

event_ok, event_failed = 0, []

# Map from event URL slug → Jekyll filename stem, for pastevents.md links
slug_to_jekyll = {}

for event_slug, jekyll_stem in EVENTS:
    url        = BASE_EVENT + event_slug
    raw_path   = os.path.join("_raw_html/events", jekyll_stem + ".html")
    jekyll_path = os.path.join("events", jekyll_stem + ".md")
    permalink  = f"/events/{jekyll_stem}/"

    print(f"  {event_slug[:58]}...", end=" ", flush=True)

    html = fetch_html(url)
    if html is None:
        print("FAILED")
        event_failed.append(event_slug)
        time.sleep(1)
        continue

    # Save raw HTML backup
    with open(raw_path, "w", encoding="utf-8") as f:
        f.write(html)

    title = extract_title(html)

    # Extract teaser image
    teaser_src = extract_teaser_image_src(html)
    teaser_md = ""
    if teaser_src:
        local = download_image(teaser_src)
        if local:
            teaser_md = f"![](/{local})\n\n"

    # Extract body
    body_html = extract_body_html(html)
    md = html_to_md(body_html)
    md = localise_images_in_md(md)
    md = clean(md)

    # Write Jekyll page
    fm = f'---\nlayout: page\ntitle: "{title.replace(chr(34), chr(39))}"\npermalink: {permalink}\n---\n'
    with open(jekyll_path, "w", encoding="utf-8") as f:
        f.write(fm + "\n" + teaser_md + md + "\n")

    slug_to_jekyll[event_slug] = (jekyll_stem, title)
    print(f"OK ({len(md)} chars)")
    event_ok += 1
    time.sleep(0.5)

print(f"\nEvent pages: {event_ok} OK, {len(event_failed)} failed")
if event_failed:
    print("Failed:")
    for s in event_failed:
        print(f"  {s}")

# ─────────────────────────────────────────────────────────────────────────────
# 3. REGENERATE pastevents.md with links to full event pages
# ─────────────────────────────────────────────────────────────────────────────

print("\nRewriting pastevents.md...")

# Read existing pastevents.md and replace each remote ayuryog event link
# with the local Jekyll event page link
pe_path = "pastevents.md"
if os.path.exists(pe_path):
    with open(pe_path, encoding="utf-8") as f:
        pe = f.read()
    # Replace any remaining ayuryog.org/event/ links with local ones
    for event_slug, (jekyll_stem, title) in slug_to_jekyll.items():
        decoded_slug = urllib.parse.unquote(event_slug)
        # Match either encoded or decoded form
        for pat in (event_slug, decoded_slug):
            pe = pe.replace(
                f"https://www.ayuryog.org/event/{pat}",
                f"/events/{jekyll_stem}/")
            pe = pe.replace(
                f"http://ayuryog.org/event/{pat}",
                f"/events/{jekyll_stem}/")
    with open(pe_path, "w", encoding="utf-8") as f:
        f.write(pe)
    print("  pastevents.md updated.")
else:
    print("  pastevents.md not found — skipping.")

print("\nAll done.")
PYEOF
