# Attribute Management System

A modern, accessibility-first **Attribute Management System** built using **HTML5**, **CSS3**, and **Vanilla JavaScript (ES Modules)** without any frontend framework.

This project was developed as part of the **Amicus Fresher Development Program 2026** and demonstrates modern frontend engineering practices including semantic HTML, responsive CSS architecture, accessibility, modular JavaScript, client-side CRUD operations, local storage, and reusable UI components.

---

# Project Objectives

The primary objective of this project is to demonstrate how a complete enterprise-style web application can be developed using only native web technologies while maintaining high standards of accessibility, maintainability, responsiveness, and performance.

The project is divided into three progressive assignments:

- Assignment 1 – Semantic HTML & Accessibility
- Assignment 2 – Responsive CSS Architecture
- Assignment 3 – Interactive JavaScript Application

Each assignment builds upon the previous one without changing the underlying HTML structure.

---

# Features

- Semantic HTML5
- Accessibility-first design
- Responsive Layout
- CSS Grid & Flexbox
- Design Tokens
- Dark Theme
- CRUD Operations
- LocalStorage Persistence
- Debounced Search
- Sorting
- Pagination
- Dependent Dropdowns
- Form Validation
- Event Delegation
- Toast Notifications
- Theme Persistence
- Relative Date Formatting
- Keyboard Navigation
- Screen Reader Friendly

---

# Technology Stack

## Frontend

- HTML5
- CSS3
- JavaScript (ES2023)

## CSS

- CSS Grid
- Flexbox
- Custom Properties
- Container Queries
- Media Queries
- BEM Methodology

## JavaScript

- ES Modules
- Fetch API
- Promise.all()
- AbortController
- LocalStorage
- FormData
- Intl.DateTimeFormat
- Intl.RelativeTimeFormat

---

# Project Structure

attribute-app/

├── index.html

├── add-attribute.html

├── edit-attribute.html

├── css/

│ ├── reset.css

│ ├── tokens.css

│ ├── base.css

│ ├── layout.css

│ ├── components.css

│ ├── utilities.css

│ ├── pages.css

│ └── main.css

├── js/

│ ├── main.js

│ ├── storage.js

│ ├── attributes.js

│ ├── lookups.js

│ ├── validation.js

│ ├── forms.js

│ ├── list.js

│ ├── dom.js

│ ├── dateUtils.js

│ ├── events.js

│ └── theme.js

├── data/

├── assets/

├── README.md

└── BUGS.md

---

# Assignment 1 – Semantic HTML & Accessibility

## Task 1

### Why must `<meta charset>` appear within the first 1024 bytes?

Browsers determine the character encoding while reading the beginning of an HTML document. Placing the `<meta charset="UTF-8">` element within the first 1024 bytes ensures that the browser correctly interprets every character before rendering the page. If the declaration appears too late, some browsers may guess the encoding incorrectly, resulting in corrupted or unreadable text.

### What does `<meta name="theme-color">` control?

The `theme-color` meta tag defines the color used by supported browsers for the browser interface surrounding the webpage. On mobile browsers such as Chrome for Android, it changes the address bar and other browser UI elements to match the application's branding, providing a more integrated user experience.

---

## Task 2

### When does a `<section>` become a landmark?

A `<section>` element only becomes a navigable landmark for assistive technologies when it has an accessible name. This is typically provided using `aria-labelledby` that references a heading within the section, or `aria-label` when no visible heading exists. Named landmarks help screen reader users quickly navigate between meaningful regions of a page.

### Why is a Skip Link important?

A Skip Link allows keyboard and screen reader users to bypass repeated navigation and move directly to the primary content of the page. Without it, users who rely on the keyboard would need to tab through every navigation element each time the page loads.

---

## Task 3

### Why does every form control require a proper `<label>`?

Labels create an explicit relationship between the visible text and its corresponding input element. Clicking the label focuses the associated input, improving usability for all users while ensuring screen readers announce meaningful field names.

