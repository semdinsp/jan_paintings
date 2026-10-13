# To do

## 2026-10-14: Validate SEO on the deployed site

Once `claude/seo` and `claude/print-references` are merged and deployed, and
the catalogue seed has been run in production
(`fly ssh console -a jan-prints -C '/app/bin/jan_paintings eval "JanPaintings.Release.seed()"'`):

- [ ] Google Rich Results Test (https://search.google.com/test/rich-results): paste a
      print URL. It should detect Product with an offer. Run it on a sold print too
      and check it reads "SoldOut".
- [ ] schema.org validator (https://validator.schema.org): paste the same URL to check
      the VisualArtwork, ArtGallery and CollectionPage data.
- [ ] Submit `https://<your host>/sitemap.xml` in Google Search Console.
- [ ] When you add a custom domain, set both `PHX_HOST` and `CANONICAL_HOST` to it
      (`fly secrets set PHX_HOST=... CANONICAL_HOST=...`).
