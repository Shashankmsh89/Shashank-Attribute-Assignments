function normalizeActiveValue(value) {
    return value === true || value === 'true';
}

export function createAttributeDraft(values) {
    return {
        id: values.attributeId || `attr-${Date.now()}`,
        attributeName: values.attributeName.trim(),
        businessUnit: values.businessUnit,
        customerLocation: values.customerLocation,
        company: values.company,
        isActive: normalizeActiveValue(values.isActive),
        createdOn: values.createdOn,
        notes: values.notes.trim(),
        createdBy: 'Administrator'
    };
}

export function addAttribute(state, draft) {
    return {
        ...state,
        attributes: [{ ...draft, isActive: normalizeActiveValue(draft.isActive) }, ...state.attributes]
    };
}

export function updateAttribute(state, id, draft) {
    return {
        ...state,
        attributes: state.attributes.map((attribute) =>
            attribute.id === id ? { ...attribute, ...draft, isActive: normalizeActiveValue(draft.isActive) } : attribute
        )
    };
}

export function deleteAttribute(state, id) { return { ...state, attributes: state.attributes.filter((attribute) => attribute.id !== id) }; }
export function getAttributeById(attributes, id) { return attributes.find((attribute) => attribute.id === id) || null; }
export function filterAttributes(attributes, filters) { const search = (filters.search || '').trim().toLowerCase(); return attributes.filter((attribute) => { const isActive = normalizeActiveValue(attribute.isActive); const matchesSearch = !search || [attribute.attributeName, attribute.businessUnit, attribute.customerLocation, attribute.company, attribute.notes].join(' ').toLowerCase().includes(search); const matchesBusinessUnit = !filters.businessUnit || attribute.businessUnit === filters.businessUnit; const matchesStatus = !filters.status || (filters.status === 'active' ? isActive : !isActive); return matchesSearch && matchesBusinessUnit && matchesStatus; }); }
export function sortAttributes(attributes, sortState) { const direction = sortState.direction === 'asc' ? 1 : -1; const sorted = [...attributes]; sorted.sort((left, right) => { const leftValue = left[sortState.field] ?? ''; const rightValue = right[sortState.field] ?? ''; if (typeof leftValue === 'boolean') return (leftValue === rightValue ? 0 : leftValue ? 1 : -1) * direction; return String(leftValue).localeCompare(String(rightValue), undefined, { sensitivity: 'base' }) * direction; }); return sorted; }
export function paginateAttributes(attributes, page, pageSize) { const start = (page - 1) * pageSize; return attributes.slice(start, start + pageSize); }