### Why is `aria-live="polite"` used for the results area?

The results count changes dynamically after filtering or searching. A polite live region informs assistive technologies about these updates without interrupting the user's current interaction, making dynamic content accessible.

---

## Task 4

### Why is Delete implemented using a POST form instead of a hyperlink?

Deleting data changes the application's state and should never be performed through an HTTP GET request. Search engines, browser prefetching, cached links, or accidental navigation could trigger GET requests unexpectedly.

Using a POST form clearly communicates that the action modifies data, follows HTTP semantics, and reduces the risk of accidental deletions. In real-world applications, POST requests are also protected using CSRF tokens, making destructive actions significantly safer.

---

## Task 5

### Why is `novalidate` used even though validation attributes remain?

The HTML validation attributes (`required`, `pattern`, `minlength`, etc.) still define the validation rules for each field. Adding `novalidate` disables the browser's built-in validation popups, allowing JavaScript to provide a consistent, accessible, and customizable validation experience.

This approach combines HTML constraint metadata with a custom validation interface.

---

## Task 6

### Three layers of validation

Modern web applications rely on three complementary validation layers:

**1. HTML Validation**

Provides immediate feedback using built-in browser constraints.

**2. JavaScript Validation**

Enhances user experience through custom messages, live validation, error summaries, and accessibility improvements.

**3. Server-side Validation**

Performs the final security check before accepting any submitted data.

Both HTML and JavaScript validation can be bypassed using browser developer tools, modified requests, or command-line tools such as `curl`. Therefore, server-side validation is the only mandatory security layer in production systems.

---

## Task 7

### Why use `<time datetime="">` instead of `<span>`?

The `<time>` element provides semantic meaning by exposing machine-readable date and time values through the `datetime` attribute. This enables assistive technologies, search engines, and calendar integrations to understand the date while still displaying a user-friendly format.

A `<span>` only presents visual text and carries no semantic meaning.

---

## Task 8

### Layout Decisions

#### Attribute List

The dashboard places filtering controls above the results table because searching and filtering are the most common user actions. Quick statistics are positioned beside the content to provide immediate contextual information without distracting from the main workflow.

Alternative layouts considered included placing filters inside a sidebar and positioning statistics below the table. These approaches required additional scrolling and increased interaction cost.

For a mobile-first redesign, the sidebar content would move below the primary content while the table would transform into responsive cards.

---

#### Add Attribute

The Add form groups related fields inside fieldsets to improve readability and accessibility. Important fields appear before optional notes so users can complete required information efficiently.

An alternative wizard-style form was rejected because the number of fields does not justify multiple steps.

For smaller devices, the two-column layout collapses into a single-column form.

---

#### Edit Attribute

The Edit page mirrors the Add page to preserve consistency. Existing values are pre-populated, while metadata such as creation date and creator are displayed separately as read-only information.

Keeping both forms visually identical reduces the learning curve and improves usability.

---

## Task 9

### Accessibility Verification

The project was evaluated using multiple accessibility tools because each identifies different categories of issues.

**W3C HTML Validator**
- Validates HTML syntax and standards compliance.

**Lighthouse**
- Evaluates accessibility, best practices, performance, and SEO.

**axe DevTools**
- Performs automated accessibility rule checks.

**Screen Reader Testing**
- Confirms real-world keyboard and assistive technology usability.

### Lighthouse vs axe

Lighthouse effectively identifies issues such as missing document metadata, insufficient color contrast, and general accessibility scoring.

axe DevTools focuses on accessibility rules including ARIA misuse, label associations, landmark structure, and screen reader compatibility.

Both tools overlap on issues such as missing labels and insufficient contrast, while each also reports findings unique to its own testing methodology.

---

# Assignment 2 – CSS Architecture & Responsive Design

## Task 1

### Why use CSS @layer instead of relying only on stylesheet order?

CSS `@layer` provides an explicit cascade order independent of the order in which selectors appear. This makes stylesheet organization predictable and prevents accidental overrides when multiple developers contribute to the same project.

