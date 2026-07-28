const NAMESPACE = 'attribute-app';
const STORAGE_KEY = `${NAMESPACE}:state`;
const DEFAULT_STATE = { attributes: [], lookups: { businessUnits: [], companies: [], locations: [] }, theme: 'light' };

export async function fetchJson(url, signal) { const response = await fetch(url, { signal }); if (!response.ok) throw new Error(`Failed to load ${url}`); return response.json(); }
export function getStorageKey(name) { return `${NAMESPACE}:${name}`; }
export function getState() { try { const raw = localStorage.getItem(STORAGE_KEY); return raw ? JSON.parse(raw) : { ...DEFAULT_STATE }; } catch { return { ...DEFAULT_STATE }; } }
export function saveState(state) { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }
export async function initializeApplication(signal) { const stored = getState(); if (stored.attributes?.length && stored.lookups?.businessUnits?.length) return stored; const [attributes, businessUnits, companies, locations] = await Promise.all([fetchJson('./data/attributes.json', signal), fetchJson('./data/businessUnits.json', signal), fetchJson('./data/companies.json', signal), fetchJson('./data/locations.json', signal)]); const nextState = { ...stored, attributes, lookups: { businessUnits, companies, locations } }; saveState(nextState); return nextState; }
export function getTheme() { return getState().theme || 'light'; }
export function saveTheme(theme) { const nextState = getState(); nextState.theme = theme; saveState(nextState); }
