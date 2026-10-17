# Jan Johnson Prints — Design Guide

Style reference for the jan-prints site (Phoenix app). Hand this to Claude Code as the source of truth for colour, type, layout and components.

## 1. Direction

A quiet, museum-like setting where the prints carry the colour. The site should feel like a well-kept print room: warm paper, dark ink, generous margins, a navigation bar drawn with hairlines, and a single rose accent for anything clickable.

Changes from the current build:

- **Header**: remove the pink background. Logo sits on the paper background.
- **Menu bar**: no coloured band. Paper background between a dark top rule and a light bottom hairline; the active page is rose.
- **Footer**: remove the pink background. Use a soft warm-grey band with ink text, separated by a hairline.
- **Pink**: kept, but used only for links, "More…" links and buttons, so it reliably means "click here".

> If the current CSS already has specific pink/green hex values that Jan likes, keep those hues and adjust lightness to hit the contrast targets below.

## 2. Colour tokens

Define these as CSS custom properties in `app.css` (or Tailwind theme `extend.colors`) and use only these.

| Token | Hex | Use |
|---|---|---|
| `--paper` | `#FAF8F4` | Page background, header background |
| `--paper-2` | `#F1EDE6` | Footer, category cards, image mats |
| `--rule` | `#DDD6CB` | Hairlines, borders, input borders |
| `--ink` | `#1F1D1A` | Headings, body text |
| `--ink-2` | `#5C5650` | Secondary text: dates, medium, captions, labels |
| `--rose` | `#A8436A` | Links, buttons, focus rings |
| `--rose-2` | `#86324F` | Link/button hover and pressed |
| `--rose-tint` | `#F6E9EE` | Rare: selected filter chip background |
| `--sold` | `#5C5650` | "Sold" label (neutral, not red) |

Contrast (WCAG AA): `--ink` on `--paper` ≈ 16:1, `--ink-2` on `--paper` ≈ 7:1, `--rose` on `--paper` ≈ 5.3:1, white on `--rose` ≈ 5.6:1.

Rules:
- No gradients, no tinted section backgrounds other than `--paper-2`.
- Rose appears only on interactive elements.

## 3. Typography

| Role | Font | Size / line-height | Weight |
|---|---|---|---|
| Display (home H1) | EB Garamond | 44px / 1.15 (mobile 32px) | 400 |
| H1 (print title, page title) | EB Garamond | 36px / 1.2 (mobile 28px) | 400 |
| H2 (section heads) | EB Garamond | 26px / 1.25 | 400 |
| Artist line (`BEHAM, Hans Sebald (1500–1550)`) | Source Sans 3 | 13px / 1.4, uppercase, letter-spacing 0.06em | 600 |
| Body | Source Sans 3 | 17px / 1.6 | 400 |
| Small / captions / metadata | Source Sans 3 | 14px / 1.5 | 400 |
| Menu items | Source Sans 3 | 15px, letter-spacing 0.02em | 500 |
| Eyebrow ("Fine prints since 1979") | Source Sans 3 | 13px uppercase, letter-spacing 0.12em, `--ink-2` | 600 |

Load from Google Fonts: `EB Garamond:ital,wght@0,400;0,500;1,400` and `Source Sans 3:wght@400;500;600`.
Use `text-wrap: pretty` on paragraphs and `text-wrap: balance` on headings. Titles in other languages (e.g. German titles) render in italic EB Garamond when quoted inline.

## 4. Layout

- Content max-width **1200px**, side padding 24px (mobile 16px).
- Reading text max-width **68ch**.
- Spacing scale (px): 4, 8, 12, 16, 24, 32, 48, 64, 96. Sections separated by 64px desktop / 48px mobile.
- Corners: square (radius 0) for images and cards; 2px radius on buttons and inputs.
- No drop shadows. Use `--rule` hairlines for separation.

## 5. Components

### Header
- Background `--paper`. Logo left, height 56px desktop / 40px mobile, vertical padding 20px.
- Optional right side: search icon or compact search field, phone number in `--ink-2` small.
- No bottom border; the menu bar's top rule provides the edge.