For this project, layers separate concerns into reset, tokens, base, layout, components, utilities, and pages. This structure improves maintainability because each layer has a clearly defined responsibility.

### Why are layered styles harder to override?

Styles inside higher-priority layers always win over styles from lower-priority layers, regardless of selector complexity. This reduces accidental specificity battles but requires developers to understand the defined layer order before overriding styles.

### When is normal stylesheet order still preferable?

For very small projects with only one or two stylesheets, traditional stylesheet order is often simpler and easier to understand. Introducing layers in such cases may add unnecessary complexity.

---

## Task 2

### Why use CSS Custom Properties instead of Sass variables?

CSS Custom Properties exist at runtime. They can be updated dynamically through JavaScript or media queries without recompiling stylesheets. This makes them ideal for theme switching, accessibility adjustments, and responsive design.

In this project, color tokens change instantly when the application switches between light and dark themes by updating the `data-theme` attribute.

### When are Sass variables still useful?

Sass variables are evaluated during compilation. They are useful for compile-time constants, calculations, loops, and generating repetitive CSS that never changes while the application is running.

---

## Task 3

### Why was BEM chosen?

The Block-Element-Modifier (BEM) methodology creates predictable and reusable CSS classes.

Examples:

- `.btn`
- `.btn--primary`
- `.form-field`
- `.form-field__label`
- `.badge--active`

BEM keeps selector specificity low because most selectors consist of single classes rather than deeply nested rules. This reduces maintenance costs and avoids cascading specificity conflicts.

Without a naming convention, selectors often become increasingly specific over time, making future changes difficult and encouraging unnecessary use of `!important`.

---

## Task 4

### Why is `outline: none` without a replacement a WCAG failure?

Keyboard users rely on visible focus indicators to understand which interactive element currently has focus. Removing the default outline without providing an accessible replacement makes keyboard navigation significantly more difficult and violates WCAG accessibility guidelines.

### Why use `:focus-visible` instead of `:focus`?

`:focus-visible` only displays focus indicators when they are helpful, primarily during keyboard navigation. Mouse users generally do not need visible focus rings after clicking an element, resulting in a cleaner visual experience while preserving accessibility.

### Why use logical properties?

Logical properties such as `margin-inline` and `padding-block` adapt automatically to writing directions including right-to-left (RTL) languages. They improve internationalization support without requiring duplicate stylesheets.

---

## Task 5

### Why follow a Mobile-First approach?

Designing for smaller screens first encourages simpler layouts and progressive enhancement. Additional complexity is introduced only when more screen space becomes available.

This approach avoids many layout issues associated with desktop-first designs, where shrinking complex layouts often produces overflow, unnecessary overrides, and maintenance challenges.

### Why use Grid Template Areas?

Grid Template Areas provide readable layout definitions by assigning descriptive names to regions instead of numeric grid coordinates.

For example:

```
header
nav
main
aside
footer
```

This approach improves maintainability and makes responsive layout changes easier to understand.

### Why use `em` breakpoints?

Using `em` units for media queries respects user font-size preferences. If a user increases their browser's default text size, the layout adapts naturally. Pixel-based breakpoints ignore these accessibility preferences.

---

## Task 6

### When do Container Queries outperform Media Queries?

Media Queries respond to the viewport size, while Container Queries respond to the available space inside an individual component.

Container Queries are particularly useful when identical components appear in different layouts, such as a dashboard card displayed inside a sidebar versus the main content area.

Media Queries cannot distinguish between those situations because the viewport size remains the same.

---

## Task 7

### Why use `data-label` with CSS instead of duplicate mobile markup?

Maintaining a single HTML table ensures that all users, including assistive technologies, interact with one consistent source of information.

Using CSS-generated labels through `attr(data-label)` transforms the visual presentation for mobile devices without duplicating content.

### What is the limitation?

Some assistive technologies may not announce generated CSS content consistently. Therefore, semantic HTML structure remains the primary source of accessibility information.

