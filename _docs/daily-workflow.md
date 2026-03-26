# Daily Workflow Guide

This is how to keep cwclark.com alive, current, and evolving every day.

---

## Morning Routine (2 minutes)

### 1. Daily Check-In
A popup appears automatically at **9:00am** asking where you are.

If you need to run it manually:
```
cd ~/cwclark.com
./_scripts/checkin.sh
```

**What it does:**
- Asks "Where are you today?" (pre-filled with yesterday's city)
- Fetches live weather for that city (no API key needed)
- Shows a summary: location · condition · temp · wind · humidity
- Saves to `content/location/current.json`
- Updates the instrument strip at the top of the site
- Updates the footer clock weather data
- Saves to the check-in history feed

**The site updates immediately** — the JSON file is read live by JavaScript.

---

## Adding New Photos

### From your phone or camera:
1. Drop photos into your Google Drive folder:
   `cwclark.com/assets/images/uploads/`
2. They sync to the site **automatically within the hour**

### Supported formats:
`jpg` · `jpeg` · `png` · `gif` · `webp` · `heic`

Photos appear in `assets/images/uploads/YYYY-MM/` on the site.

---

## Publishing Changes

### Save and go live:
```
cd ~/cwclark.com
./_scripts/save.sh "Describe what you changed"
```

This will:
1. Commit all changes to git
2. Update CHANGELOG.md automatically
3. Ask if you want to push to GitHub (press Enter for yes)
4. Push assets + site backup to Google Drive in the background
5. Site is live at cwclark.com within ~60 seconds

### Quick push without the script:
```
cd ~/cwclark.com
git add -A && git commit -m "your message"
git push origin master
```

---

## Updating Content

### Change your location manually:
Edit `content/location/current.json` directly:
```json
{
  "city": "New York",
  "region": "New York",
  "country": "United States of America",
  "temp_f": 72,
  "temp_c": 22,
  "condition": "Partly Cloudy",
  "wind_mph": 8,
  "wind_dir": "NW",
  "humidity": 45,
  "emoji": "⛅",
  "updated": "2026-03-26T09:00:00"
}
```
Then run `./_scripts/save.sh "Update location"` to push live.

### Add a blog/update entry:
Edit `content/updates/index.json` — add a new entry at the top:
```json
{
  "id": "2026-03-26",
  "date": "2026-03-26",
  "time": "09:00",
  "city": "New York",
  "region": "New York",
  "country": "United States of America",
  "condition": "Partly Cloudy",
  "temp_f": 72,
  "emoji": "⛅"
}
```

---

## Checking the Site

### View live site:
https://cwclark.com

### Check SEO score:
```
cd ~/cwclark.com
./_scripts/seo-score.sh
```
Results saved to `reports/seo/YYYY-MM-DD.json`

### View change history:
```
cd ~/cwclark.com
./_scripts/history.sh
```

### Roll back to a previous version:
```
cd ~/cwclark.com
./_scripts/rollback.sh
```

---

## Grid Overlay (design check)

On the live site, press **G** to toggle the column grid overlay.

Shows:
- 12 columns with red tint
- 8px baseline grid
- Current breakpoint (XS/SM/MD/LG/XL/2XL/3XL) + viewport width

---

## Weekly

- Run `./_scripts/seo-score.sh` to check visibility trends
- Review `reports/seo/scores.json` for 90-day history
- Add new photos to Google Drive `uploads/` folder
- Run `./_scripts/gdrive-push.sh` to back up latest files
