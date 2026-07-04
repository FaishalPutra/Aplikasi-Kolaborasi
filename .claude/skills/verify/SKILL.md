---
name: verify
description: How to build/launch/drive this repo (Express+Prisma backend, Flutter mobile) for runtime verification.
---

# Verifying changes in collab-platform

Monorepo: `backend/` (Express + Prisma + PostgreSQL) and `mobile/` (Flutter, Android emulator + web).

## Backend surface (server/API)

```bash
cd backend
npm run dev > /d/tmp_backend.log 2>&1 &   # ts-node-dev, auto-reload on save
curl -sS http://localhost:3000/health     # {"ok":true} when ready
```

- Auth: `POST /api/auth/register` returns **no token** — must `POST /api/auth/login` separately to get one.
- Drive real flows with curl + a bash script (register → login → PUT /auth/akun → PUT /auth/profil → create project → register → accept …). See git history of this file's directory for a full example script if needed.
- Extracting JSON fields with `sed` greedy regex breaks when the same key name appears nested (e.g. top-level project `"id"` vs nested `roles[].id`) — greedy `.*` matches the *last* occurrence. Anchor with `^{"id":"..."` or match a unique neighboring field instead.
- After `git pull` brings in a `schema.prisma` change: `npx prisma migrate deploy && npx prisma generate`. The `generate` step fails with `EPERM ... query_engine-windows.dll.node` if the dev server is still running (holds the file open) — stop it first (`taskkill //F //PID <pid> //T`, find via `Get-CimInstance Win32_Process -Filter "Name='node.exe'"` in PowerShell), regenerate, then restart.
- No seeded demo accounts exist in a fresh DB — register your own via the API for testing, then delete via a one-off `backend/src/scripts_*.ts` using `prisma` client (no self-service account-delete endpoint exists). Always delete the throwaway script file afterward.

## Mobile surface (GUI — Android emulator)

Cold-start sequence (needed almost every session since the emulator process doesn't survive across sessions):

```bash
ANDROID_HOME="${ANDROID_HOME:-$LOCALAPPDATA/Android/Sdk}"
"$ANDROID_HOME/emulator/emulator.exe" -avd emulator_android &   # launches as its own floating window
"$ANDROID_HOME/platform-tools/adb.exe" devices                  # poll until state is "device" (not "unauthorized"/"offline")
cd mobile && flutter run -d emulator-5554 --debug > /d/tmp_flutter.log 2>&1 &
```

Watch the log with Monitor for `Built build|FAILURE|Lost connection|A Dart VM` rather than polling.

**Driving the UI (no proper automation tool available — raw adb):**
- Screenshot: `adb exec-out screencap -p > file.png` (NOT `adb shell screencap -p /sdcard/x.png` — the combined `-p` + path form errors out on this setup; exec-out avoids the extra pull step too).
- Tap coordinates: `adb shell wm size` confirms physical resolution (1080x2280 here) matches screencap pixel dimensions — but the image returned to Read is *displayed* at a smaller size with a stated scale factor (e.g. "displayed at 947x2000, multiply by 1.14"). **Always multiply the coordinates you read off the image by that factor before calling `adb shell input tap`** — passing displayed-image coordinates directly taps the wrong element (this bit us: it selected the wrong tab).
- Text input: `adb shell input text "foo@bar.com"` — works fine with `@`/`.` unescaped when passed as one quoted arg from bash.
- Dismissing the keyboard: `input keyevent 111` (ESC) does *not* reliably dismiss the Flutter text-field keyboard on this AVD — tapping a visible sliver of the underlying button works better than fighting the keyboard.
- After tapping, `sleep 1-2` before screenshotting — Flutter route transitions and API round-trips aren't instant; a screenshot taken too early silently shows the stale frame (looks like "tap did nothing").
- Login/logout round-trip for switching test accounts: Welcome → "Masuk" → fill email/password → submit → bottom-nav "Profil" → scroll down → "Keluar" → confirm dialog.
- Bottom nav order: Orang (People-to-People) / Proyek (People-to-Project) / Tim (Team Formation placeholder) / Profil.

## Known runtime gotcha found via this process

`mobile/lib/modules/people_to_project.dart` Detail Proyek's "Diajukan oleh X" line: the inner `Row(children:[icon, text])` is not wrapped in `Expanded`/`Flexible`, so any long creator name + jurusan + angkatan string overflows (visible as Flutter's yellow/black "RIGHT OVERFLOWED" banner) — this is real screen-rendering behavior `flutter analyze` cannot catch. When adding text to a `Row` that lives inside an already-`Expanded` column, wrap the `Text` itself in `Expanded` + `overflow: TextOverflow.ellipsis`.
