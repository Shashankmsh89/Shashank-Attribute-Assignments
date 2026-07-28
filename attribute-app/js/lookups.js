export function formatLookupOptions(options) { return options.map((option) => ({ id: option.id, name: option.name })); }
export function getFilteredLookups(lookups, businessUnitId) {
    if (!businessUnitId) {
        return {
            locations: lookups.locations || [],
            companies: lookups.companies || []
        };
    }

    const locations = (lookups.locations || []).filter((location) => location.businessUnitId === businessUnitId);
    const companies = (lookups.companies || []).filter((company) => company.businessUnitId === businessUnitId);
    return { locations, companies };
}
