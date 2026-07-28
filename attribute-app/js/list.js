import { formatDate, formatRelativeTime } from './dateUtils.js';
export function renderLoadingState(table) { const body = table.querySelector('tbody'); const fragment = document.createDocumentFragment(); for (let index = 0; index < 5; index += 1) { const row = document.createElement('tr'); const cell = document.createElement('td'); cell.colSpan = 7; cell.textContent = 'Loading records…'; row.append(cell); fragment.append(row); } body.replaceChildren(fragment); }
export function renderErrorState(table, message, onRetry) { const body = table.querySelector('tbody'); const row = document.createElement('tr'); const cell = document.createElement('td'); cell.colSpan = 7; const text = document.createElement('p'); text.textContent = message; cell.append(text); if (onRetry) { const button = document.createElement('button'); button.type = 'button'; button.className = 'btn btn--ghost'; button.textContent = 'Retry'; button.addEventListener('click', onRetry); cell.append(button); } row.append(cell); body.replaceChildren(row); }
function findLookupName(options, id) {
    if (!options || !id) return id || '';
    const item = options.find((option) => option.id === id);
    return item ? item.name : id;
}

export function renderAttributeTable(table, attributes, lookups) {
    const body = table.querySelector('tbody');
    const fragment = document.createDocumentFragment();
    if (!attributes.length) {
        const row = document.createElement('tr');
        const cell = document.createElement('td');
        cell.colSpan = 7;
        cell.textContent = 'No records matched the current filters.';
        row.append(cell);
        fragment.append(row);
        body.replaceChildren(fragment);
        return;
    }
    attributes.forEach((attribute) => {
        const row = document.createElement('tr');
        const nameCell = document.createElement('th');
        nameCell.scope = 'row';
        nameCell.textContent = attribute.attributeName;
        const businessUnitCell = document.createElement('td');
        businessUnitCell.dataset.label = 'Business unit';
        businessUnitCell.textContent = findLookupName(lookups?.businessUnits, attribute.businessUnit);
        const locationCell = document.createElement('td');
        locationCell.dataset.label = 'Location';
        locationCell.textContent = findLookupName(lookups?.locations, attribute.customerLocation);
        const companyCell = document.createElement('td');
        companyCell.dataset.label = 'Company';
        companyCell.textContent = findLookupName(lookups?.companies, attribute.company);
        const statusCell = document.createElement('td');
        statusCell.dataset.label = 'Status';
        const badge = document.createElement('span');
        badge.className = attribute.isActive ? 'badge badge--active' : 'badge badge--inactive';
        badge.textContent = attribute.isActive ? 'Active' : 'Inactive';
        statusCell.append(badge);
        const dateCell = document.createElement('td');
        dateCell.dataset.label = 'Created on';
        const time = document.createElement('time');
        time.dateTime = attribute.createdOn;
        time.textContent = formatDate(attribute.createdOn);
        const rel = document.createElement('div');
        rel.className = 'field-hint';
        rel.textContent = formatRelativeTime(attribute.createdOn);
        dateCell.append(time, rel);
        const actionsCell = document.createElement('td');
        actionsCell.dataset.label = 'Actions';
        const editLink = document.createElement('a');
        editLink.href = `edit-attribute.html?id=${attribute.id}`;
        editLink.className = 'link-action';
        editLink.textContent = 'Edit'; const form = document.createElement('form'); form.method = 'post'; form.className = 'inline-form'; form.dataset.deleteForm = 'true'; const hiddenInput = document.createElement('input'); hiddenInput.type = 'hidden'; hiddenInput.name = 'id'; hiddenInput.value = attribute.id; const deleteButton = document.createElement('button'); deleteButton.type = 'submit'; deleteButton.className = 'btn btn--ghost'; deleteButton.dataset.action = 'delete'; deleteButton.dataset.id = attribute.id; deleteButton.textContent = 'Delete'; form.append(hiddenInput, deleteButton); actionsCell.append(editLink, form); row.append(nameCell, businessUnitCell, locationCell, companyCell, statusCell, dateCell, actionsCell); fragment.append(row);
    }); body.replaceChildren(fragment);
}
export function renderPagination(container, page, totalPages) {
    container.replaceChildren();
    if (!totalPages || totalPages <= 1) {
        return;
    }

    const fragment = document.createDocumentFragment();
    const prevButton = document.createElement('button');
    prevButton.type = 'button';
    prevButton.className = page === 1 ? 'btn btn--secondary' : 'btn';
    prevButton.dataset.action = 'paginate';
    prevButton.dataset.page = String(Math.max(1, page - 1));
    prevButton.textContent = 'Previous';
    prevButton.disabled = page === 1;
    fragment.append(prevButton);

    for (let index = 1; index <= totalPages; index += 1) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'btn btn--secondary';
        button.dataset.action = 'paginate';
        button.dataset.page = String(index);
        button.textContent = String(index);
        if (index === page) {
            button.setAttribute('aria-current', 'page');
        }
        fragment.append(button);
    }

    const nextButton = document.createElement('button');
    nextButton.type = 'button';
    nextButton.className = page === totalPages ? 'btn btn--secondary' : 'btn';
    nextButton.dataset.action = 'paginate';
    nextButton.dataset.page = String(Math.min(totalPages, page + 1));
    nextButton.textContent = 'Next';
    nextButton.disabled = page === totalPages;
    fragment.append(nextButton);
    container.append(fragment);
}

export function renderPaginationStatus(container, page, totalPages) {
    if (!container) return;
    container.textContent = `Page ${page} of ${totalPages}`;
}
export function updateResultsSummary(container, totalVisible, totalMatches, filters) { const terms = []; if (filters.search) terms.push(`Search: “${filters.search}”`); if (filters.businessUnit) terms.push(`Business unit: ${filters.businessUnit}`); if (filters.status) terms.push(`Status: ${filters.status}`); const summary = totalMatches ? `${totalVisible} of ${totalMatches} records visible${terms.length ? ` · ${terms.join(' · ')}` : ''}` : 'No records matched the current filters.'; container.textContent = summary; }
