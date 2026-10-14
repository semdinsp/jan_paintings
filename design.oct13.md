# Jan Johnson Prints: current site snapshot (13 October 2026)

This records the live site at https://jan-prints.fly.dev/ as it stood on 13 Oct 2026, before the redesign described in `design.md`. Keep it as a reference for rolling back.

**What it covers:** I could read the page structure, content and links, but not the stylesheet. The colours below come from your description of the current design. Before relying on exact values, copy the actual hex values and fonts from `assets/css/app.css` into the "Visual styling" section.

## 1. Visual styling (as built)

| Element | Current treatment |
|---|---|
| Header | Pinkish background, logo image at left |
| Menu bar | Green |
| Footer | Pinkish background |
| Links and "More…" links | Pink |
| Buttons | Pink |
| Exact hex values / fonts | See below (from `assets/css/app.css` at commit `8886996`) |

Exact values at commit `8886996` (the last commit before the redesign; `git checkout 8886996 -- assets lib priv/static/images` restores the old look):

| Token | Value |
|---|---|
| Header / footer (daisyUI `primary`, "oxblood") | `oklch(39% 0.07 5)` ≈ `#643440` |
| Menu bar (daisyUI `secondary`, "sage") | `oklch(76% 0.035 125)` ≈ `#b2baa6`, text `oklch(25% 0.02 125)` |
| Links, "More…", buttons (`accent` = `primary`) | `oklch(39% 0.07 5)` |
| Page background | `#b2baa6` sage with SVG paper-noise texture and radial shading |
| Content sheet | `oklch(98.5% 0.006 85)` cream, with a drop shadow on ≥640px |
| Print mounts | cream lightened 30% with an inset 1px bevel and soft shadow |
| Header art | category banner print detail at right, faded in from the left |
| Logo | white `jan-johnson-logo.png` on the oxblood header |
| Body font | Tinos (Times-metric) |
| Headings (h1, h2) | Libre Baskerville |
| Radii | fields/buttons 0.25rem, boxes 0.5rem |

Logo asset: `/images/jan-johnson-logo-2e40937b417e3e931a1e716acd31a406.png` (alt "Jan Johnson, Old Master & Modern Prints Inc.").

## 2. Global layout

**Header:** logo linking to `/`.

**Menu bar** (in this order):
- All Prints → `/prints`
- Old Master Prints → `/prints/old-masters`
- Modern Prints → `/prints/modern`
- Canadian Prints → `/prints/canadian`
- About → `/about`
- Contact → `/about#contact`

There is a visual gap between "All Prints" and the category links, and before About/Contact.

**Footer** (on every page):
- Jan Johnson, Old Master & Modern Prints, Inc.
- 189 rue Saint-Pierre, Chambly, QC, Canada J3L 1L8
- jan@janjohnsonprints.com (mailto)
- Phone 450.658.2752 · Cell 514.608.6959 (tel links)
- Log in → `/users/log-in`

## 3. Pages

### Home `/`
1. Eyebrow: "Fine prints since 1979"
2. H1: "Old Master, Modern and Canadian prints for collectors and museums."
3. Intro paragraph
4. Search field ("Search by artist or title") + Search button
5. Buttons: "Browse the stock" → `/prints`, "Get in touch" → `/about#contact`
6. Featured print (image link): PETHER, William, *A Farrier's Shop, after Joseph Wright of Derby*
7. About block: portrait `/images/catalogue/jan-green-jacket.jpg`, label "About the gallery", H2 "Jan Johnson", paragraph, link "More about the gallery →"
8. Three category cards (title + one-line description, whole card links):
   - Old Master Prints: "Engravings, etchings, woodcuts and mezzotints from the fifteenth to the eighteenth century."
   - Modern Prints: "European printmaking of the nineteenth and early twentieth centuries."
   - Canadian Prints: "Etchings, woodcuts and linocuts by Canadian printmakers of the early twentieth century."
9. H2 "From the stock": grid of 6 print cards

### All Prints `/prints` (and the category pages)
1. H1 "All Prints" + intro line
2. Search field + Search button
3. Filter tabs: All · Old Masters · Modern · Canadian (links to the category URLs)
4. Count line: "180 prints shown."
5. Grid of print cards, sorted by artist surname within each category (Old Masters, then Modern, then Canadian)

Category URLs: `/prints/old-masters`, `/prints/modern`, `/prints/canadian`.

### Print detail `/prints/{category}/{slug}`
1. Back link: "← Old Master Prints" (category name)
2. Large image (`/images/catalogue/{slug}-lg.jpg`)
3. Artist line with dates: "BEHAM, Hans Sebald (1500–1550)"
4. H1 title
5. Link "More by this artist (n)" → `#more-by-artist`
6. Description paragraph
7. Field list: Size, Condition, Price (e.g. "$4,000 USD")
8. Primary button "Enquire about this print" → `/about?print={slug}#contact`
9. H2 "More by this artist" + print cards

### About `/about`
1. H1 "About" + four paragraphs (history, stock, services, fairs/museum clients)
2. H2 "Contact" (anchor `#contact`) + intro paragraph (prices in USD, Canadian prints in CAD)
3. Contact list: Email, Phone, Cell, Address, Visits ("By appointment")
4. H2 "Send a message" + "We'll reply by email, usually within a few days."
5. Form fields: Name, Email, Phone (optional), Subject (optional), Message, a hidden honeypot field ("Leave this empty"), and a "Send message" button. Prefilled when you arrive via `?print={slug}`.

### Log in `/users/log-in`
Admin login, linked from the footer.

## 4. Components

**Print card** (home, listings, "More by this artist")
- The whole card is a link.
- Image with alt text "ARTIST, Name, Title".
- Artist line in the format "SURNAME, Forenames".
- Title.
- Medium and date (optional), e.g. "Engraving, 1548".
- Status badge before the artist, when it applies: **sold** or **reserved**.

**Search:** single text field with a Search button, on the home and listing pages.

**Category filter tabs:** All / Old Masters / Modern / Canadian on the listing pages.

## 5. Content conventions
- Artist names: surname in capitals, then a comma, then forenames ("TIEPOLO, Giandomenico").
- Titles stay in their original language, with a translation in parentheses where given.
- Dates are free text ("ca. 1545", "before 1774", "1593-8").
- Prices are in USD; Canadian prints are priced in CAD.
- Status values: available (no badge), sold, reserved.

## 6. Site metadata
- Page title format: "{Page} · Jan Johnson Old Master & Modern Prints"
- Each page has a meta description, Open Graph and Twitter card tags (summary_large_image), using a print image as og:image.
- Canonical URLs are set.
