# Harusi Cards — Wedding Invitation & Contribution Ledger

A wedding invitation + QR contribution ledger. Now backed by **Firebase**
(Authentication + Firestore), so multiple admins on different browsers or
devices all see and edit the same live ledger — no more single-device
limitation.

## Files
- `index.html` — app structure (login/register screens, dashboard, scanner)
- `style.css` — design system
- `app.js` — all UI logic (module — imports firebase-init.js)
- `firebase-init.js` — Firebase wiring (auth + Firestore helpers) — you
  shouldn't need to edit this
- `firebase-config.js` — **the only file you need to edit** to connect
  your own Firebase project
- `logo.png` — your platform logo

## 1. Create a Firebase project
1. Go to https://console.firebase.google.com and click **Add project**
   (it's free — the "Spark" plan covers this app's scale comfortably).
2. Once created, click the gear icon → **Project settings**.
3. Under "Your apps", click the **`</>`** (Web) icon to register a web app.
   You don't need Firebase Hosting — just the app registration.
4. Firebase shows you a `firebaseConfig` object. Copy those real values
   into `firebase-config.js`, replacing the placeholders.

## 2. Turn on Email/Password sign-in, and create your admin accounts
1. In the Firebase console sidebar: **Build → Authentication → Sign-in
   method** → enable **Email/Password**.
2. There is deliberately **no self-registration page** in the app — if
   there were, anyone who found your GitHub Pages link could create their
   own admin account. Instead, create accounts yourself: **Build →
   Authentication → Users → Add user**, and add one entry per admin
   (e.g. you and your friend), each with an email + password of your
   choosing. Share those credentials with them directly.

## 3. Create the Firestore database
In the sidebar: **Build → Firestore Database → Create database**. Choose
any nearby region and start in **production mode**.

Then go to the **Rules** tab and paste this in (any signed-in admin can
read/write, no one else can):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Click **Publish**.

## 4. Running locally
Because `app.js` uses ES module imports, opening `index.html` directly
with `file://` won't work (browsers block module imports over `file://`).
Run a quick local server instead, from this folder:

```
python3 -m http.server 8000
```

Then open `http://localhost:8000` in your browser.

## 5. Hosting on GitHub Pages
1. Create a GitHub repository and add all the files in this folder to
   the root (including `logo.png`, `firebase-config.js`, `firebase-init.js`).
2. **Settings → Pages** → set source to your `main` branch, folder `/root`.
3. Your app will be live at `https://<your-username>.github.io/<repo>/`.
4. In the Firebase console, go to **Authentication → Settings →
   Authorized domains** and add your GitHub Pages domain (e.g.
   `<your-username>.github.io`) so sign-in works there.

## How to use it
1. **Sign in** with an account created in the Firebase Console (see step 2
   above). There's no in-app registration, by design — only accounts you
   create yourself can access the ledger.
2. **Event Setup** — bride/groom names, date, venue, card prices, and
   photos. Saved once, shared instantly with every admin.
3. **Add Contributor** — after receiving payment, add the contributor.
   A card + QR code generate instantly and sync to Firestore right away.
4. **Records** — live ledger, searchable, exportable as CSV/Excel, with
   running totals.
5. **Scan Gate** — scan a guest's QR code on the wedding day; it looks
   the contributor up in the shared ledger and marks them checked in
   everywhere at once, flagging repeat scans.

## Notes
- Contributor photos are compressed to ~500×500 JPEGs before upload, so
  they stay small and fast to sync.
- This is a basic single-role system: any registered admin can do
  everything (add, edit, delete, scan). There's no separate "gate-only"
  role — keep registration limited to people you trust.
- No payment gateway, email, or SMS integration is included —
  contributions are still recorded manually after being received offline.
