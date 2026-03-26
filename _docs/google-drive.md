# Google Drive Setup & Sync

All site assets and backups are mirrored to Google Drive automatically.

Drive folder: `cwclark.com/`
URL: https://drive.google.com/drive/folders/14AaVS3se9Nakyl4XN-S9oe-HaQDDFRHG

---

## First-Time Setup (run once)

```
cd ~/cwclark.com
./_scripts/gdrive-setup.sh
```

Opens a browser window for Google OAuth. Sign in with your Google account.
Once authorised, creates this folder structure in your Drive:

```
cwclark.com/
├── assets/
│   ├── images/uploads/     ← drop photos here
│   ├── fonts/
│   └── graphics/
├── content/
│   ├── blog/
│   └── updates/
├── backups/                ← full site ZIP, updated on every push
├── reports/seo/
└── docs/                   ← this documentation
```

---

## How Sync Works

| Direction | Script | When |
|---|---|---|
| Local → Drive | `gdrive-push.sh` | Automatically after every `save.sh` push |
| Drive → Local | `gdrive-pull.sh` | Automatically every hour via LaunchAgent |

### Push manually:
```
./_scripts/gdrive-push.sh
```

### Pull manually:
```
./_scripts/gdrive-pull.sh
```

---

## Adding Photos from Your Phone

1. Open Google Drive on your phone
2. Navigate to `cwclark.com/assets/images/uploads/`
3. Upload photos (JPG, PNG, HEIC, WebP, GIF all supported)
4. Within the hour, `gdrive-pull.sh` downloads them to your local repo and commits them automatically
5. Run `./_scripts/save.sh "Add new photos"` to push them live

---

## What Gets Synced

**Push (local → Drive):**
- `assets/images/uploads/` — all photos
- `assets/fonts/` — self-hosted fonts
- `assets/graphics/` — SVG graphic primitives
- `content/` — all JSON data files
- `_docs/` — this documentation
- A full ZIP backup of the site → `backups/YYYY-MM-DD.zip`

**Pull (Drive → local):**
- Any new files added to the `assets/images/uploads/` folder in Drive
- New files are auto-committed with message "Auto-sync from Drive"

---

## Troubleshooting

### "rclone not found"
```
brew install rclone
```
Then re-run `./_scripts/gdrive-setup.sh`.

### "Authorization failed" or token expired
```
rclone config reconnect cwclark-drive:
```
Follow the browser prompt.

### Check rclone config
```
rclone config show
```
Should show a `[cwclark-drive]` section with `type = drive`.

### Test the connection
```
rclone lsd cwclark-drive:cwclark.com/
```
Lists the top-level folders in the Drive.

---

## LaunchAgent

The hourly pull runs via:
`~/Library/LaunchAgents/com.cwclark.gdrive-pull.plist`

To reload after a restart:
```
launchctl load ~/Library/LaunchAgents/com.cwclark.gdrive-pull.plist
```

To check it's running:
```
launchctl list | grep cwclark
```
