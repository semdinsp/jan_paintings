# SEO

Notes and checklist for search-engine setup on https://janjohnsonprints.com
(Fly app `jan-prints`).

## Checklist

- [x] Custom domain live: `PHX_HOST` and `CANONICAL_HOST` set to
      `janjohnsonprints.com`; `www` and `jan-prints.fly.dev` redirect (301) to it.
- [x] Site added to Google Search Console (see below).
- [x] Sitemap submitted in Search Console: `https://janjohnsonprints.com/sitemap.xml`.
- [ ] Optional: URL Inspection on the home page, then **Request indexing**.
- [ ] Google Rich Results Test (https://search.google.com/test/rich-results): paste a
      print URL. It should detect Product with an offer. Run it on a sold print too
      and check it reads "SoldOut".
- [ ] schema.org validator (https://validator.schema.org): paste the same URL to check
      the VisualArtwork, ArtGallery and CollectionPage data.

## Google Search Console

Search Console is at https://search.google.com/search-console. Sign in with the
Google account you want to manage the site from.

### Setting it up

1. Click **Add property**. Google offers two types:
   - **Domain (recommended):** enter `janjohnsonprints.com`. It covers the whole
     domain, including `www` and both http and https. Google gives you a TXT record
     (`google-site-verification=…`). Add it in cPanel's Zone Editor, the same place
     as the mail records, then click **Verify**. It can take a few minutes to an
     hour to show up.
   - **URL prefix:** enter `https://janjohnsonprints.com/`. One way to verify is a
     `<meta name="google-site-verification" …>` tag in the site's page header. If
     you choose this, the tag goes in the root layout on a branch.
2. Once it's verified, go to **Sitemaps** in the left menu, enter `sitemap.xml` and
   click **Submit**.
3. Optionally, use **URL Inspection** on the home page and click **Request indexing**
   to speed things up.

After that, Search Console shows which pages Google has indexed and which searches
bring visitors in, and it flags any errors.

### Checking the DNS record

The local network intercepts plain DNS lookups (`dig`, port 53) and can return stale
answers, so confirm the TXT record over DNS-over-HTTPS instead:

```sh
curl -s -H 'accept: application/dns-json' \
  'https://cloudflare-dns.com/dns-query?name=janjohnsonprints.com&type=TXT'
```
