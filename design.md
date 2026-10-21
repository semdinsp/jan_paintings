# Jan Johnson Prints — Design Guide

Style reference for the jan-prints site (Phoenix app). Hand this to Claude Code as the source of truth for colour, type, layout and components.

Earlier versions: `design.oct13.md` (the site before the print-room redesign) and `design.oct15.md` (the print-room redesign, before the colour and homepage-tile changes below).

## 1. Direction

A museum-like print room where the prints carry the colour: warm paper, dark ink, generous margins. Colour comes from three places only:

- **Dusky pink** frames the page: a full-width band behind the header and the footer.
- **Antique gold** draws the lines: the rule under the menu bar and the outlines of form fields and filter buttons.
- **Rose** marks what you can click: links, buttons, the active menu item and focus rings.

The homepage is a set of large picture tiles, one per print category, with search below them.

## 2. Colour tokens

Defined as CSS custom properties in `assets/css/app.css` (light and dark), exposed to Tailwind as `bg-dusk`, `border-gold`, etc. Use only these.

| Token | Light | Dark | Use |
|---|---|---|---|
| `--paper` | `#FAF8F4` | `#1C1A17` | Page background, menu bar |
| `--paper-2` | `#F1EDE6` | `#262320` | Image mats, contact form panel |
| `--rule` | `#DDD6CB` | `#3D3832` | Hairlines, dividers |
| `--ink` | `#1F1D1A` | `#EDE8E0` | Headings, body text, text on dusk |
| `--ink-2` | `#5C5650` | `#B3ABA1` | Secondary text: dates, medium, captions, labels |
| `--rose` | `#A8436A` | `#D9809F` | Links, buttons, focus rings, active menu item |
| `--rose-2` | `#86324F` | `#E8A3BB` | Link/button hover and pressed |
| `--rose-tint` | `#F6E9EE` | `#3A2630` | Selected filter button background |
| `--dusk` | `#C2918D` | `#3B2B2D` | Header and footer background |
| `--gold` | `#A9851F` | `#C9A84C` | Menu bar bottom rule, form field and filter button outlines |
| `--sold` | `#5C5650` | `#B3ABA1` | "Sold" label (neutral, not red) |

Contrast (WCAG AA): `--ink` on `--paper` ≈ 16:1, `--ink-2` on `--paper` ≈ 7:1, `--rose` on `--paper` ≈ 5.3:1, white on `--rose` ≈ 5.6:1, `--ink` on `--dusk` ≈ 6:1.

Rules:
- On `--dusk`, all text and links are `--ink` (links keep their underline). Rose and `--ink-2` are too faint on the pink.
- Gold is a line colour only, never text or a fill. It meets 3:1 on `--paper` (≈3.3:1), the minimum for outlines of fields and buttons; don't lighten it below that. Fields also have a visible label or placeholder, and turn ink with a rose ring when focused.
- Rose appears only on interactive elements.
- No gradients. No tinted backgrounds other than `--paper-2` and `--dusk`.

## 3. Typography

| Role | Font | Size / line-height | Weight |
|---|---|---|---|
| H1 (page title) | EB Garamond | 36px / 1.2 (mobile 28px) | 400 |
| Print title on its detail page | EB Garamond | 32px / 1.2 (mobile 24px) | 400 |
| H2 (section heads) | EB Garamond | 26px / 1.25 | 400 |
| Tile label (homepage) | EB Garamond | 32px / 1.25, white | 400 |
| Artist line (`BEHAM, Hans Sebald (1500–1550)`) | Source Sans 3 | 13px / 1.4 (14px on the print detail page), uppercase, letter-spacing 0.06em | 600 |
| Body | Source Sans 3 | 17px / 1.6 | 400 |
| Small / captions / metadata | Source Sans 3 | 14px / 1.5 | 400 |
| Menu items | Source Sans 3 | 15px, letter-spacing 0.02em | 500 |
| Eyebrow ("Search the stock", definition-list labels) | Source Sans 3 | 13px uppercase, letter-spacing 0.12em, `--ink-2` | 600 |

The `.type-eyebrow` class sets its own font family, so an eyebrow stays sans even when it is a heading element.

