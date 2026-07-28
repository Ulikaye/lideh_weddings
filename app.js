/* ============================================================
   Harusi Cards — Wedding Invitation & Contribution Ledger
   Data now lives in Firebase (Auth + Firestore) so every admin
   device sees the same live ledger. See firebase-config.js to
   connect your own Firebase project.
   ============================================================ */

import { fb } from './firebase-init.js';

let html5QrCode = null;
let activeRecordForCard = null;
let confetti = null;

let currentEvent = defaultEventData();
let contributors = [];
let unsubEvent = null;
let unsubContrib = null;
let autoShowDone = false;

function defaultEventData(){
  return {
    brideName:'', groomName:'', weddingDate:'', venue:'',
    singleAmount:50000, doubleAmount:100000,
    brideImage:null, groomImage:null
  };
}

function formatMoney(n){
  return 'TZS ' + Number(n || 0).toLocaleString('en-US');
}
function formatDate(d){
  if(!d) return '—';
  const dt = new Date(d + 'T00:00:00');
  if(isNaN(dt)) return d;
  return dt.toLocaleDateString('en-GB', {day:'numeric', month:'long', year:'numeric'});
}
function todayISO(){
  return new Date().toISOString().slice(0,10);
}
function escapeHtml(str){
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

/* ============================================================
   CONFETTI (login screen ambiance + celebration burst)
   ============================================================ */
function setupConfetti(){
  const canvas = document.getElementById('confettiCanvas');
  const ctx = canvas.getContext('2d');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const colors = ['#D4AF37', '#146356', '#FBF3E4', '#E8B4B8'];
  let particles = [];
  let rafId = null;

  function resize(){
    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
  }
  window.addEventListener('resize', resize);

  function spawn(count){
    for(let i = 0; i < count; i++){
      particles.push({
        x: Math.random() * canvas.width,
        y: -20 - Math.random() * canvas.height * 0.6,
        size: 4 + Math.random() * 5,
        color: colors[Math.floor(Math.random() * colors.length)],
        vy: 1 + Math.random() * 2.4,
        vx: (Math.random() - 0.5) * 1.4,
        rot: Math.random() * 360,
        vr: (Math.random() - 0.5) * 6,
        shape: Math.random() > 0.5 ? 'rect' : 'circle'
      });
    }
    if(particles.length > 400) particles = particles.slice(-400);
  }

  function tick(){
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    particles.forEach(p=>{
      p.y += p.vy; p.x += p.vx; p.rot += p.vr;
      if(p.y > canvas.height + 20){ p.y = -20; p.x = Math.random() * canvas.width; }
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot * Math.PI / 180);
      ctx.fillStyle = p.color;
      if(p.shape === 'rect') ctx.fillRect(-p.size / 2, -p.size * 0.2, p.size, p.size * 0.4);
      else { ctx.beginPath(); ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2); ctx.fill(); }
      ctx.restore();
    });
    rafId = requestAnimationFrame(tick);
  }

  return {
    start(){
      if(reduceMotion || rafId) return;
      resize();
      if(particles.length === 0) spawn(50);
      tick();
    },
    stop(){
      if(rafId){ cancelAnimationFrame(rafId); rafId = null; }
    },
    burst(n){
      if(reduceMotion) return;
      spawn(n);
    }
  };
}

/* ============================================================
   AUTHENTICATION (Firebase Auth)
   ============================================================ */
function showApp(){
  document.getElementById('loginScreen').classList.add('is-hidden');
  document.getElementById('appRoot').style.display = '';
  if(confetti) confetti.stop();
}
function showLogin(){
  document.getElementById('loginScreen').classList.remove('is-hidden');
  document.getElementById('appRoot').style.display = 'none';
  if(confetti) confetti.start();
}
function logout(){
  fb.logout();
}

function startDataSubscriptions(){
  if(unsubEvent || unsubContrib) return;
  unsubEvent = fb.subscribeEvent(data=>{
    currentEvent = Object.assign(defaultEventData(), data || {});
    populateEventForm();
    syncAmountForSelectedType();
  });
  unsubContrib = fb.subscribeContributors(list=>{
    contributors = list;
    renderRecords();
  });
}
function stopDataSubscriptions(){
  if(unsubEvent){ unsubEvent(); unsubEvent = null; }
  if(unsubContrib){ unsubContrib(); unsubContrib = null; }
  contributors = [];
  currentEvent = defaultEventData();
}

