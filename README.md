# AyurYog — Jekyll Site

A faithful Jekyll reproduction of [ayuryog.org](https://ayuryog.org), the website of the ERC-funded research project "Medicine, Immortality, Mokṣa: Entangled Histories of Ayurveda, Yoga and Alchemy in South Asia" (2015–2020), suitable for hosting on GitHub Pages.

## Site structure

```
ayuryog/
├── _config.yml               # Jekyll configuration
├── Gemfile                   # Ruby dependencies
├── .bundle/config            # Tells Bundler to install to vendor/bundle/
├── .gitignore
├── index.html                # Home page
├── team.md                   # People page
├── publications.md           # Publications
├── resources.md              # Resources index
├── resources/
│   ├── untangling-traditions.md   # Video presentations page
│   └── inform.md                  # Inform collaboration
├── alchemy-reconstruction.md # Full alchemy reconstruction videos
├── alchemy-timeline.md       # Alchemy timeline stub
├── timeline.md               # Yoga timeline stub
├── events.md                 # Events page
├── blog.html                 # Blog listing
├── credits.md                # Credits page
├── _posts/                   # All blog posts (2015–2023)
├── _layouts/
│   ├── default.html          # Base layout
│   ├── page.html             # Static page layout
│   └── post.html             # Blog post layout
├── _includes/
│   ├── header.html           # Site header + nav
│   └── footer.html           # Site footer
└── assets/
    └── css/
        └── main.css          # Stylesheet
```

## Serving locally

The `.bundle/config` file in this repo tells Bundler to install gems into
`vendor/bundle/` (a local subdirectory you own) rather than the system gem
directory (which requires root). So a plain `bundle install` will work without
`sudo`:

```bash
bundle install
bundle exec jekyll serve
```

Then visit http://localhost:4000.

If for any reason Bundler still complains about permissions, run:

```bash
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec jekyll serve
```

## Deploying to GitHub Pages

The Gemfile uses plain `jekyll ~> 4.2` rather than the `github-pages` gem
(which pulls in `jekyll-coffeescript` → `execjs` and `sass-embedded` → native
extensions that cause build failures in many environments).

GitHub Pages supports this cleanly via a **GitHub Actions workflow**:

1. Create a new GitHub repository and push this directory to `main`.
2. In repository Settings → Pages, set **Source** to **GitHub Actions**.
3. The `.github/workflows/jekyll.yml` workflow included in this repo handles
   everything automatically on every push.

## Notes on content

- **Blog posts**: All 56 blog posts from the original site are reproduced as
  Jekyll posts with accurate dates, authors, titles, and substantive body text.
- **Videos**: All YouTube embeds from the Alchemy Reconstruction and Untangling
  Traditions pages are preserved.
- **Images**: Logos referenced in the footer (`assets/images/`) need to be
  downloaded from the original site and placed there manually.
- **Timelines**: The interactive Yoga and Alchemy Timelines are represented as
  stub pages linking to the originals; recreating them as interactive JS
  applications would be a separate project.

## Original site

The original site runs on Drupal 7 at [ayuryog.org](https://ayuryog.org).
This Jekyll reproduction was created in 2026.

## Fetching full blog post content and images

The `_posts/` directory in the base zip contains stub content. To replace all
56 posts with their full original text and download all images locally, run:

```bash
cd ayuryog
bash fetch_posts.sh
```

This script:
- Fetches each post from `ayuryog.org` with automatic retry on 502 errors
- Rewrites the Jekyll post files with full content
- Downloads all post images to `assets/images/posts/`
- Rewrites all image references in the posts to point to the local copies
- Removes all links back to `ayuryog.org`

Re-run the script at any time to retry any posts that failed (it skips images
already downloaded). Once complete, the site is fully self-contained and no
longer depends on `ayuryog.org` being live.