---

## Task 8

### What does `:has()` unlock?

The `:has()` pseudo-class enables parent-level styling based on child elements.

Examples include:

- Highlighting an entire fieldset when any contained input is invalid.
- Styling a card when it contains a selected checkbox.
- Displaying validation states without additional JavaScript.

Before `:has()`, these behaviors typically required JavaScript.

### Why prefer `:user-invalid` over `:invalid`?

`:invalid` becomes active immediately after page load, potentially overwhelming users with error messages before they interact with the form.

`:user-invalid` activates only after user interaction, creating a more user-friendly validation experience.

---

## Task 9

### Why is `transition: all` considered an anti-pattern?

Animating every property forces browsers to monitor unnecessary style changes, reducing rendering performance.

Instead, transitions should target only the properties that actually animate.

### Which properties are inexpensive to animate?

The browser can efficiently animate:

- `transform`
- `opacity`

These properties are processed by the compositor and generally avoid layout recalculation and repaint operations.

### Why respect `prefers-reduced-motion`?

Some users experience discomfort or motion sensitivity when animations are excessive.

The `prefers-reduced-motion` media query respects operating system accessibility preferences by reducing or disabling unnecessary animations.

---

## Task 10

### CSS Specificity Demonstration

Specificity is calculated using four values:

- Inline styles
- IDs
- Classes, attributes, pseudo-classes
- Elements and pseudo-elements

Example ranking:

| Selector | Specificity |
|-----------|-------------|
| `:where(.btn)` | 0,0,0,0 |
| `.btn` | 0,0,1,0 |
| `button.btn` | 0,0,1,1 |
| `:is(.btn)` | 0,0,1,0 |
| `#submit-btn` | 0,1,0,0 |
| Inline Style | 1,0,0,0 |

Although inline styles normally have the highest specificity, an external declaration using `!important` may override them unless the inline style itself is also marked `!important`.

### Rule for using `!important`

`!important` should be avoided in production unless absolutely necessary. Appropriate use cases include utility classes and overriding third-party styles that cannot be modified directly.

---

## Task 11

### Chrome DevTools Observations

The **Styles** panel displays every matching CSS rule and explains which declarations are overridden by the cascade.

The **Computed** panel displays the final computed values after all inheritance, specificity, and cascading have been resolved.

The **Layout** panel visualizes Grid and Flexbox layouts, making responsive debugging significantly easier.

The **Coverage** tool identifies unused CSS and JavaScript. Some unused CSS during a single page interaction is expected because not every component appears simultaneously.

The **Rendering** panel allows simulation of accessibility preferences such as `prefers-reduced-motion`, enabling verification that animations are correctly disabled.

Lighthouse combines automated analysis for performance, accessibility, best practices, and SEO into a single report, helping identify areas requiring improvement.

---

# Assignment 3 – Vanilla JavaScript & Application Architecture

## Task 1

### Why use ES Modules for this project?

ES Modules divide the application into small, reusable files where each module has a single responsibility. Instead of placing every function inside one large script, functionality is organized into modules such as storage, validation, rendering, events, and theme management.

This separation improves maintainability, readability, and testability while reducing code duplication.

### Trade-offs of ES Modules

Advantages:

- Better organization
- Explicit imports and exports
- Strict mode enabled automatically
- Deferred loading by default
- Reusable code

Disadvantages:

- Requires an HTTP server
- Cannot be executed reliably using `file://`
- Slightly more files to manage

### What does "deferred by default" mean?

Module scripts behave similarly to scripts loaded with the `defer` attribute. They download while the HTML parser continues processing the document and execute only after the document has been parsed.

This means most DOM elements are already available without manually waiting for `DOMContentLoaded`.

### Why doesn't `file://` work?

Modern browsers treat ES Modules as network resources and enforce CORS restrictions.

Opening HTML directly from the filesystem (`file://`) blocks module imports.

