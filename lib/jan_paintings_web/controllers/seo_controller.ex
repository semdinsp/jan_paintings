defmodule JanPaintingsWeb.SEOController do
  @moduledoc """
  Files for crawlers: /sitemap.xml, /robots.txt and /llms.txt.

  They are generated so their URLs use the canonical host from the endpoint
  config, and so the sitemap follows the catalogue as prints are added.
  """
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog
  alias JanPaintingsWeb.SEO

  @doc """
  Lists the home, about, terms of sale, print list and category pages, and
  every print.
  Sold prints are included: their pages stay up as a record of the stock
  and still answer searches for the artist and title.
  """
  def sitemap(conn, _params) do
    prints = Catalog.list_prints()
    latest = prints |> Enum.map(& &1.updated_at) |> Enum.max(DateTime, fn -> nil end)

    pages =
      [
        {"/", latest},
        {"/about", nil},
        {"/contact", nil},
        {"/terms-of-sale", nil},
        {"/prints", latest}
      ] ++
        Enum.map(Catalog.categories(), fn category ->
          {"/prints/#{category.slug}",
           prints |> Enum.filter(&(&1.category == category.slug)) |> latest_update()}
        end) ++
        Enum.map(prints, &{SEO.print_path(&1), &1.updated_at})

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, sitemap_xml(pages))
  end

  defp latest_update(prints) do
    prints |> Enum.map(& &1.updated_at) |> Enum.max(DateTime, fn -> nil end)
  end

  defp sitemap_xml(pages) do
    urls =
      Enum.map(pages, fn {path, lastmod} ->
        [
          "  <url><loc>",
          xml_escape(SEO.url(path)),
          "</loc>",
          if(lastmod,
            do: ["<lastmod>", Date.to_iso8601(DateTime.to_date(lastmod)), "</lastmod>"],
            else: []
          ),
          "</url>\n"
        ]
      end)

    IO.iodata_to_binary([
      ~s(<?xml version="1.0" encoding="UTF-8"?>\n),
      ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n),
      urls,
      "</urlset>\n"
    ])
  end

  defp xml_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  def robots(conn, _params) do
    text(conn, """
    # Every crawler is welcome on the public pages.
    User-agent: *
    Allow: /
    Disallow: /admin/
    Disallow: /users/
    Disallow: /dev/

    Sitemap: #{SEO.url("/sitemap.xml")}
    """)
  end

  def llms(conn, _params) do
    categories =
      Enum.map_join(Catalog.categories(), "\n", fn category ->
        "- [#{category.name}](#{SEO.url("/prints/#{category.slug}")}): #{category.blurb}"
      end)

    conn
    |> put_resp_content_type("text/markdown")
    |> send_resp(200, """
    # Jan Johnson, Old Master & Modern Prints Inc.

    > A fine print dealer founded by Jan Johnson in London in 1979, after years in the print department of P & D Colnaghi. The gallery moved to Montreal in 1982 and is now in Chambly, Quebec, near Montreal, where the stock can be viewed by appointment. It supplies private collectors and major museums and is a founding member of the International Fine Print Dealers Association.

    ## Specialities

    - Old Master prints: engravings, etchings, woodcuts and mezzotints from the fifteenth to the eighteenth century.
    - Nineteenth- and early twentieth-century European prints.
    - Early twentieth-century Canadian printmaking.

    ## Browse

    - [All prints](#{SEO.url("/prints")})
    #{categories}
    - [About the gallery](#{SEO.url("/about")})
    - [Contact us](#{SEO.url("/contact")}): enquiries, viewings by appointment and the mailing list.
    - [Terms of sale](#{SEO.url("/terms-of-sale")}): authenticity guarantee, approval, shipping and payment.
    - [Sitemap](#{SEO.url("/sitemap.xml")}): every print page, with last-updated dates.

    Each print page lists the artist, title, medium and date, size, condition, provenance where known, price and availability, and carries schema.org JSON-LD.

    ## Contact

    - Email: jan@janjohnsonprints.com
    - Phone: +1 450 658 2752 · Cell: +1 514 608 6959
    - Address: 189 rue Saint-Pierre, Chambly, QC J3L 1L8, Canada
    - Visits by appointment. Enquiries: #{SEO.url("/contact")}
    """)
  end
end
