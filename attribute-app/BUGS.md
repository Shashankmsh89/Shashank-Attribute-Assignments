# BUGS.md

This document records the deliberate bugs introduced during the three assignments, how they were reproduced, their root causes, how they were fixed, and the lessons learned.

---

# Assignment 1

## Bug A – `<div role="button">` instead of `<button>`

### Problem

A clickable `<div>` was used instead of a native `<button>`.

### Symptoms

- Keyboard focus was inconsistent.
- Space key did not activate the control.
- Additional JavaScript would be required to emulate native button behavior.

### Root Cause

A `<div>` is not an interactive element. Adding `role="button"` changes how assistive technologies announce it but does not provide native keyboard behavior.

### Reproduction

1. Replace a `<button>` with:

```html
<div role="button">Delete</div>
```

2. Press **Tab**.
3. Press **Space**.

### Fix

Replace the `<div>` with:

```html
<button type="button">Delete</button>
```

### Lesson Learned

Always use native HTML elements whenever possible. ARIA enhances semantics but should not replace built-in browser functionality.

---

## Bug B – Icon-only Delete Button

### Problem

The Delete button displayed only an icon.

### Symptoms

Screen readers announced:

```
Button
```

instead of

```
Delete
```

### Root Cause

The button had no accessible name.

### Fix

```html
<button aria-label="Delete">
    🗑
</button>
```

or

```html
<button>
    🗑
    <span class="sr-only">Delete</span>
</button>
```

### Lesson Learned

Every interactive element must have an accessible name.

---

## Bug C – Multiple `<h1>` Elements

### Problem

Two `<h1>` elements existed on the page.

### Root Cause

Heading hierarchy was incorrect.

### Fix

Keep one `<h1>`.

Convert the second heading into:

```html
<h2>
```

### Lesson Learned

Headings communicate document structure to assistive technologies.

---

## Bug D – Label Not Connected

### Problem

Clicking the label did not focus the input.

### Root Cause

Missing

```html
for=""
```

attribute.

### Fix

```html
<label for="attributeName">
```

```html
<input id="attributeName">
```

### Lesson Learned

Explicit label associations improve accessibility and usability.

---

# Assignment 2

## Bug A – Absolutely Positioned Toast

Problem

Toast appeared in an unexpected location.

Cause

No positioned ancestor existed.

Fix

```css
position: relative;
```

or

```css
position: fixed;
```

Lesson Learned

Absolutely positioned elements are positioned relative to their nearest positioned ancestor.

---

## Bug B – z-index Not Working

Problem

z-index had no effect.

Cause

The element remained

```css
position: static;
```

Fix

```css
position: relative;
```

Lesson Learned

z-index only affects positioned elements or stacking contexts.

---

## Bug C – Margin Collapse

Problem

Child margins escaped the parent container.

Fixes

- Parent padding
- Parent border
- display: flow-root

Preferred solution:

```css
display: flow-root;
```

Lesson Learned

Understanding block formatting contexts prevents unexpected layouts.

---

## Bug D – Flex Overflow

Problem

Long text overflowed the card.

Cause

```css
min-width:auto;
```

Fix

```css
min-width:0;
```

Lesson Learned

Flex items often require explicit shrinking.

---

# Assignment 3

## Bug A – var Closure

Problem

Expected:

```
0
1
2
```

Actual:

```
3
3
3
```

Cause

`var` has function scope.

Fix

Use

```javascript
let
```

Lesson Learned

Prefer block-scoped variables.

---

## Bug B – Incorrect `this`

Problem

`this` referred to the clicked element.

Fixes

- bind()
- Arrow functions

Lesson Learned

Understand how JavaScript binds context.

---

## Bug C – Missing JSON.parse()

Problem

Objects became strings.

Fix

```javascript
JSON.parse()
```

Lesson Learned

Always deserialize LocalStorage values.

---

## Bug D – Array Mutation

Problem

Original array changed unexpectedly.

Fix

```javascript
structuredClone()
```

Lesson Learned

Avoid mutating shared objects.

---

## Bug E – Event Listener Leak

Problem

Every modal opening added another listener.

Fix

Use

```javascript
AbortController
```

with

```javascript
signal
```

### Lesson Learned

Always clean up event listeners.

---

# DevTools Learning

Using the Sources panel made it possible to inspect:

- Function call stack
- Local variables
- Closure values
- Execution flow

Unlike `console.log()`, breakpoints allow inspection of application state before execution continues, making complex debugging significantly easier.