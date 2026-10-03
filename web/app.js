const $ = (id) => document.getElementById(id);
const fmt = (n) => '$' + Math.round(n || 0).toLocaleString('en-US');
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'arca_hud';
const post = (name, data = {}) => fetch(`https://${resource}/${name}`, { method: 'POST', body: JSON.stringify(data) }).catch(() => {});

let settings = { rings: {} };
let lastStatus = null;
let lastMoney = null;

/* ---------- status rings ---------- */
const RINGS = [
    { key: 'health', icon: 'fa-heart', color: '#3ecf72' },
    { key: 'armor', icon: 'fa-shield-halved', color: '#4c8dff', hideAtZero: true },
    { key: 'hunger', icon: 'fa-burger', color: '#ffb547' },
    { key: 'thirst', icon: 'fa-droplet', color: '#38bdf8' },
    { key: 'stress', icon: 'fa-brain', color: '#ff5468', hideAtZero: true },
    { key: 'oxygen', icon: 'fa-lungs', color: '#a5f3fc', hideWhenMissing: true },
    { key: 'voice', icon: 'fa-microphone', color: '#00ff6a', voice: true },
];
const CIRC = 107; // 2 * PI * 17

const statusEl = $('status');
const rings = {};
RINGS.forEach((r) => {
    const el = document.createElement('div');
    el.className = 'ring' + (r.voice ? ' voice' : '');
    el.style.setProperty('--c', r.color);
    el.innerHTML = `<svg viewBox="0 0 42 42"><circle class="bg" cx="21" cy="21" r="17"/><circle class="fg" cx="21" cy="21" r="17"/></svg><i class="fa-solid ${r.icon}"></i>`;
    statusEl.appendChild(el);
    rings[r.key] = { el, fg: el.querySelector('.fg'), icon: el.querySelector('i'), cfg: r };
});

function setRing(key, value) {
    const ring = rings[key];
    const cfg = ring.cfg;
    const missing = value === undefined || value === null;
    const disabled = settings.rings[key] === false;
    const gone = disabled || (cfg.hideWhenMissing && missing) || (cfg.hideAtZero && !missing && value <= 0) || (missing && !cfg.voice);
    ring.el.classList.toggle('gone', gone);
    if (missing) return;
    const v = Math.max(0, Math.min(100, value));
    ring.fg.style.strokeDashoffset = CIRC - (CIRC * v) / 100;
    const lowIsBad = key !== 'stress';
    ring.el.classList.toggle('low', lowIsBad ? v <= 15 && key !== 'armor' : v >= 85);
}

function updateStatus(d) {
    lastStatus = d;
    ['health', 'armor', 'hunger', 'thirst', 'stress', 'oxygen'].forEach((k) => setRing(k, d[k]));

    // voice: ring shows range (1-3), icon lights up while talking
    const voice = rings.voice;
    setRing('voice', ((d.voice || 2) / 3) * 100);
    voice.el.classList.toggle('talking', !!d.talking);
    voice.icon.className = `fa-solid ${d.radio ? 'fa-walkie-talkie' : 'fa-microphone'}`;
}

/* ---------- vehicle ---------- */
const RPM_LEN = 419;
function updateVehicle(d) {
    $('left').classList.toggle('map', !!d.map);
    mapVisible = !!d.map;
    syncFrame();
    $('vehicle').classList.toggle('hidden', !d.show);
    if (!d.show) return;

    $('speed').textContent = d.speed;
    $('unit').textContent = d.unit === 'kmh' ? 'KM/H' : 'MPH';
    const rpm = $('rpm');
    rpm.style.strokeDashoffset = RPM_LEN - (RPM_LEN * Math.min(d.rpm, 100)) / 100;
    rpm.classList.toggle('red', d.rpm >= 90);

    $('gear').textContent = d.speed === 0 && d.gear <= 1 ? 'N' : d.gear === 0 ? 'R' : d.gear;
    const belt = $('belt');
    belt.classList.toggle('on', !!d.seatbelt);
    belt.innerHTML = `<i class="fa-solid ${d.seatbelt ? 'fa-user-shield' : 'fa-user-slash'}"></i>`;

    const engine = $('engine');
    engine.classList.toggle('warn', d.engine < 60 && d.engine >= 30);
    engine.classList.toggle('bad', d.engine < 30);

    const fuel = $('fuel');
    fuel.style.width = `${Math.max(0, Math.min(100, d.fuel))}%`;
    fuel.classList.toggle('low', d.fuel <= 15);
}

/* ---------- location ---------- */
function updateLocation(d) {
    $('compass').textContent = d.heading;
    $('street').textContent = d.cross ? `${d.street} / ${d.cross}` : d.street;
    $('zone').textContent = d.zone;
}

/* ---------- money ---------- */
let moneyTimer;
function updateMoney(d) {
    lastMoney = d;
    if (settings.money) d.mode = settings.money;
    const box = $('money');
    $('cash').querySelector('span').textContent = fmt(d.cash);
    $('bank').querySelector('span').textContent = fmt(d.bank);
    box.classList.toggle('hidden', d.mode === 'never');

    if (d.change && d.change.amount) {
        const el = $('money-change');
        const plus = d.change.amount > 0;
        el.className = '';
        void el.offsetWidth; // restart animation
        el.className = plus ? 'plus' : 'minus';
        el.textContent = `${plus ? '+' : '-'}${fmt(Math.abs(d.change.amount))} ${d.change.type}`;
    }

    if (d.mode === 'change') {
        box.classList.remove('away');
        clearTimeout(moneyTimer);
        moneyTimer = setTimeout(() => box.classList.add('away'), d.change ? 5000 : 4000);
    } else {
        box.classList.remove('away');
    }
}