function initAuth(){
  if(!fb.isConfigured){
    document.getElementById('loginPanel').classList.add('is-hidden');
    document.getElementById('firebaseSetupNotice').classList.remove('is-hidden');
    if(confetti) confetti.start();
    return;
  }

  fb.onAuthChange(user=>{
    if(user){
      startDataSubscriptions();
      if(!autoShowDone){ autoShowDone = true; showApp(); }
    } else {
      autoShowDone = false;
      stopDataSubscriptions();
      showLogin();
    }
  });

  document.getElementById('loginForm').addEventListener('submit', async e=>{
    e.preventDefault();
    const email = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value;
    const errorEl = document.getElementById('loginError');
    errorEl.textContent = '';
    const btn = e.target.querySelector('button[type="submit"]');
    btn.disabled = true;
    const res = await fb.login(email, password);
    btn.disabled = false;
    if(res.ok){
      autoShowDone = true;
      if(confetti) confetti.burst(150);
      setTimeout(showApp, 650);
    } else {
      errorEl.textContent = res.error;
    }
  });

  document.getElementById('sidebarLogoutBtn').addEventListener('click', logout);
  document.getElementById('topbarLogoutBtn').addEventListener('click', logout);
}

/* ============================================================
   NAVIGATION
   ============================================================ */
function setupNav(){
  document.querySelectorAll('.nav-item').forEach(btn=>{
    btn.addEventListener('click', ()=>{
      document.querySelectorAll('.nav-item').forEach(b=>b.classList.remove('is-active'));
      document.querySelectorAll('.view').forEach(v=>v.classList.remove('is-active'));
      btn.classList.add('is-active');
      document.getElementById('view-' + btn.dataset.view).classList.add('is-active');
      if(btn.dataset.view === 'records') renderRecords();
      if(btn.dataset.view !== 'scan') stopScanner();
    });
  });
}

/* ============================================================
   EVENT SETUP
   ============================================================ */
function resizeImageFile(file, maxDim = 500, quality = 0.85){
  return new Promise((resolve, reject)=>{
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('Could not read file'));
    reader.onload = () => {
      const img = new Image();
      img.onerror = () => reject(new Error('Could not load image'));
      img.onload = () => {
        const side = Math.min(img.width, img.height);
        const sx = (img.width - side) / 2;
        const sy = (img.height - side) / 2;
        const size = Math.min(maxDim, side);
        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, sx, sy, side, side, 0, 0, size, size);
        resolve(canvas.toDataURL('image/jpeg', quality));
      };
      img.src = reader.result;
    };
    reader.readAsDataURL(file);
  });
}

function setPhotoPreview(previewId, dataUrl){
  const el = document.getElementById(previewId);
  el.innerHTML = dataUrl
    ? `<img src="${dataUrl}" alt="">`
    : `<svg><use href="#icon-image"/></svg>`;
}

function populateEventForm(){
  document.getElementById('brideName').value = currentEvent.brideName || '';
  document.getElementById('groomName').value = currentEvent.groomName || '';
  document.getElementById('weddingDate').value = currentEvent.weddingDate || '';
  document.getElementById('venue').value = currentEvent.venue || '';
  document.getElementById('singleAmount').value = currentEvent.singleAmount || 50000;
  document.getElementById('doubleAmount').value = currentEvent.doubleAmount || 100000;
  setPhotoPreview('bridePreview', currentEvent.brideImage);
  setPhotoPreview('groomPreview', currentEvent.groomImage);
}

