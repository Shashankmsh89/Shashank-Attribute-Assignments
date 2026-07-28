import { initializeApplication, saveState } from './storage.js';
import { addAttribute, deleteAttribute, filterAttributes, getAttributeById, paginateAttributes, sortAttributes, updateAttribute } from './attributes.js';
import { getFilteredLookups } from './lookups.js';
import { validateAttributeForm, getErrorSummary } from './validation.js';
import { collectFormValues, clearFieldErrors, applyFieldErrors, markFieldTouched, markFormDirty, resetFormState } from './forms.js';
import { renderAttributeTable, renderErrorState, renderLoadingState, renderPagination, renderPaginationStatus, updateResultsSummary } from './list.js';
import { getDefaultDate } from './dateUtils.js';
import { bindDelegatedActions, debounce, notify, showToast } from './events.js';
import { initThemeToggle } from './theme.js';

const page = document.body.dataset.page || 'dashboard';
const viewState = { appState: null, currentPage: 1, filters: { search: '', businessUnit: '', status: '' }, sort: { field: 'createdOn', direction: 'desc' }, pageSize: 6, controller: null };

function syncUrl() { const params = new URLSearchParams(); if (viewState.filters.search) params.set('search', viewState.filters.search); if (viewState.filters.businessUnit) params.set('businessUnit', viewState.filters.businessUnit); if (viewState.filters.status) params.set('status', viewState.filters.status); const query = params.toString(); const currentUrl = `${window.location.pathname}${query ? `?${query}` : ''}`; window.history.replaceState({}, '', currentUrl); }
function populateSelect(select, options, selectedValue, placeholder) { select.replaceChildren(); const emptyOption = document.createElement('option'); emptyOption.value = ''; emptyOption.textContent = placeholder; select.append(emptyOption); options.forEach((option) => { const choice = document.createElement('option'); choice.value = option.id; choice.textContent = option.name; if (selectedValue === option.id) choice.selected = true; select.append(choice); }); }
function getPageSize() { return window.innerWidth < 700 ? 4 : 6; }
function setupCreatedOnCalendar(field) {
  if (!field) return;
  const wrapper = field.closest('.field-group');
  if (!wrapper || wrapper.querySelector('.calendar-toolbar')) return;
  const toolbar = document.createElement('div');
  toolbar.className = 'calendar-toolbar';
  const picker = document.createElement('button');
  picker.type = 'button';
  picker.className = 'btn btn--ghost calendar-picker';
  // Accessible icon-only button that opens native date picker when available
  picker.setAttribute('aria-label', 'Pick date');
  picker.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false"><path d="M7 11H9V13H7V11Z" fill="currentColor"/><path d="M11 11H13V13H11V11Z" fill="currentColor"/><path d="M15 11H17V13H15V11Z" fill="currentColor"/><path fill-rule="evenodd" clip-rule="evenodd" d="M7 4C6.44772 4 6 4.44772 6 5V6H5C3.89543 6 3 6.89543 3 8V19C3 20.1046 3.89543 21 5 21H19C20.1046 21 21 20.1046 21 19V8C21 6.89543 20.1046 6 19 6H18V5C18 4.44772 17.5523 4 17 4C16.4477 4 16 4.44772 16 5V6H8V5C8 4.44772 7.55228 4 7 4ZM5 9H19V19H5V9Z" fill="currentColor"/></svg>';
  picker.addEventListener('click', (event) => {
    event.preventDefault();
    if (typeof field.showPicker === 'function') {
      field.showPicker();
    } else {
      field.focus();
    }
  });
  toolbar.append(picker);
  wrapper.append(toolbar);
}
function renderDashboard(table, resultsStatus, pagination, paginationLabel) { if (!viewState.appState) return; const filtered = filterAttributes(viewState.appState.attributes, viewState.filters); const sorted = sortAttributes(filtered, viewState.sort); const pageSize = getPageSize(); viewState.pageSize = pageSize; const totalPages = Math.max(1, Math.ceil(sorted.length / viewState.pageSize)); const currentPage = Math.min(viewState.currentPage, totalPages); viewState.currentPage = currentPage; const visible = paginateAttributes(sorted, viewState.currentPage, viewState.pageSize); renderAttributeTable(table, visible, viewState.appState.lookups); renderPagination(pagination, viewState.currentPage, totalPages); renderPaginationStatus(paginationLabel, viewState.currentPage, totalPages); updateResultsSummary(resultsStatus, visible.length, sorted.length, viewState.filters); const totalCount = document.getElementById('stat-total'); const activeCount = document.getElementById('stat-active'); const inactiveCount = document.getElementById('stat-inactive'); if (totalCount) totalCount.textContent = String(viewState.appState.attributes.length); if (activeCount) activeCount.textContent = String(viewState.appState.attributes.filter((attribute) => attribute.isActive).length); if (inactiveCount) inactiveCount.textContent = String(viewState.appState.attributes.filter((attribute) => !attribute.isActive).length); }
function populateBusinessUnitOptions(businessUnits) { const select = document.getElementById('business-unit'); if (!select) return; populateSelect(select, businessUnits, viewState.filters.businessUnit, 'All business units'); }
async function initDashboard() {
  const table = document.querySelector('[data-table]'); const resultsStatus = document.getElementById('results-status'); const filterForm = document.getElementById('filter-form'); const pagination = document.getElementById('pagination'); const paginationLabel = document.getElementById('pagination-label'); const params = new URLSearchParams(window.location.search); viewState.filters.search = params.get('search') || ''; viewState.filters.businessUnit = params.get('businessUnit') || ''; viewState.filters.status = params.get('status') || ''; if (filterForm) { filterForm.elements.search.value = viewState.filters.search; filterForm.elements.businessUnit.value = viewState.filters.businessUnit; filterForm.elements.status.value = viewState.filters.status; }
  renderLoadingState(table);
  try { viewState.controller?.abort(); const controller = new AbortController(); viewState.controller = controller; viewState.appState = await initializeApplication(controller.signal); populateBusinessUnitOptions(viewState.appState.lookups.businessUnits); renderDashboard(table, resultsStatus, pagination, paginationLabel); showToast('Catalog loaded', 'success'); } catch (error) { if (error.name === 'AbortError') return; renderErrorState(table, 'The catalog could not be loaded.', () => initDashboard()); notify('The catalog could not be loaded. Please retry.', 'error'); }
  bindDelegatedActions(document.body, { sort: (_event, target) => { const field = target.dataset.sortBy; viewState.sort = viewState.sort.field === field && viewState.sort.direction === 'asc' ? { field, direction: 'desc' } : { field, direction: 'asc' }; renderDashboard(table, resultsStatus, pagination, paginationLabel); }, paginate: (_event, target) => { viewState.currentPage = Number(target.dataset.page || 1); renderDashboard(table, resultsStatus, pagination, paginationLabel); }, delete: (_event, target) => { const id = target.dataset.id; if (!id) return; const nextState = deleteAttribute(viewState.appState, id); viewState.appState = nextState; saveState(nextState); notify('Attribute deleted successfully.', 'success'); renderDashboard(table, resultsStatus, pagination, paginationLabel); } });
  filterForm.addEventListener('submit', (event) => { event.preventDefault(); viewState.filters.search = filterForm.elements.search.value.trim(); viewState.filters.businessUnit = filterForm.elements.businessUnit.value; viewState.filters.status = filterForm.elements.status.value; viewState.currentPage = 1; syncUrl(); renderDashboard(table, resultsStatus, pagination, paginationLabel); });
  filterForm.addEventListener('reset', () => { viewState.filters = { search: '', businessUnit: '', status: '' }; viewState.currentPage = 1; window.setTimeout(() => { syncUrl(); renderDashboard(table, resultsStatus, pagination, paginationLabel); }, 0); });
  filterForm.addEventListener('input', debounce(() => { viewState.filters.search = filterForm.elements.search.value.trim(); viewState.filters.businessUnit = filterForm.elements.businessUnit.value; viewState.filters.status = filterForm.elements.status.value; viewState.currentPage = 1; syncUrl(); renderDashboard(table, resultsStatus, pagination, paginationLabel); }, 220));
  window.addEventListener('resize', debounce(() => { renderDashboard(table, resultsStatus, pagination, paginationLabel); }, 180));
  document.addEventListener('submit', (event) => { if (event.target.matches('[data-delete-form="true"]')) { event.preventDefault(); const id = event.target.elements.id?.value; if (!id) return; const nextState = deleteAttribute(viewState.appState, id); viewState.appState = nextState; saveState(nextState); notify('Attribute deleted successfully.', 'success'); renderDashboard(table, resultsStatus, pagination, paginationLabel); } });
}
async function initFormPage() {
  const form = document.getElementById('attribute-form'); const errorSummary = document.getElementById('form-error-summary'); const businessUnitField = document.getElementById('businessUnit'); const customerLocationField = document.getElementById('customerLocation'); const companyField = document.getElementById('company'); const createdOnField = document.getElementById('createdOn'); if (!form) return; try {
    const appState = await initializeApplication(); viewState.appState = appState; populateSelect(businessUnitField, appState.lookups.businessUnits, '', 'Select business unit'); populateSelect(customerLocationField, [], '', 'Select location'); populateSelect(companyField, [], '', 'Select company'); // populate dependent selects with full lists when no business unit is chosen
    syncDependentOptions(form, appState.lookups);
    if (createdOnField && !createdOnField.value) createdOnField.value = getDefaultDate(); setupCreatedOnCalendar(createdOnField); if (page === 'edit') { const id = new URLSearchParams(window.location.search).get('id'); const attribute = getAttributeById(appState.attributes, id); if (!attribute) { notify('The requested attribute could not be found.', 'error'); return; } populateForm(form, attribute, appState.lookups); }
    form.addEventListener('input', (event) => { markFormDirty(form); markFieldTouched(form, event.target.name); if (event.target.name === 'businessUnit') syncDependentOptions(form, appState.lookups); });
    form.addEventListener('change', (event) => { markFormDirty(form); markFieldTouched(form, event.target.name); if (event.target.name === 'businessUnit') syncDependentOptions(form, appState.lookups); });
    form.addEventListener('reset', () => { window.setTimeout(() => { clearFieldErrors(form); resetFormState(form); if (createdOnField) createdOnField.value = getDefaultDate(); syncDependentOptions(form, appState.lookups); }, 0); });
    form.addEventListener('submit', (event) => {
      event.preventDefault(); clearFieldErrors(form); const values = collectFormValues(form); const errors = validateAttributeForm(values); if (Object.keys(errors).length) { applyFieldErrors(form, errors); errorSummary.hidden = false; errorSummary.innerHTML = ''; const list = document.createElement('ul'); getErrorSummary(errors).forEach((entry) => { const item = document.createElement('li'); item.textContent = entry.message; list.append(item); }); errorSummary.append(list); const firstError = document.querySelector('[aria-invalid="true"]'); if (firstError) firstError.focus(); return; }
      const draft = { ...values, attributeName: values.attributeName.trim(), notes: values.notes.trim(), createdOn: values.createdOn };
      let nextState; if (page === 'edit') { const id = form.elements.attributeId.value; nextState = updateAttribute(viewState.appState, id, draft); notify('Attribute updated successfully.', 'success'); } else { nextState = addAttribute(viewState.appState, { id: `attr-${Date.now()}`, attributeName: draft.attributeName, businessUnit: draft.businessUnit, customerLocation: draft.customerLocation, company: draft.company, isActive: draft.isActive, createdOn: draft.createdOn, notes: draft.notes, createdBy: 'Administrator' }); notify('Attribute created successfully.', 'success'); }
      viewState.appState = nextState; saveState(nextState); window.location.href = 'index.html';
    });
  } catch (error) { notify('The form could not be loaded.', 'error'); }
}
function populateForm(form, attribute, lookups) {
  const businessUnitField = form.elements.businessUnit;
  const customerLocationField = form.elements.customerLocation;
  const companyField = form.elements.company;
  const isActive = attribute.isActive === true || attribute.isActive === 'true';
  form.elements.attributeId.value = attribute.id;
  form.elements.attributeName.value = attribute.attributeName;
  form.elements.businessUnit.value = attribute.businessUnit;
  form.elements.createdOn.value = attribute.createdOn;
  form.elements.notes.value = attribute.notes || '';
  const activeRadios = form.querySelectorAll('input[name="isActive"]');
  activeRadios.forEach((radio) => { radio.checked = radio.value === String(isActive); });
  populateSelect(businessUnitField, lookups.businessUnits, attribute.businessUnit, 'Select business unit');
  syncDependentOptions(form, lookups, attribute.customerLocation, attribute.company);
}
function syncDependentOptions(form, lookups, selectedLocation, selectedCompany) { const businessUnitValue = form.elements.businessUnit.value; const filtered = getFilteredLookups(lookups, businessUnitValue); populateSelect(form.elements.customerLocation, filtered.locations, selectedLocation || '', 'Select location'); populateSelect(form.elements.company, filtered.companies, selectedCompany || '', 'Select company'); }
window.addEventListener('DOMContentLoaded', () => { initThemeToggle(document.getElementById('theme-toggle')); if (page === 'dashboard') initDashboard(); else initFormPage(); });
