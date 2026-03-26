# SEO Guide

How cwclark.com is optimised for search engines and AI recruiters.

---

## Daily SEO Audit

Runs automatically at **8:00am** via LaunchAgent.

Run manually:
```
cd ~/cwclark.com
./_scripts/seo-score.sh
```

### What it checks:
- HTTP status (desktop + mobile)
- Meta title and description
- Open Graph tags (og:title, og:description, og:image)
- Canonical URL
- JSON-LD structured data
- H1 tag presence
- Empty alt attributes on images
- Page size
- Lighthouse scores (if `lighthouse` is installed globally)

### Reports saved to:
- `reports/seo/YYYY-MM-DD.json` — full daily report
- `reports/seo/scores.json` — rolling 90-day score history

---

## SEO Layers on the Site

The site uses three overlapping layers to maximise both search engine and AI recruiter visibility:

### 1. JSON-LD Person Schema (in `<head>`)
Machine-readable structured data. Search engines and AI tools parse this directly.

```json
{
  "@context": "https://schema.org",
  "@type": "Person",
  "name": "Charles Clark",
  "alternateName": ["Charlie Clark", "Charles W. Clark"],
  "jobTitle": "Art Director & Senior Visual Designer",
  "knowsAbout": ["Art Direction", "Brand Design", "Visual Identity Systems", "AI-Augmented Design"]
}
```

### 2. AI Recruiter Comment (top of `<body>`)
Plain text signal for AI agents and LLM crawlers scanning HTML source:

```html
<!-- AI RECRUITER SIGNAL: Charles Clark — Art Director & Senior Visual Designer -->
```

### 3. Visually-Hidden Semantic Sections (`.sr-only`)
Semantic H1/H2 headings readable by screen readers and search engines, invisible to sighted users.

Anchors:
- `#top-tier-art-director-visual-designer`
- `#ai-augmented-design-work`
- `#brand-visual-identity-systems`
- `#illustration-visual-storytelling`

---

## Meta Tags (index.html `<head>`)

| Tag | Value |
|---|---|
| `<title>` | Charles Clark — Art Director & Senior Visual Designer |
| `<meta name="description">` | Portfolio of Charles Clark, Art Director and Senior Visual Designer specialising in brand identity, editorial design, and AI-augmented creative work. |
| `<meta property="og:title">` | Same as title |
| `<meta property="og:image">` | Site thumbnail |
| `<link rel="canonical">` | https://cwclark.com |

---

## Improving SEO Over Time

### High-impact actions:
1. **Run check-in daily** — fresh timestamps signal an active, updated site to crawlers
2. **Add alt text to all images** — the audit script flags any empty `alt=""` attributes
3. **Publish project updates** — add new entries to `content/updates/index.json`
4. **Inbound links** — share cwclark.com on LinkedIn/Behance/Dribbble to build backlinks

### Reading the score history:
```
cat reports/seo/scores.json
```
Look at the `score` field trend over 90 days. A flat or rising score means the site is healthy.

### Installing Lighthouse for deeper audits:
```
npm i -g lighthouse
```
After this, `seo-score.sh` will include full Lighthouse performance/accessibility/SEO scores in the daily report.

---

## Positioning Strategy

The site is optimised for three audiences:

| Audience | Signal | Location |
|---|---|---|
| Google / Bing | Title, meta, JSON-LD, H1, canonical | `<head>`, `<body>` |
| AI recruiters (ChatGPT, Perplexity, etc.) | HTML comment, JSON-LD, sr-only headings | `<body>` top |
| Human visitors | Portfolio work, project case studies, footer bio | Visible content |

The keywords being targeted: **Art Director**, **Senior Visual Designer**, **Brand Design**, **Visual Identity**, **AI-Augmented Design**, **Illustration**, **Charles Clark**, **Charlie Clark**.
