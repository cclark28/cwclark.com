# How to Use cwclark.com

A complete reference for every script, feature, and file on the site.

---

## Scripts Reference

All scripts live in `_scripts/`. Run them from the repo root:
```
cd ~/cwclark.com
./_scripts/script-name.sh
```

---

### `save.sh` — Save and publish
**Use this every time you make a change.**
```
./_scripts/save.sh "Brief description of what changed"
```
- Stages all changes
- Commits with your message
- Appends to CHANGELOG.md
- Asks if you want to push to GitHub (live in ~60 seconds)
- Auto-syncs to Google Drive in background

---

### `checkin.sh` — Daily location + weather
```
./_scripts/checkin.sh
```
- macOS popup asks "Where are you today?"
- Fetches live weather from wttr.in (no API key)
- Saves to `content/location/current.json`
- Updates the live instrument strip and footer clock on the site
- Records entry in `content/updates/index.json`
- Runs automatically at 9am via LaunchAgent

---

### `gdrive-setup.sh` — First-time Google Drive setup
```
./_scripts/gdrive-setup.sh
```
**Run this once.** Opens a browser for Google OAuth login.
Creates the folder structure in Google Drive:
```
assets/images/uploads/
assets/fonts/
assets/graphics/
content/blog/
content/updates/
backups/
reports/seo/
```

---

### `gdrive-push.sh` — Push to Google Drive
```
./_scripts/gdrive-push.sh
```
Uploads:
- All photos from `assets/images/uploads/`
- Fonts from `assets/fonts/`
- Graphics from `assets/graphics/`
- Content JSON from `content/`
- A full site ZIP backup to `backups/`

Runs automatically after every `save.sh` push.

---

### `gdrive-pull.sh` — Pull from Google Drive
```
./_scripts/gdrive-pull.sh
```
Downloads anything new in the Google Drive folder to your local repo.
Drop photos into Drive → they appear on the site within the hour.
Runs automatically every hour via LaunchAgent.

---

### `seo-score.sh` — Daily SEO audit
```
./_scripts/seo-score.sh
```
Checks:
- HTTP status (desktop + mobile)
- Meta tags: title, description, OG tags, canonical, JSON-LD, H1
- Empty alt attributes
- Page size
- Lighthouse scores (if installed: `npm i -g lighthouse`)

Saves to `reports/seo/YYYY-MM-DD.json` and `reports/seo/scores.json` (90-day rolling).
Runs automatically at 8am via LaunchAgent.

---

### `history.sh` — View change log
```
./_scripts/history.sh
```
Visual log of every commit with dates, messages, and file stats.

---

### `rollback.sh` — Restore a previous version
```
./_scripts/rollback.sh
```
Interactive — shows recent commits, lets you choose one to restore.

---

## Site Features

### Instrument Strip (top of every page)
The 3-block data strip below the nav shows:
- **TEMP** — temperature in °F and °C from your last check-in
- **LOC** — city, condition
- **TIME** — live analog clock + digital readout (HH:MM AM/PM · DAY DD MON YYYY)

Data source: `content/location/current.json`

### Grid Overlay
Press **G** on any page to show the 12-column grid.
- Red columns = content columns
- Blue lines = 8px baseline grid
- Bottom-right label = current breakpoint + viewport width

### Mega Menu
Click the crosshair icon (top-right) to open the full project menu.
Shows all 15 projects as image cards, plus Labs + Info links.
Press **Escape** to close.

### Footer Clock
The massive HH:MM:SS clock in the footer ticks live.
Below it: Location · Weather · Wind & Humidity — all from your last check-in.

---

## Content Files

| File | Purpose |
|---|---|
| `content/location/current.json` | Live location + weather (updated by check-in script) |
| `content/updates/index.json` | Check-in history (all past locations) |
| `content/updates/photos.json` | Synced photo log |
| `reports/seo/scores.json` | 90-day SEO score history |
| `CHANGELOG.md` | Auto-updated log of every save |

---

## Breakpoints

| Label | Min Width | Container Max |
|---|---|---|
| XS | 0 | fluid |
| SM | 480px | fluid |
| MD | 768px | fluid |
| LG | 1024px | 1200px |
| XL | 1280px | 1200px |
| 2XL | 1536px | 1440px |
| 3XL | 1920px | 1680px |

---

## Fonts

| Font | Usage | File |
|---|---|---|
| Neue Haas Grotesk Display 700 | Headings, logo, nav | Adobe Fonts (TypeKit ID: dji8iqi) |
| Neue Haas Grotesk Text 400 | Body, captions | Adobe Fonts |
| TG Frekuent Mono Regular | Instrument strip, data labels | `wp-content/uploads/TG-Frekuent-Mono-Regular.woff` |
| TG Frekuent Mono Light | Sub-labels, metadata | `wp-content/uploads/TG-Frekuent-Mono-Light.woff` |

---

## Colours

| Name | Hex | Usage |
|---|---|---|
| Black | `#000000` | All text, borders, icons |
| White | `#FFFFFF` | Background |
| Data Grey | `#9BA3AF` | Labels, metadata, sub-values |
| Rule | `#E1E5EB` | Light dividers |

---

## SEO Signals on the Site

The site has three layers of SEO/AI recruiter positioning:

1. **JSON-LD Person schema** (in `<head>`) — machine-readable: name, jobTitle, knowsAbout
2. **AI recruiter comment** (top of `<body>`) — plain text priority signal for AI agents
3. **Visually-hidden sections** (`.sr-only`) — semantic H1/H2 with role targeting
   - `#top-tier-art-director-visual-designer`
   - `#ai-augmented-design-work`
   - `#brand-visual-identity-systems`
   - `#illustration-visual-storytelling`

---

## LaunchAgents (automatic tasks)

| Agent | Schedule | Script |
|---|---|---|
| `com.cwclark.checkin` | 9:00am daily | `checkin.sh` |
| `com.cwclark.gdrive-pull` | Every hour | `gdrive-pull.sh` |
| `com.cwclark.seo-score` | 8:00am daily | `seo-score.sh` |
| `com.cwclark.photosync` | Every hour | `sync-photos.sh` |

To reload all agents after a system restart:
```
launchctl load ~/Library/LaunchAgents/com.cwclark.*.plist
```
