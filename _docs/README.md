# cwclark.com — Site Documentation

**Charles Clark · Art Director & Senior Visual Designer**
Live site: https://cwclark.com
Repository: https://github.com/cclark28/cwclark.com
Google Drive: https://drive.google.com/drive/folders/14AaVS3se9Nakyl4XN-S9oe-HaQDDFRHG

---

## Quick Reference

| Task | Command |
|---|---|
| Save + push live | `./_scripts/save.sh "what you changed"` |
| Daily check-in (location/weather) | `./_scripts/checkin.sh` |
| Connect Google Drive (first time) | `./_scripts/gdrive-setup.sh` |
| Push assets to Drive | `./_scripts/gdrive-push.sh` |
| Pull new files from Drive | `./_scripts/gdrive-pull.sh` |
| Run SEO audit | `./_scripts/seo-score.sh` |
| View site history | `./_scripts/history.sh` |
| Roll back to a version | `./_scripts/rollback.sh` |
| Toggle grid overlay | Press **G** on the live site |

---

## What Runs Automatically

| When | What |
|---|---|
| 9:00am daily | Check-in prompt (location + weather popup) |
| Every hour | Pull new files from Google Drive |
| 8:00am daily | SEO audit + score logged to `reports/seo/` |
| After every `save.sh` | Push assets + backup to Google Drive |

---

## Directory Structure

```
cwclark.com/
├── index.html              Main portfolio page
├── info.html               About page
├── works/                  15 project pages
│   ├── terminus.html
│   ├── gungeon.html
│   └── ...
├── style-guide.html        Visual design system reference (not in nav)
├── assets/
│   ├── images/uploads/     Photos synced from Google Drive
│   ├── fonts/              Self-hosted fonts (TG Frekuent Mono)
│   └── graphics/           SVG graphic primitives
├── content/
│   ├── location/current.json   Live location + weather data
│   └── updates/index.json      Check-in history feed
├── reports/
│   └── seo/                Daily SEO audit JSON files
├── _scripts/               All automation scripts
├── _docs/                  This documentation
└── CHANGELOG.md            Auto-updated on every save
```

---

## See also

- [Daily Workflow](daily-workflow.md)
- [Full How-To Guide](how-to-use.md)
- [Google Drive Setup](google-drive.md)
- [SEO Guide](seo.md)
