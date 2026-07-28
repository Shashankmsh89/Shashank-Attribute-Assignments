export function collectFormValues(form) {
    const data = new FormData(form);
    const values = Object.fromEntries(data.entries());
    const activeRadio = form.querySelector('input[name="isActive"]:checked');
    values.isActive = activeRadio ? activeRadio.value === 'true' : data.get('isActive') === 'true';
    return values;
}
export function resetFormState(form) { form.dataset.dirty = 'false'; form.dataset.pristine = 'true'; form.querySelectorAll('[data-touched]').forEach((field) => field.removeAttribute('data-touched')); }
export function markFieldTouched(form, fieldName) { const field = form.elements[fieldName]; if (field) field.setAttribute('data-touched', 'true'); form.dataset.touched = 'true'; }
export function markFormDirty(form) { form.dataset.dirty = 'true'; form.dataset.pristine = 'false'; }
export function clearFieldErrors(form) { form.querySelectorAll('[data-error-for]').forEach((item) => { item.textContent = ''; item.hidden = true; }); form.querySelectorAll('input, select, textarea').forEach((input) => input.removeAttribute('aria-invalid')); }
export function applyFieldErrors(form, errors) { Object.entries(errors).forEach(([fieldName, message]) => { const input = form.elements[fieldName]; const errorNode = form.querySelector(`[data-error-for="${fieldName}"]`); if (input) input.setAttribute('aria-invalid', 'true'); if (errorNode) { errorNode.textContent = message; errorNode.hidden = false; } }); }
