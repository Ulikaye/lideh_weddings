# Harusi Cards — Flutter rebuild

Rebuild of your `Lewis3` web app (plain HTML/JS/localStorage) as one Flutter
codebase for **Web + Android + iOS**, backed by Firebase (Firestore +
Storage) instead of `localStorage`, so records sync live across every device.

## What changed vs. the original

- **Card → QR only.** After you save a contributor, the app no longer draws
  a designed invitation card. It shows and lets you download just the QR
  code (PNG). Your card designer embeds that QR into the printed card.
- **Firebase instead of localStorage.** The original stored everything in
  the browser only (one device, no sync). This version writes to
  Firestore (`event`, `contributors`, `meta/counter` collections) and
  Storage (bride/groom photos), so the web app, the Android app and the
  iOS app all see the same live data.
- Everything else is kept: event setup with bride/groom photos, add
  contributor form (auto-filling amount from card type), records list with
  search + totals + checked-in count, camera QR scan for gate check-in,
  and CSV/Excel export.
- Login is still a simple in-app username/password gate (see
  `lib/services/auth_service.dart`) — same approach as before, not real
  per-user accounts. See the security note below.

## 1. Firebase project

Your web config (`lideh-wedding` project) is already wired into
`lib/firebase_options.dart`. Nothing to do there for the **web** build.

For **Android** and **iOS** you need to register those two apps in the same
Firebase project (you haven't yet — the web config alone doesn't cover
native apps). Easiest way, from this project's root folder once step 2 is
done:

```
dart pub global activate flutterfire_cli
flutterfire configure --project=lideh-wedding
```

This talks to your existing project, adds the Android/iOS apps, downloads
`google-services.json` / `GoogleService-Info.plist` into the right folders,
and **rewrites `lib/firebase_options.dart` for you** (safe to overwrite —
it'll keep your real web values and fill in the real Android/iOS ones).

Also turn on **Cloud Firestore** and **Storage** in the Firebase console if
you haven't (Build → Firestore Database → Create database; Build → Storage
→ Get started). Then deploy the two rule files in this folder:

```
firebase deploy --only firestore:rules,storage:rules
```

(`firestore.rules` / `storage.rules` are wide open by default so the app
works immediately — read the comment at the top of each file before you
go live with real money involved.)

## 2. Get the native platform folders

This zip has `lib/`, `pubspec.yaml`, `web/`, and the two rules files —
the actual app. It deliberately does **not** include the generated
`android/`, `ios/`, `macos/`, `windows/`, `linux/` folders, because those
are large, mostly-boilerplate, and version-sensitive (best generated fresh
by your own Flutter SDK rather than hand-typed here, or they can end up
mismatched and fail to build).

1. Somewhere else on your machine, create a throwaway scaffold:
   ```
   flutter create scaffold_tmp
   ```
2. Copy `android/`, `ios/` (and `macos/`, `windows/`, `linux/` if you want
   those too) from `scaffold_tmp` into this project folder, next to `lib/`.
3. Delete `scaffold_tmp`.
4. Open `android/app/build.gradle` and `ios/Runner.xcodeproj` and set the
   package name / bundle id you want (needed before `flutterfire configure`
   in step 1, since it registers apps under that id).

## 3. Install & run

```
flutter pub get
flutter run              # pick a device: web/Android/iOS
```

Sign in with one of the accounts in `lib/services/auth_service.dart`
(`admin` / `harusi2026` or `gate` / `gate2026` by default — change these).

## Data model (Firestore)

- `event/config` — one document: bride/groom names, date, venue, card
  amounts, photo URLs.
- `contributors/{id}` — one document per guest, id like `WC-0001`
  (assigned atomically via a counter so two devices adding a guest at the
  same instant never collide).
- `meta/counter` — internal, just the running count used to generate ids.

## Security note

The login screen is a convenience gate, not real authentication — the
credentials live in the compiled app, and (until you lock down the rules
above) anyone with your Firebase config could read/write the data directly.
For a production rollout with real contribution money, swap
`auth_service.dart` for Firebase Authentication and restrict
`firestore.rules` / `storage.rules` to `request.auth != null`.