function initEventForm(){
  populateEventForm();

  document.getElementById('brideImage').addEventListener('change', async e=>{
    const file = e.target.files[0];
    if(!file) return;
    const dataUrl = await resizeImageFile(file);
    setPhotoPreview('bridePreview', dataUrl);
    await fb.saveEvent({ brideImage: dataUrl });
  });
  document.getElementById('groomImage').addEventListener('change', async e=>{
    const file = e.target.files[0];
    if(!file) return;
    const dataUrl = await resizeImageFile(file);
    setPhotoPreview('groomPreview', dataUrl);
    await fb.saveEvent({ groomImage: dataUrl });
  });

  document.getElementById('eventForm').addEventListener('submit', async e=>{
    e.preventDefault();
    const data = {
      brideName: document.getElementById('brideName').value.trim(),
      groomName: document.getElementById('groomName').value.trim(),
      weddingDate: document.getElementById('weddingDate').value,
      venue: document.getElementById('venue').value.trim(),
      singleAmount: Number(document.getElementById('singleAmount').value) || 0,
      doubleAmount: Number(document.getElementById('doubleAmount').value) || 0
    };
    const note = document.getElementById('eventSaveNote');
    try{
      await fb.saveEvent(data);
      syncAmountForSelectedType();
      note.textContent = 'Saved — visible to every admin instantly.';
    } catch(err){
      note.textContent = 'Could not save. Check your connection.';
    }
    note.classList.add('is-visible');
    setTimeout(()=>note.classList.remove('is-visible'), 2500);
  });
}

/* ============================================================
   ADD CONTRIBUTOR
   ============================================================ */
function syncAmountForSelectedType(){
  const type = document.getElementById('cardType').value;
  document.getElementById('amount').value = type === 'Single'
    ? (currentEvent.singleAmount || 50000)
    : (currentEvent.doubleAmount || 100000);
}

function initAddForm(){
  document.getElementById('dateAdded').value = todayISO();
  syncAmountForSelectedType();

  document.getElementById('cardType').addEventListener('change', syncAmountForSelectedType);

  document.getElementById('addForm').addEventListener('submit', async e=>{
    e.preventDefault();
    const fullName = document.getElementById('fullName').value.trim();
    if(!fullName) return;

    const btn = e.target.querySelector('button[type="submit"]');
    btn.disabled = true;
    try{
      const record = await fb.addContributor({
        fullName,
        cardType: document.getElementById('cardType').value,
        amount: Number(document.getElementById('amount').value) || 0,
        date: document.getElementById('dateAdded').value || todayISO(),
        phone: document.getElementById('phone').value.trim()
      });
      document.getElementById('addForm').reset();
      document.getElementById('dateAdded').value = todayISO();
      syncAmountForSelectedType();
      openCardModal(record);
    } catch(err){
      alert('Could not save this contributor. Check your connection and try again.');
    }
    btn.disabled = false;
  });
}

/* ============================================================
   INVITATION CARD + QR
   ============================================================ */
function qrPayload(record){
  return [record.id, record.fullName, record.cardType, record.amount, record.date].join('|');
}

function renderCard(record){
  const ev = currentEvent;
  const coupleNames = (ev.groomName || 'Groom') + ' & ' + (ev.brideName || 'Bride');
  const metaParts = [];
  if(ev.weddingDate) metaParts.push(formatDate(ev.weddingDate));
  if(ev.venue) metaParts.push(ev.venue);

  document.getElementById('cardCouple').textContent = coupleNames;
  document.getElementById('cardMeta').textContent = metaParts.join(' · ') || 'Date · Venue to be confirmed';

  const bridePhotoEl = document.getElementById('cardBridePhoto');
  const groomPhotoEl = document.getElementById('cardGroomPhoto');
  const photosWrap = document.querySelector('.card-photos');
  bridePhotoEl.src = ev.brideImage || '';
  groomPhotoEl.src = ev.groomImage || '';
  photosWrap.classList.toggle('is-empty', !ev.brideImage && !ev.groomImage);

  document.getElementById('cardName').textContent = record.fullName;
  document.getElementById('cardType').textContent = record.cardType + ' card';
  document.getElementById('cardAmount').textContent = formatMoney(record.amount);
  document.getElementById('cardDate').textContent = 'Contributed on ' + formatDate(record.date);
  document.getElementById('cardIdLabel').textContent = record.id;

  const qrEl = document.getElementById('qrcodeContainer');
  qrEl.innerHTML = '';
  new QRCode(qrEl, {
    text: qrPayload(record),
    width: 128,
    height: 128,
    colorDark: '#2A1220',
    colorLight: '#FBF3E4',
    correctLevel: QRCode.CorrectLevel.M
  });
}