Using VS Code Live Server provides a local HTTP server, allowing module loading and Fetch API requests to function correctly.

---

## Task 3

### Why namespace LocalStorage keys?

Using namespaced keys such as:

```
ams.attributes
ams.theme
ams.seedVersion
```

prevents conflicts with other applications running on the same origin.

If multiple applications store a generic key like:

```
theme
```

they may accidentally overwrite each other's data.

### Why wrap LocalStorage access inside try/catch?

Reading or parsing LocalStorage can fail due to:

- Invalid JSON
- Corrupted stored data
- Storage quota limitations
- Private browsing restrictions

Handling these exceptions prevents the application from crashing unexpectedly.

---

## Task 4

### Why use `DocumentFragment` instead of appending rows individually?

Appending DOM nodes one at a time causes repeated layout calculations and browser reflows.

`DocumentFragment` creates an in-memory container where all elements are assembled before a single insertion into the document.

This significantly reduces rendering overhead for larger tables.

### When is `innerHTML` acceptable?

`innerHTML` is acceptable when rendering trusted, static markup that is completely controlled by the developer.

### When is `innerHTML` dangerous?

Using `innerHTML` with user-generated content can introduce Cross-Site Scripting (XSS) vulnerabilities by executing malicious HTML or JavaScript.

Using `createElement()` and `textContent` safely escapes user input and avoids these risks.

---

## Task 5

### How does Debounce work?

Debounce delays execution until the user has stopped triggering an event for a specified period.

A timer is restarted after every keystroke. Only when the timer expires does the callback execute.

This prevents unnecessary filtering or rendering while the user is actively typing.

### Why store filter state inside the URL?

Updating the query string allows:

- Refreshing the page without losing filters.
- Sharing filtered URLs.
- Browser Back and Forward buttons working correctly.

---

## Task 6

### What is Event Delegation?

Event Delegation attaches a single event listener to a common parent instead of individual listeners on every child element.

Advantages:

- Lower memory usage
- Automatically supports dynamically created elements

### When does Event Delegation fail?

Delegation relies on event bubbling.

Events such as:

- focus
- blur
- mouseenter
- mouseleave

do not bubble.

For focus events, `focusin` and `focusout` provide bubbling alternatives.

---

## Task 7

### Why paginate on the server?

Client-side pagination is appropriate for small datasets.

Large datasets containing thousands of records require excessive memory, slower rendering, and longer loading times.

Server-side pagination transfers only the required page of data, reducing bandwidth usage and improving performance.

### Future API Contract

A server endpoint would typically receive:

```
?page=2&pageSize=5&sort=name&direction=asc
```

and return:

- Current page
- Total records
- Page size
- Records

This contract allows the frontend to remain unchanged when migrating to a backend.

---

## Task 8

### Why use `setTimeout()` instead of `setInterval()` for Toasts?

Each toast notification should disappear only once.

`setTimeout()` executes a callback a single time.

`setInterval()` repeatedly executes callbacks until manually stopped, making it unsuitable for auto-dismiss notifications.

### Why use a Map of timers?

If multiple toast notifications appear simultaneously, each requires its own timer.

Using a `Map` associates each toast with its corresponding timeout, preventing stale timers from dismissing the wrong notification.

---

## Task 9

### Why use dependent dropdowns?

Dependent dropdowns prevent users from selecting invalid combinations of Business Units and Customer Locations.

### Backend Trade-offs

Option 1: Load all locations once.

Advantages:

- Faster interaction
- No additional network requests

Disadvantages:

- Larger initial payload

Option 2: Request locations after Business Unit selection.

Advantages:

- Smaller initial download

Disadvantages:

- Additional request latency

The best approach depends on dataset size.

---

## Task 10

### Why can't HTML validate uniqueness?

HTML validation only examines a single field.

It cannot compare values against existing records.

Uniqueness checks require JavaScript or server-side validation.

### Why verify that the selected Location belongs to the selected Business Unit?

Although the dropdown restricts available options, users can modify form values using browser developer tools.

