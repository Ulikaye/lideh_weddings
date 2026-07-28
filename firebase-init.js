/* ============================================================
   FIREBASE INIT
   ------------------------------------------------------------
   Wires up Firebase Authentication + Firestore and exposes a
   small `fb` API that app.js calls into. You should not need to
   edit this file — edit firebase-config.js instead.
   ============================================================ */

import { initializeApp } from "https://www.gstatic.com/firebasejs/12.16.0/firebase-app.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/12.16.0/firebase-auth.js";
import {
  getFirestore,
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  onSnapshot,
  query,
  orderBy,
  runTransaction
} from "https://www.gstatic.com/firebasejs/12.16.0/firebase-firestore.js";

import { firebaseConfig } from './firebase-config.js';

const isConfigured = !!(firebaseConfig && firebaseConfig.apiKey && !firebaseConfig.apiKey.startsWith('YOUR_'));

let app = null, auth = null, db = null;
if(isConfigured){
  app = initializeApp(firebaseConfig);
  auth = getAuth(app);
  db = getFirestore(app);
}

/* ---------------- friendly error messages ---------------- */
const AUTH_ERROR_MESSAGES = {
  'auth/invalid-email': 'That email address looks invalid.',
  'auth/user-not-found': 'No account found with that email.',
  'auth/wrong-password': 'Incorrect email or password.',
  'auth/invalid-credential': 'Incorrect email or password.',
  'auth/email-already-in-use': 'An account with that email already exists — try signing in instead.',
  'auth/weak-password': 'Password should be at least 6 characters.',
  'auth/too-many-requests': 'Too many attempts. Please wait a moment and try again.',
  'auth/network-request-failed': 'Network error — check your internet connection.'
};
function friendlyError(err){
  return AUTH_ERROR_MESSAGES[err && err.code] || (err && err.message) || 'Something went wrong.';
}

/* ---------------- authentication ---------------- */
async function login(email, password){
  try{
    await signInWithEmailAndPassword(auth, email, password);
    return { ok: true };
  } catch(err){
    return { ok: false, error: friendlyError(err) };
  }
}
async function logout(){
  await signOut(auth);
}
function onAuthChange(callback){
  onAuthStateChanged(auth, user => callback(user));
}

/* ---------------- Firestore refs ---------------- */
const eventDocRef = () => doc(db, 'event', 'main');
const counterDocRef = () => doc(db, 'meta', 'counter');
const contributorsColRef = () => collection(db, 'contributors');

/* ---------------- event settings (shared across all admins) ---------------- */
function subscribeEvent(callback){
  return onSnapshot(eventDocRef(), snap=>{
    callback(snap.exists() ? snap.data() : null);
  });
}
async function saveEvent(data){
  await setDoc(eventDocRef(), data, { merge: true });
}

/* ---------------- contributors (shared across all admins) ---------------- */
function subscribeContributors(callback){
  const q = query(contributorsColRef(), orderBy('id'));
  return onSnapshot(q, snap=>{
    const list = [];
    snap.forEach(d => list.push(d.data()));
    callback(list);
  });
}

/* Sequential WC-0001 style IDs, made collision-safe across devices
   with a Firestore transaction on a shared counter document. */
async function nextContributorId(){
  return runTransaction(db, async (tx)=>{
    const ref = counterDocRef();
    const snap = await tx.get(ref);
    const current = snap.exists() ? (snap.data().value || 0) : 0;
    const next = current + 1;
    tx.set(ref, { value: next });
    return 'WC-' + String(next).padStart(4, '0');
  });
}

async function addContributor(data){
  const id = await nextContributorId();
  const record = { ...data, id, checkedIn: false, checkedInTime: null };
  await setDoc(doc(contributorsColRef(), id), record);
  return record;
}
async function updateContributor(id, data){
  await updateDoc(doc(contributorsColRef(), id), data);
}
async function deleteContributor(id){
  await deleteDoc(doc(contributorsColRef(), id));
}

export const fb = {
  isConfigured,
  login, logout, onAuthChange,
  subscribeEvent, saveEvent,
  subscribeContributors, addContributor, updateContributor, deleteContributor
};