function openCardModal(record){
  activeRecordForCard = record;
  renderCard(record);
  document.getElementById('cardModal').classList.add('is-active');
}
function closeCardModal(){
  document.getElementById('cardModal').classList.remove('is-active');
  activeRecordForCard = null;
}

function downloadCard(){
  if(!activeRecordForCard) return;
  const cardEl = document.getElementById('cardTemplate');
  html2canvas(cardEl, {backgroundColor:null, scale:2}).then(canvas=>{
    const link = document.createElement('a');
    const safeName = activeRecordForCard.fullName.replace(/[^a-z0-9]+/gi, '_');
    link.download = `${activeRecordForCard.id}_${safeName}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
  });
}

/* ============================================================
   RECORDS TABLE
   ============================================================ */
function renderRecords(){
  const list = contributors;
  const query = (document.getElementById('searchInput').value || '').toLowerCase();
  const filtered = list.filter(r =>
    r.fullName.toLowerCase().includes(query) || r.id.toLowerCase().includes(query)
  );

  document.getElementById('statCount').textContent = list.length;
  document.getElementById('statTotal').textContent = formatMoney(list.reduce((s,r)=>s + Number(r.amount||0), 0));
  document.getElementById('statChecked').textContent = list.filter(r=>r.checkedIn).length;

  const body = document.getElementById('recordsBody');
  body.innerHTML = '';
  document.getElementById('recordsEmpty').classList.toggle('is-visible', list.length === 0);

  filtered.forEach(r=>{
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="mono">${r.id}</td>
      <td>${escapeHtml(r.fullName)}</td>
      <td>${r.cardType}</td>
      <td class="mono">${formatMoney(r.amount)}</td>
      <td>${formatDate(r.date)}</td>
      <td>${r.checkedIn
          ? `<span class="badge badge-in"><svg><use href="#icon-check"/></svg>Checked in</span>`
          : `<span class="badge badge-out"><svg><use href="#icon-x"/></svg>Not yet</span>`}</td>
      <td class="col-actions">
        <div class="row-actions">
          <button class="icon-btn" data-action="view" data-id="${r.id}" title="View / download card"><svg><use href="#icon-eye"/></svg></button>
          <button class="icon-btn danger" data-action="delete" data-id="${r.id}" title="Delete"><svg><use href="#icon-trash"/></svg></button>
        </div>
      </td>
    `;
    body.appendChild(tr);
  });

  body.querySelectorAll('[data-action="view"]').forEach(btn=>{
    btn.addEventListener('click', ()=>{
      const rec = contributors.find(r=>r.id === btn.dataset.id);
      if(rec) openCardModal(rec);
    });
  });
  body.querySelectorAll('[data-action="delete"]').forEach(btn=>{
    btn.addEventListener('click', async ()=>{
      if(!confirm('Remove this contributor from the ledger? This cannot be undone.')) return;
      try{
        await fb.deleteContributor(btn.dataset.id);
      } catch(err){
        alert('Could not delete this contributor. Check your connection and try again.');
      }
    });
  });
}

/* ============================================================
   EXPORT (CSV / XLSX)
   ============================================================ */
function exportCSV(){
  const list = contributors;
  const headers = ['ID','Full Name','Card Type','Amount (TZS)','Date','Phone','Checked In','Checked In Time'];
  const rows = list.map(r => [r.id, r.fullName, r.cardType, r.amount, r.date, r.phone||'', r.checkedIn?'Yes':'No', r.checkedInTime||'']);
  const csv = [headers, ...rows].map(row =>
    row.map(cell => `"${String(cell).replace(/"/g,'""')}"`).join(',')
  ).join('\n');

  const blob = new Blob([csv], {type:'text/csv;charset=utf-8;'});
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = 'wedding_contributors.csv';
  link.click();
}

function exportXLSX(){
  const list = contributors;
  const rows = list.map(r => ({
    ID:r.id, 'Full Name':r.fullName, 'Card Type':r.cardType, 'Amount (TZS)':r.amount,
    Date:r.date, Phone:r.phone||'', 'Checked In':r.checkedIn?'Yes':'No', 'Checked In Time':r.checkedInTime||''
  }));
  const sheet = XLSX.utils.json_to_sheet(rows);
  const book = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(book, sheet, 'Contributors');
  XLSX.writeFile(book, 'wedding_contributors.xlsx');
}