Load from Google Fonts: `EB Garamond:ital,wght@0,400;0,500;1,400` and `Source Sans 3:ital,wght@0,400;0,500;0,600;1,400` (the italic is for additional notes).
Use `text-wrap: pretty` on paragraphs and `text-wrap: balance` on headings.

## 4. Layout

- Content max-width **1200px**, side padding 24px (mobile 16px). Header and footer bands are full-bleed; their contents sit in the 1200px container.
- Reading text max-width **68ch**.
- Spacing scale (px): 4, 8, 12, 16, 24, 32, 48, 64, 96. Sections separated by 64px desktop / 48px mobile.
- Corners: square (radius 0) for images and tiles; 2px radius on buttons and inputs.
- No drop shadows. Use `--rule` hairlines for separation.
- Breakpoints: phone < 640px (`sm`), tablet 640–1023px (`sm`/`md`), desktop ≥ 1024px (`lg`). Check every change at 375px, 768px and 1280px.

## 5. Components

### Header
- Full-width `--dusk` band, 20px vertical padding.
- Logo left: `jan-johnson-logo-ink.png` (transparent ink, inverted in dark mode). Height 64px phone, 80px tablet, 120px from `md`. A 2px `--ink` rule sits directly under it, inset to the width of the lettering (not the image's transparent margins).
- Beham triton engraving (`beham-triton.jpg`) right-aligned, the same height as the logo (64px phone, 80px `sm`, 120px `md`). On phones it shrinks to fit the space beside the logo.
- Admin and account links sit between logo and triton, in `--ink`.
- No phone number in the header; it is in the contact section of the About page and in the footer.

### Menu bar
- Sits inside the 1200px container (not full-bleed), background `--paper`, sticky at the top on scroll.
- A 3px `--gold` rule along the bottom only (no top rule). Height 48px.
- Items: `--ink`, 15px/500, 28px gap; full bar height as hit area. Hover: text `--rose`.
- Active page: text `--rose`, weight 600, 2px `--rose` bottom border.
- Icon item (Home): always `--rose` (hover `--rose-2`), 20px, with the label as tooltip and screen-reader text; the rose underline marks the current page.
- Order: a home icon (`hero-home`), then Old Master Prints · Modern Prints · Canadian Prints on the left; About Us · Contact Us right-aligned (Contact Us goes to `/about#contact`, the contact details and form on the About page, which are also linked from print enquiry buttons and the "ask us" note on listings).
- Search: from `lg` (1024px), a 240px search box (36px tall, gold field border, "Artist or title" placeholder, magnifier submit button) sits right-aligned before About Us and Contact Us; Enter opens the matches on /prints. On tablets (768–1023px) there is no room for the box, so a magnifier icon links to /prints and its search box instead.
- Mobile (< 768px): "Menu" + hamburger on the left, the home icon at the right end of the bar; the menu opens a `--paper` drawer with the search box at the top, then stacked 48px rows separated by `--rule` hairlines, active row in rose.

### Links
- Inline links: `--rose`, underline with `text-underline-offset: 3px`, `text-decoration-thickness: 1px`. Hover: `--rose-2`, thickness 2px.
- "More" links ("← Old Master Prints"): `--rose`, 15px/600, no underline by default, underline on hover. Arrow is a text character.
- On `--dusk`, links are `--ink` with the same underline.

### Buttons
- **Primary** ("Enquire about this print", "Send message"): background `--rose`, white text, 15px/600, padding 12px 20px, radius 2px. Hover `--rose-2`.
- **Secondary** ("More by this artist" on a print page, under the enquiry button; opens /prints searched by the artist's surname and first given name): transparent, 1px `--rose` border, `--rose` text. Hover: `--rose-tint` background.
- Focus (all interactive): 2px `--rose` outline, 2px offset.
- Minimum hit area 44px tall.

### Form fields and search
- 2px `--gold` border, `--paper` background, 16px text, 44px tall, placeholder in `--ink-2`.
- Focus: border `--ink` plus the 2px rose ring. For a daisyUI `.input` wrapper (the search box), the ring is drawn on the wrapper and the inner `<input>` has no outline, so there is one complete ring.
- Search: "Search" button attached on the right, styled like a selected filter button (2px `--rose` border, `--rose-tint` background, `--rose` text, weight 600; hover `--rose-2`), so it matches the filters beneath it in both light and dark mode. As you type on the homepage, up to six matches drop down below the box; Enter opens the full results on /prints.

### Filter buttons (listing pages)
- There are no category buttons on the listing pages; the menu bar links to each category. There is no All Prints menu item (desktop or phone drawer); the /prints page remains, reached through search and the More by this artist button.
- Filter buttons (the nationality filter below) are 44px tall, 2px `--gold` border, `--ink` text; 12px side padding on phones, 16px from `sm`.
- Hover: border and text `--rose`.
- Selected: `--rose` border, `--rose-tint` background, `--rose` text, weight 600.

### Search box (listing pages)
- Only All Prints (/prints) has a search box under the heading, since the menu search and the More by this artist button open there. The category pages (Old Master, Modern, Canadian) have none.

### Nationality filter (listing pages)
- Under the search box: one button per nationality (Dutch/Flemish · Italian · German · French · British · Canadian · Other) in the filter button style, with no label in front: the country names say what they are, and screen readers hear "Filter by nationality" from the group. On phones the row scrolls sideways.
- Only nationalities that have prints in the current category and search are offered; the row is hidden when there would be just one (e.g. Canadian Prints). A selected nationality always stays visible so it can be cleared.
- Clicking one shows only that nationality, selected in rose; clicking it again shows all. The choice is kept in the URL (`?nationality=french`) and through searches; the menu bar's category links start fresh.
- Nationality is set per print in the admin form; `priv/repo/seeds/print_nationalities.json` holds the drafted value for each artist, loaded by `JanPaintings.Catalog.Seed.load_nationalities/1`.
- There is no sort control. `price_amount`, `price_currency`, `height_mm` and `width_mm` are still worked out from the price and size text on save, and the admin form shows what each reads as.

### Homepage
- No hero. A visually hidden H1 ("Jan Johnson, Old Master, Modern and Canadian prints for collectors and museums") keeps the page heading for search engines and screen readers.
- **Tiles**: three large picture links, one per print category, in this order (About has no tile; it is in the menu bar):

  | Tile | Links to | Image |
  |---|---|---|
  | Old Master Prints | /prints/old-masters | Dürer, *St George Slaying the Dragon* |
  | Modern Prints | /prints/modern | Chahine, *Invitation après la parade* (`chahine-edgar-invitation-tile.jpg`, a copy with the paper margin cropped off the top and sides) |
  | Canadian Prints | /prints/canadian | Hornyansky, *Anxiety, People on the Shore* |

  - Layout: centred flex-wrap, 24px gap. Three in a row from `sm`, one per row on phones.
  - Shape: 4:5 portrait from `sm`; 3:2 landscape on phones so the stack stays short.
  - Image fills the tile (`object-fit: cover`), with a per-tile `object-position` so faces and key details stay in frame. A tile can set a different position for the landscape phone crop (St George uses `object-[50%_10%] sm:object-center` so his head shows on phones). This is the one place a print may be cropped.
  - A 35% black wash over the image (20% on hover), with the label centred in white EB Garamond 32px and a soft text shadow.
  - Hover: the image scales to 1.03 over 500ms. This is the one hover zoom on the site.
  - Tile settings (label, path, image, position) live in `PageController.home_tiles/0`.
- **Search**: below the tiles, centred, max-width 512px, under a "Search the stock" eyebrow.
- "From the stock" is not shown, but is kept as the `from_the_stock/1` component in `PageHTML`; its doc has the one line needed to restore it.

### Print grid (listing pages)
- CSS grid `repeat(auto-fill, minmax(220px, 1fr))`, gap 32px horizontal / 48px vertical.
- Phones (< 640px): exactly two columns, gap 16px / 32px.
- Image on a `--paper-2` mat, fixed 4:5 box, `object-fit: contain`, 16px padding, so prints of different shapes align.
- Below the image: artist line, title (EB Garamond 18px, max 3 lines), medium + date in `--ink-2` 14px.
- Hover: title gets a rose underline. No image zoom.
- **Sold**: small uppercase "Sold" in `--sold` above the artist line; image at 85% opacity. No red, no banners.

### Print detail page
- Back link ("← Old Master Prints") above, in rose "more" style. It returns to this print's place in the category list: each card in a list has the id `print-<slug>` (with an 80px scroll margin to clear the sticky menu bar), and the link goes to `/prints/<category>#print-<slug>` with a full page load, so the browser scrolls to the card and focuses it (the rose focus ring marks where you were).
- Two columns desktop: image 7/12 on a `--paper-2` mat, details 5/12. Stacked on mobile.
- When a print has a larger image or extra views, a small secondary button "View larger" with a `hero-magnifying-glass-plus` icon sits under the image, right-aligned, and the image itself links to the larger view (zoom-in cursor). Both open it in a full-screen view on `--paper` (a native `<dialog>`, not a new tab, so it works on phones): the image as large as fits, with a primary "Close" button (`hero-x-mark`) at the top right. Esc or a tap beside the image also closes it, and the page behind doesn't scroll. Both follow the selected gallery view. Without JS the links open the image itself.
- Details: artist line, H1 title, medium/date, definition list (eyebrow labels, `--rule` hairlines between rows), price 20px/600, primary Enquire button.
- Additional notes (commentary that was set in italics on the original site), when present, each paragraph in Source Sans italic, `--ink-2`. From `md` (768px, the two-column layout) they sit under the images with no label, 24px below the image (or gallery). On phones they are instead a row of the definition list labelled "Additional notes", straight after Condition (so before Provenance, Watermark and Price).

### About page
- Text column (68ch). Jan's portrait (`images/jan-johnson.jpg`) on a `--paper-2` mat with "Jan Johnson" below: beside the text from `lg` (1024px); below the text on phones and tablets, at most 320px wide.
- Text (in the gallery's own words, "we"): founding and history; the stock; focused stock lists and the mailing list (links to email and the contact form); auction and appraisal services; print fairs and IFPDA.
- Museum clients: a full-width section under the text and portrait (`--rule` hairline above), H2 "Museum clients", a one-line `--ink-2` intro, then the 43 museums in alphabetical order, 15px, one column on phones, two from `sm`, three from `lg`.
- Contact section below: details on the left, the "Send a message" form on a `--paper-2` panel on the right (stacked on mobile).
- Mailing list: a second `--paper-2` panel under "Send a message" (right column, 32px gap), `id="mailing-list"` (linked from the text above), styled like it: H2 "Join our mailing list", a one-line meta note, then Email and Name (optional) side by side from `sm`, Interests (optional) below, and a primary "Join the mailing list" button, with the same hidden spam trap as the contact form. Signups go to the `mailing_list_subscribers` table, one row per email (lowercased); signing up again keeps the first entry. Success redirects back to `#mailing-list` with a thank-you flash.

### Footer
- Full-width `--dusk` band, 48px vertical padding, `--ink` text, 15px.
- Columns: business name + address; email and phone links, then a "Contact us" link to the form on the About page; a log-in icon (`hero-arrow-right-end-on-rectangle`, arrow pointing in, "Log in" as its title and screen-reader text) and the theme toggle. One column on phones, two on tablets (the third group wraps below), three from `lg` with the third right-aligned.

### Favicon
- The triton's head from the header engraving in a round medallion on a `--dusk` square.
- Files: `priv/static/favicon.ico` (16/32/48), `images/favicon-192.png`, `images/apple-touch-icon.png` (180). Masters: `images/Beham single Triton..JPG` and `images/logo, black on white.png`.

## 6. Imagery
- Prints are never cropped, except on the homepage tiles: everywhere else `object-fit: contain` on a mat.
- Provide `alt` as `ARTIST, Name, Title`. Tile images are decorative (`alt=""`) because the label names the link.
- Lazy-load grid and tile images; serve a medium size for grids and a large size on detail pages.

## 7. Don'ts
- No rose on non-interactive text or decoration, and no rose text on `--dusk`.
- No gold text or gold fills.
- No shadows, gradients or rounded image corners.
- No hover zoom except the homepage tiles.
- No more than the two font families above.
