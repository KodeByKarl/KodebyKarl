const state = {
    items: [],
    category: 'all',
    query: '',
    nextUpdateAt: 0,
};

const listEl = document.getElementById('list');
const catsEl = document.getElementById('cats');
const searchEl = document.getElementById('search');
const countdownEl = document.getElementById('countdown');
const refreshEl = document.getElementById('refresh');

function formatMoney(n) {
    return '$' + Math.max(0, Math.floor(n || 0)).toLocaleString();
}

function formatCountdown(seconds) {
    if (seconds < 0) seconds = 0;
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) return h + 'h ' + m + 'm';
    if (m > 0) return m + 'm';
    return seconds + 's';
}

function categories() {
    const set = new Set();
    state.items.forEach(function (item) {
        set.add(item.category || 'General');
    });
    return ['all'].concat(Array.from(set));
}

function filteredItems() {
    const q = state.query.trim().toLowerCase();
    return state.items.filter(function (item) {
        const catOk = state.category === 'all' || item.category === state.category;
        const searchOk =
            !q ||
            String(item.label || '').toLowerCase().indexOf(q) !== -1 ||
            String(item.item || '').toLowerCase().indexOf(q) !== -1;
        return catOk && searchOk;
    });
}

function renderCats() {
    catsEl.innerHTML = '';
    categories().forEach(function (cat) {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'cat' + (state.category === cat ? ' active' : '');
        btn.textContent = cat;
        btn.addEventListener('click', function () {
            state.category = cat;
            render();
        });
        catsEl.appendChild(btn);
    });
}

function renderList() {
    const rows = filteredItems();
    listEl.innerHTML = '';

    if (!rows.length) {
        const empty = document.createElement('div');
        empty.className = 'empty';
        empty.textContent = 'No items match that search.';
        listEl.appendChild(empty);
        return;
    }

    rows.forEach(function (item) {
        const card = document.createElement('article');
        card.className = 'card';

        const wrap = document.createElement('div');
        wrap.className = 'thumb-wrap';

        const img = document.createElement('img');
        img.className = 'thumb';
        img.alt = item.label || item.item;
        img.src = item.image || '';

        const ph = document.createElement('div');
        ph.className = 'ph';
        ph.textContent = String(item.label || '?').slice(0, 1).toUpperCase();

        img.addEventListener('error', function () {
            img.classList.add('hidden');
            ph.classList.add('show');
        });

        wrap.appendChild(img);
        wrap.appendChild(ph);

        const name = document.createElement('div');
        name.className = 'name';
        name.textContent = item.label || item.item;

        const catLabel = document.createElement('div');
        catLabel.className = 'cat-label';
        catLabel.textContent = item.category || 'General';

        const price = document.createElement('div');
        price.className = 'price';
        price.textContent = formatMoney(item.price);

        card.appendChild(wrap);
        card.appendChild(name);
        card.appendChild(catLabel);
        card.appendChild(price);
        listEl.appendChild(card);
    });
}

function render() {
    renderCats();
    renderList();
}

function applyCatalog(data) {
    if (!data || typeof data !== 'object') return;
    state.items = Array.isArray(data.items) ? data.items : [];
    state.nextUpdateAt = Number(data.nextUpdateAt) || 0;
    render();
}

async function loadCatalog() {
    try {
        const data = await fetchNui('grim-market:getCatalog');
        applyCatalog(data);
    } catch (err) {
        listEl.innerHTML = '<div class="empty">Could not load prices.</div>';
    }
}

function tickCountdown() {
    if (!state.nextUpdateAt) {
        countdownEl.textContent = 'Live';
        return;
    }
    const remaining = Math.floor(state.nextUpdateAt - Date.now() / 1000);
    countdownEl.textContent = formatCountdown(remaining);
}

searchEl.addEventListener('input', function () {
    state.query = searchEl.value;
    renderList();
});

refreshEl.addEventListener('click', function () {
    loadCatalog();
});

window.addEventListener('message', function (e) {
    if (e.data && e.data.type === 'pricesUpdated') {
        applyCatalog(e.data.catalog);
    }
});

loadCatalog();
setInterval(tickCountdown, 1000);
tickCountdown();