/* ---------- minimap frame ---------- */
let mapVisible = false;
let frameStyle = 'frame';
function updateMinimap(d) {
    const a = d.anchor;
    frameStyle = d.style || 'frame';
    const f = $('minimap-frame');
    f.style.left = `${a.left * 100}vw`;
    f.style.top = `${a.top * 100}vh`;
    f.style.width = `${a.width * 100}vw`;
    f.style.height = `${a.height * 100}vh`;
    // status block sits just right of the radar
    document.documentElement.style.setProperty('--map-right', `${(a.left + a.width) * 100}vw`);
    syncFrame();
}
function syncFrame() {
    $('minimap-frame').classList.toggle('hidden', !mapVisible || frameStyle === 'none');
}

/* ---------- router ---------- */
window.addEventListener('message', ({ data }) => {
    switch (data.action) {
        case 'visible': $('hud').classList.toggle('hidden', !data.data); break;
        case 'status': updateStatus(data.data); break;
        case 'vehicle': updateVehicle(data.data); break;
        case 'location': updateLocation(data.data); break;
        case 'money': updateMoney(data.data); break;
        case 'minimap': updateMinimap(data.data); break;
    }
});

// browser preview: open web/index.html?preview
if (location.search.includes('preview')) {
    document.body.style.background = '#1d2a24';
    window.postMessage({ action: 'visible', data: true });
    window.postMessage({ action: 'status', data: { health: 82, armor: 40, hunger: 64, thirst: 12, stress: 25, voice: 2, talking: true } });
    window.postMessage({ action: 'vehicle', data: { show: true, map: true, speed: 87, unit: 'mph', rpm: 72, gear: 4, fuel: 46, engine: 92, seatbelt: true } });
    window.postMessage({ action: 'location', data: { street: 'Vinewood Blvd', cross: 'Power St', zone: 'Downtown Vinewood', heading: 'NE' } });
    window.postMessage({ action: 'money', data: { cash: 2450, bank: 18900, mode: 'always', change: { type: 'cash', amount: 250 } } });
}

/* ---------- settings (from /hud) ---------- */
function applySettings(s) {
    settings = s;
    document.documentElement.style.setProperty('--s', (s.scale || 100) / 100);
    $('cine').classList.toggle('hidden', !s.cinematic);
    if (lastStatus) updateStatus(lastStatus);
    if (lastMoney) updateMoney({ ...lastMoney, change: null });
    if (!$('menu').classList.contains('hidden')) fillMenu();
}

/* ---------- /hud menu ---------- */
const menu = $('menu');
const RING_LABELS = { health: 'Health', armor: 'Armor', hunger: 'Hunger', thirst: 'Thirst', stress: 'Stress', voice: 'Voice' };

function fillMenu() {
    menu.querySelectorAll('.toggle').forEach((t) => (t.checked = !!settings[t.dataset.key]));
    menu.querySelectorAll('input[type=range]').forEach((r) => (r.value = settings[r.dataset.key]));
    menu.querySelectorAll('.seg').forEach((seg) => {
        seg.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b.dataset.value === settings[seg.dataset.key]));
    });
    $('scale-val').textContent = `${settings.scale}%`;
    $('zoom-val').textContent = settings.minimapZoom;

    const chips = $('ring-chips');
    chips.innerHTML = '';
    Object.keys(RING_LABELS).forEach((name) => {
        const cfg = RINGS.find((r) => r.key === name);
        const on = settings.rings[name] !== false;
        const chip = document.createElement('button');
        chip.className = 'chip' + (on ? ' on' : '');
        chip.style.setProperty('--c', cfg.color);
        chip.innerHTML = `<i class="fa-solid ${cfg.icon}"></i>${RING_LABELS[name]}`;
        chip.addEventListener('click', () => post('settings:update', { key: 'ring', value: { name, enabled: !on } }));
        chips.appendChild(chip);
    });
}

menu.querySelectorAll('.toggle').forEach((t) =>
    t.addEventListener('change', () => post('settings:update', { key: t.dataset.key, value: t.checked })));

menu.querySelectorAll('input[type=range]').forEach((r) => {
    r.addEventListener('input', () => {
        if (r.dataset.key === 'scale') {
            $('scale-val').textContent = `${r.value}%`;
            document.documentElement.style.setProperty('--s', r.value / 100); // live preview while dragging
        } else {
            $('zoom-val').textContent = r.value;
        }
    });
    r.addEventListener('change', () => post('settings:update', { key: r.dataset.key, value: Number(r.value) }));
});

menu.querySelectorAll('.seg').forEach((seg) =>
    seg.querySelectorAll('button').forEach((b) =>
        b.addEventListener('click', () => post('settings:update', { key: seg.dataset.key, value: b.dataset.value }))));

menu.querySelectorAll('[data-action]').forEach((b) =>
    b.addEventListener('click', () => post(b.dataset.action === 'reset' ? 'settings:reset' : 'settings:close')));

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !menu.classList.contains('hidden')) post('settings:close');
});

window.addEventListener('message', ({ data }) => {
    if (data.action === 'settings') applySettings(data.data);
    if (data.action === 'menu') {
        menu.classList.toggle('hidden', !data.data.open);
        if (data.data.open) {
            settings = data.data.settings;
            fillMenu();
        }
    }
});

if (location.search.includes('menu')) {
    window.postMessage({ action: 'menu', data: { open: true, settings: { visible: true, cinematic: false, scale: 100, speedUnit: 'mph', minimapOnFoot: false, minimapFrame: true, minimapZoom: 1100, location: true, stress: true, money: 'change', rings: { health: true, armor: true, hunger: true, thirst: true, stress: false, voice: true } } } });
}

// tell Lua the page is ready, so it (re)sends everything — after a resource restart the
// first messages arrive before this page has loaded and would otherwise be lost
post('ready');
