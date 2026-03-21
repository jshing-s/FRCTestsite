# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static website for FRC (FIRST Robotics Competition) Teams 3020 and 5805 at Santa Margarita Catholic High School. No build tools, no package manager, no dependencies — just HTML files opened directly in a browser.

## Development

Open `RoboticsSite.html` or `gallery.html` directly in a browser. There is no build step, dev server, or test suite.

## File Structure

- `RoboticsSite.html` — Main site (single-page with anchor sections)
- `gallery.html` — Photo gallery page (separate page, links back to main)
- `RoboticsSite_backup.html` — Backup copy; do not edit
- `PortHuenemePhotos/` — Raw competition photos (not yet wired into the gallery)
- `images/` — Where gallery photos should live (create if absent)

## Architecture

Both HTML files are fully self-contained: all CSS lives in a `<style>` block in `<head>`, and all JS lives in a `<script>` block at the bottom of `<body>`. There are no external JS dependencies or separate CSS files.

### Main site sections (by anchor ID)

`#home` → `#about` → `#teams` → `#achievements` → `#sponsors` → `#what-we-do`, plus a `#contact` footer.

### Design system (CSS custom properties in `:root`)

Both pages share the same variable set — edit `:root` to rebrand:

| Variable | Value | Role |
|---|---|---|
| `--accent-main` | `#1e9bd8` | Sky blue — primary accent, Team 3020 |
| `--navy` / `--accent-team-b` | `#21409a` | Deep navy — Team 5805 |
| `--accent-gold` | `#bca465` | Gold — secondary highlights |
| `--font-display` | Chakra Petch | Headings and labels |
| `--font-body` | IBM Plex Sans | Body text |

### Gallery photo data (`gallery.html`)

Photos are declared as a plain JS array near the top of the `<script>` block:

```js
const photos = [
  { src: "images/filename.jpg", caption: "Short description", tag: "3020" },
  // tag: "3020" | "5805" | "both" | "event"
];
```

Add an entry here for each image. Files go in `images/` (relative to the HTML file). The filter bar, masonry grid, and lightbox are all driven from this array — no other changes needed.

### JS patterns used

- Intersection Observer for scroll-reveal animations (`RoboticsSite.html`)
- Animated stat counters triggered on viewport entry
- Canvas particle effect in the hero section
- Cursor glow effect tracking `mousemove`
- Lightbox with keyboard navigation (Arrow keys, Escape)