### Menu bar
- Sits inside the 1200px content container (not full-bleed), background `--paper`.
- Top border 1px `--ink`; bottom border 1px `--rule`. Height 48px.
- Items: `--ink`, 15px/500, no horizontal padding, 28px gap between items; full bar height as hit area.
- Hover: text `--rose`.
- Active page: text `--rose`, weight 600, 2px `--rose` bottom border (sitting on the bar's bottom hairline).
- Order: All Prints · Old Master Prints · Modern Prints · Canadian Prints on the left; About · Contact right-aligned on desktop.
- Mobile (< 768px): bar shows "Menu" + hamburger on the left; opens a `--paper` drawer with stacked 48px rows separated by `--rule` hairlines, active row in rose.
- Optional: sticky on scroll (`position: sticky; top: 0`) with `--paper` background so content doesn't show through.

### Links
- Inline links: `--rose`, underline with `text-underline-offset: 3px`, `text-decoration-thickness: 1px`. Hover: `--rose-2`, thickness 2px.
- "More" links (e.g. "More about the gallery →", "More by this artist (1)", "← Old Master Prints"): `--rose`, 15px/600, no underline by default, underline on hover. Arrow is a text character, not an icon.

### Buttons
- **Primary** ("Enquire about this print", "Browse the stock", "Search"): background `--rose`, text white, 15px/600, padding 12px 20px, radius 2px. Hover `--rose-2`.
- **Secondary** ("Get in touch"): transparent, 1px `--rose` border, `--rose` text. Hover: `--rose-tint` background.
- Focus (all interactive): 2px `--rose` outline, 2px offset.
- Minimum hit area 44px tall.

### Search field
- 1px `--rule` border, `--paper` background, 16px text, height 44px, placeholder in `--ink-2`. Focus border `--ink`, plus focus ring. Primary button attached on the right.

### Hero (home)
- Two columns desktop (text 5/12, featured print 7/12), stacked on mobile.
- Eyebrow, display H1, body paragraph in `--ink-2`, search, then primary + secondary buttons in a row (gap 12px).
- Featured print on a `--paper-2` mat with 32px padding; caption below in small text: artist uppercase line, title in EB Garamond italic.

### Category cards (Old Master / Modern / Canadian)
- Three-column grid (1 column mobile), gap 24px.
- Card: `--paper-2` background, 24px padding, square corners. Title in EB Garamond 22px `--ink`, description 15px `--ink-2`, then "Browse →" in rose.
- Entire card is the link; hover shows the rose "Browse →" underlined and title colour unchanged.

### Print grid ("From the stock", listing pages)
- CSS grid `repeat(auto-fill, minmax(220px, 1fr))`, gap 32px horizontal / 48px vertical.
- Image on `--paper-2` mat, fixed aspect box 4:5 with the print `object-fit: contain` and 16px padding, so prints of different shapes align.
- Below image (8px gap): artist line (uppercase small), title (EB Garamond 18px, max 3 lines with clamp), medium + date in `--ink-2` 14px.
- Hover: title gets rose underline. No image zoom.
- **Sold**: small uppercase label "Sold" in `--sold` above the artist line; image at 85% opacity. Don't use red or diagonal banners.

### Print detail page
- Back link ("← Old Master Prints") above, in rose "more" style.
- Two columns desktop: image 7/12 on `--paper-2` mat, details 5/12. Stacked mobile.
- Details order: artist line, H1 title, medium/date, description paragraph, definition list, price, primary Enquire button, "More by this artist" link.
- Definition list (Size, Condition, Price): label in uppercase small `--ink-2`, value in body text; rows separated by `--rule` hairlines.
- Price: 20px/600 `--ink`.
- "More by this artist" section below uses the print grid.

### About block (home)
- Two columns: portrait image left (4/12), text right. Eyebrow "About the gallery", H2, body, rose "more" link.

### Footer
- Background `--paper-2`, 1px `--rule` top border, padding 48px 0.
- Three columns desktop (stacked mobile): business name + address; email and phone links (rose); small "Log in" link in `--ink-2` right-aligned.
- Body text `--ink`, 15px. No coloured background.

## 6. Imagery
- Prints never cropped: always `object-fit: contain` on a mat.
- Provide `alt` as `ARTIST, Name, Title`.
- Lazy-load grid images; serve a medium size for grids and a large size on detail pages.

## 7. Don'ts
- No coloured header or footer backgrounds.
- No rose on non-interactive text or decoration.
- No coloured menu bar.
- No shadows, gradients, rounded image corners or hover zoom.
- No more than the two font families above.

## 8. Implementation notes for Claude Code
1. Add the colour tokens to `assets/css/app.css` under `:root` (or Tailwind theme) and replace existing hard-coded pinks/greens. Remove the green entirely.
2. Update the root layout / `core_components.ex` header, nav and footer per §5.
3. Update link and button components to use rose tokens; make sure every link, including "More…" ones, uses the same styles.
4. Apply the print-grid card spec to the home "From the stock" section, category listings and "More by this artist".
5. Check all pages at 375px, 768px and 1280px widths.
