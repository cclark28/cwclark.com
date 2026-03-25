# Lessons Learned — cwclark.com

Running log of corrections and patterns to avoid repeating.
Updated after every user correction. Reviewed at session start.

---

## L001 — 2026-03-25: post-commit hook infinite loop
**Mistake:** Used a `post-commit` hook that ran `git commit --amend --no-verify`, which re-triggered the hook, looping hundreds of times and bloating the CHANGELOG.
**Root cause:** `--no-verify` skips hooks on the amend, but `post-commit` still fires after any commit including amends in some git versions.
**Rule:** Never use `post-commit` hooks that themselves run git commits or amends. Use explicit scripts (like `save.sh`) instead of hooks for changelog automation.

---

## L002 — 2026-03-25: wget only grabbed homepage, not full site
**Mistake:** First wget run used `charleswclark.com` (no www), which got a 301 redirect and only saved the redirected index.html — no assets, no subpages.
**Root cause:** `--no-parent` + redirect meant wget followed to `www.charleswclark.com` but filed it under the wrong domain folder and stopped.
**Rule:** Always start wget scrapes from the canonical `www.` URL. Use `--domains` to explicitly allow both root and www plus any CDN domains needed.

---

## L003 — 2026-03-25: GitHub push failed due to file >100MB
**Mistake:** Committed `Video-Trailer.mp4` (146MB) directly to git history before setting up LFS.
**Root cause:** Didn't audit file sizes before the initial commit.
**Rule:** Before any initial commit on a media-heavy site, run `find . -size +90M` and set up Git LFS for video/audio types first.

---

## L004 — 2026-03-25: Static scrape produced broken relative paths
**Mistake:** wget's `--convert-links` rewrote CDN URLs (i0.wp.com, c0.wp.com) to relative `../i0.wp.com/...` paths that broke when the site was served from the repo root.
**Root cause:** wget assumes the scraped files will be served from the same relative directory structure. Moving files to a different root breaks those paths.
**Rule:** After any wget scrape + move, audit all `src=` and `href=` attributes for `../external-domain/` patterns and rewrite them back to absolute `https://` URLs.

---

_Add new lessons below as they occur._
