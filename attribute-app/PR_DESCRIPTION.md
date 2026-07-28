Title: UI: compact add-form layout and segmented status control; responsive table fixes; pagination improvements

Summary:
- Tighten the Add/Edit form layout so the create page appears more compact and centered.
- Replace the Status radio controls with a segmented pill-style UI for a modern look.
- Improve responsive behavior of the attribute table (remove hard min-width and add mobile card layout tweaks).
- Add previous/next controls and a page label in pagination.

Files changed (high level):
- css/pages.css
- css/layout.css
- css/components.css
- js/main.js
- js/list.js

Testing steps:
1. Run a local static server from the project root (e.g., `python -m http.server 8000`).
2. Open `http://127.0.0.1:8000/` and verify dashboard, mobile layout, pagination controls.
3. Open `add-attribute.html` and confirm the form is compact and the Status control is segmented and selectable.

Notes:
- The scripts in `scripts/` provide convenience to create a branch, commit, and push if desired.
- If you prefer SSH-based remotes, replace the HTTPS URL in the scripts with your SSH remote.