Validating relationships again provides defense-in-depth and prevents inconsistent data.

### Why focus the error summary?

Moving keyboard focus directly to the error summary allows assistive technology users to immediately understand why submission failed.

This improves accessibility and follows WCAG guidance.

---

## Task 11

### Validation Strategy

The application implements validation similar to Angular Reactive Forms.

| State | Description |
|--------|-------------|
| Pristine | Field has never been modified |
| Dirty | Field value has changed |
| Touched | Field has received and lost focus |

Displaying validation errors only after a field has been touched prevents overwhelming users with immediate error messages.

### What does Angular provide automatically?

Angular Reactive Forms automatically track touched, dirty, pristine, valid, invalid, and pending states while exposing powerful validation APIs.

Vanilla JavaScript requires these behaviors to be implemented manually.

---

## Task 13

### Promise.all vs Promise.allSettled

`Promise.all()` executes all promises concurrently and immediately rejects if any promise fails.

This fail-fast behavior is appropriate because all lookup files are required before the application can initialize.

`Promise.allSettled()` waits for every promise regardless of failures.

It is useful when partial results remain valuable.

### What does Promise.any solve?

`Promise.any()` resolves as soon as the first promise succeeds.

It is useful when multiple equivalent sources exist and only one successful response is required.

---

## Task 14

### Why is Debounce alone insufficient?

Without request cancellation, an older request may finish after a newer request and overwrite the latest results.

This is known as the stale-response problem.

### How does AbortController solve it?

Each new search request aborts the previous one before it completes.

Only the latest request is allowed to update the interface.

### Other uses of AbortController

- Fetch cancellation
- Event listener cleanup
- ReadableStream cancellation

---

## Task 15

### Why doesn't fetch() reject on HTTP 404?

The Fetch API only rejects promises when a network failure occurs.

HTTP responses such as 404 and 500 are considered successful network operations.

Therefore developers must manually verify:

```javascript
if (!response.ok) {
    throw new Error("Request failed");
}
```

### How does Axios differ?

Axios automatically rejects promises for HTTP status codes outside the successful range, reducing the need for manual response checking.

---

## Task 16

### Why prioritize the user's theme preference?

Once users explicitly choose a theme, that preference should take precedence over operating system defaults.

Respecting explicit user choices creates a more predictable user experience.

### Why isn't CSS-only theming enough?

CSS media queries such as:

```
prefers-color-scheme
```

can follow operating system preferences but cannot permanently store user selections.

JavaScript persistence using LocalStorage enables user preferences to remain consistent across future visits.

---

# Accessibility Features

- Semantic HTML5 landmarks
- Skip Navigation Link
- ARIA labels
- Live Regions
- Focus Management
- Keyboard Navigation
- Screen Reader Support
- High Contrast Focus Indicators
- Accessible Forms
- Accessible Tables

---

# Performance Optimizations

- ES Modules
- Lazy Rendering
- DocumentFragment
- Debounced Search
- Event Delegation
- LocalStorage Caching
- CSS Custom Properties
- Compositor-friendly Animations

---

# Security Considerations

- No inline JavaScript
- Safe DOM rendering using createElement()
- Avoidance of XSS through textContent
- POST semantics for destructive actions
- LocalStorage namespacing
- Validation on multiple layers

---

# Future Improvements

- REST API integration
- Authentication and Authorization
- Server-side Pagination
- Export to CSV and PDF
- Unit Testing
- Progressive Web App (PWA)
- Offline Support
- Multi-language support

---

# How to Run

1. Clone or download the repository.

2. Open the project in Visual Studio Code.

3. Install the Live Server extension.

4. Right-click `index.html`.

5. Select **Open with Live Server**.

The application will be served over HTTP, allowing ES Modules and Fetch API requests to function correctly.

---

# Author

**Shashank Masih**

Developed as part of the **Amicus Fresher Development Program 2026** using modern HTML, CSS, and Vanilla JavaScript best practices.