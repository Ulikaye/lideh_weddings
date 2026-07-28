/* ============================================================
   FIREBASE CONFIGURATION
   ------------------------------------------------------------
   This is the ONLY file you need to edit to connect this app to
   your own Firebase project. Everything else (auth, database
   reads/writes, real-time sync across devices) is already wired
   up in firebase-init.js and app.js.

   HOW TO GET THESE VALUES:
   1. Go to https://console.firebase.google.com and create a project
      (or open an existing one).
   2. Click the gear icon → "Project settings".
   3. Under "Your apps", click the "</>" (Web) icon to register a
      web app (you don't need Hosting — just the app registration).
   4. Firebase will show you a config object exactly like the one
      below. Copy your real values in here, replacing the
      placeholders.
   5. In the left sidebar, open "Build → Authentication → Sign-in
      method" and enable "Email/Password".
   6. In the left sidebar, open "Build → Firestore Database" and
      click "Create database" (start in production mode is fine —
      see the security rules note in README.md).
   ============================================================ */


export const firebaseConfig = {
    apiKey: "AIzaSyA-78mKgBxf3x4lKoQKVT_Nliqb3FuOatA",
    authDomain: "lideh-wedding.firebaseapp.com",
    projectId: "lideh-wedding",
    storageBucket: "lideh-wedding.firebasestorage.app",
    messagingSenderId: "340746957889",
    appId: "1:340746957889:web:0f0fff0bb60a32111282c0",
    measurementId: "G-3DEFQWYSY8"
  };