/* ============================================================
   GATE SCANNER
   ============================================================ */
function startScanner(){
  html5QrCode = new Html5Qrcode('qrReader');
  Html5Qrcode.getCameras().then(()=>{
    html5QrCode.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: 240 },
      decodedText => handleScanResult(decodedText),
      ()=>{ /* ignore per-frame scan errors */ }
    ).then(()=>{
      document.getElementById('startScanBtn').classList.add('is-hidden');
      document.getElementById('stopScanBtn').classList.remove('is-hidden');
    }).catch(()=>{
      showScanMessage('bad', 'Camera unavailable', 'Grant camera access in your browser settings and try again.');
    });
  }).catch(()=>{
    showScanMessage('bad', 'No camera found', 'This device has no accessible camera.');
  });
}

function stopScanner(){
  if(html5QrCode){
    html5QrCode.stop().then(()=>html5QrCode.clear()).catch(()=>{});
  }
  document.getElementById('startScanBtn').classList.remove('is-hidden');
  document.getElementById('stopScanBtn').classList.add('is-hidden');
}

async function handleScanResult(decodedText){
  if(html5QrCode) html5QrCode.pause(true);

  const id = (decodedText.split('|')[0] || '').trim();
  const record = contributors.find(r => r.id === id);

  if(!record){
    showScanMessage('bad', 'Not recognised', 'This QR code does not match any contributor in the ledger.');
    return;
  }

  if(record.checkedIn){
    showScanMessage('warn', 'Already checked in', `Checked in at ${record.checkedInTime || 'an earlier time'}.`, record);
    return;
  }

  const checkedInTime = new Date().toLocaleString('en-GB');
  try{
    await fb.updateContributor(id, { checkedIn: true, checkedInTime });
    showScanMessage('ok', 'Checked in', 'Contribution verified. Welcome them in.', { ...record, checkedIn:true, checkedInTime });
  } catch(err){
    showScanMessage('bad', 'Could not update', 'Check your connection and try again.');
  }
}

function showScanMessage(kind, title, sub, record){
  const iconMap = { ok:'icon-check', warn:'icon-alert', bad:'icon-x' };
  const resultEl = document.getElementById('scanResult');
  resultEl.innerHTML = `
    <div class="result-panel">
      <svg class="result-icon ${kind}"><use href="#${iconMap[kind]}"/></svg>
      <div class="result-title">${title}</div>
      <div class="result-sub">${sub}</div>
      ${record ? `
        <div class="result-name">${escapeHtml(record.fullName)}</div>
        <div class="result-detail">
          <span>${record.cardType} card</span>
          <span>${formatMoney(record.amount)}</span>
          <span>${formatDate(record.date)}</span>
        </div>
      ` : ''}
      <button class="btn btn-primary scan-again" id="scanAgainBtn"><svg><use href="#icon-camera"/></svg> Scan next guest</button>
    </div>
  `;
  document.getElementById('scanAgainBtn').addEventListener('click', ()=>{
    resultEl.innerHTML = `<div class="scan-placeholder"><svg><use href="#icon-qr"/></svg><p>Scan results will appear here</p></div>`;
    if(html5QrCode) html5QrCode.resume();
  });
}

/* ============================================================
   INIT
   ============================================================ */
document.addEventListener('DOMContentLoaded', ()=>{
  confetti = setupConfetti();
  initAuth();
  setupNav();
  initEventForm();
  initAddForm();

  document.getElementById('modalCloseBtn').addEventListener('click', closeCardModal);
  document.getElementById('cardModal').addEventListener('click', e=>{
    if(e.target.id === 'cardModal') closeCardModal();
  });
  document.getElementById('downloadCardBtn').addEventListener('click', downloadCard);

  document.getElementById('searchInput').addEventListener('input', renderRecords);
  document.getElementById('exportCsvBtn').addEventListener('click', exportCSV);
  document.getElementById('exportXlsxBtn').addEventListener('click', exportXLSX);

  document.getElementById('startScanBtn').addEventListener('click', startScanner);
  document.getElementById('stopScanBtn').addEventListener('click', stopScanner);
});
