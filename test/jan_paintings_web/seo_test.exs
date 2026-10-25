defmodule JanPaintingsWeb.SEOTest do
  use JanPaintingsWeb.ConnCase

  alias JanPaintings.Catalog
  alias JanPaintingsWeb.SEO

  defp json_ld(html) do
    [_, json] = Regex.run(~r{<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>}s, html)
    Jason.decode!(json)
  end

  defp base, do: JanPaintingsWeb.Endpoint.url()

  describe "print pages" do
    test "have VisualArtwork/Product JSON-LD with an in-stock offer", %{conn: conn} do
      print = Catalog.get_print("beham-leda-and-the-swan")
      html = conn |> get(SEO.print_path(print)) |> html_response(200)
      data = json_ld(html)

      assert data["@type"] == ["VisualArtwork", "Product"]
      assert data["name"] == "Leda and the Swan"

      assert data["creator"] == %{
               "@type" => "Person",
               "name" => "Hans Sebald Beham",
               "birthDate" => "1500",
               "deathDate" => "1550"
             }

      assert data["dateCreated"] == "1548"
      assert data["artMedium"] == "Engraving"

      assert data["height"] == %{
               "@type" => "QuantitativeValue",
               "value" => 46,
               "unitCode" => "MMT"
             }

      assert data["width"]["value"] == 59
      assert data["image"] == base() <> print.image
      assert data["url"] == base() <> SEO.print_path(print)

      assert %{
               "@type" => "Offer",
               "price" => "4000",
               "priceCurrency" => "USD",
               "availability" => "https://schema.org/InStock",
               "seller" => %{"@type" => "ArtGallery"}
             } = data["offers"]
    end

    test "mark sold prints as sold out", %{conn: conn} do
      print = Enum.find(Catalog.list_prints(), &(&1.status == "sold"))
      data = conn |> get(SEO.print_path(print)) |> html_response(200) |> json_ld()

      assert data["offers"]["availability"] == "https://schema.org/SoldOut"
    end

    test "use an AggregateOffer when a print has several prices", %{conn: conn} do
      print =
        Catalog.get_print(
          "tissot-the-return-from-the-parable-of-the-prodigal-son-a-set-of-four-plus-title"
        )

      offers =
        conn |> get(SEO.print_path(print)) |> html_response(200) |> json_ld() |> Map.get("offers")

      assert %{"@type" => "AggregateOffer", "lowPrice" => "1200", "highPrice" => "2000"} = offers
    end

    test "have a descriptive title, description, canonical and Open Graph tags on the canonical host",
         %{conn: conn} do
      print = Catalog.get_print("beham-leda-and-the-swan")
      html = conn |> get(SEO.print_path(print) <> "?utm_source=x") |> html_response(200)
      canonical = base() <> SEO.print_path(print)

      assert html =~ "<title"

      assert html =~
               "Hans Sebald Beham, Leda and the Swan, Engraving, 1548 · Jan Johnson Old Master &amp; Modern Prints"

      assert html =~ ~s(rel="canonical" href="#{canonical}")
      assert html =~ ~s(property="og:url" content="#{canonical}")
      assert html =~ ~s(property="og:image" content="#{base()}#{print.image}")
      assert html =~ ~s(property="og:type" content="product")
      assert [_, description] = Regex.run(~r/name="description" content="([^"]*)"/, html)
      assert String.length(description) <= 155
    end

    test "show references and sheet size when present, but not the state", %{conn: conn} do
      print = Catalog.get_print("beham-leda-and-the-swan")

      {:ok, print} =
        Catalog.update_print(print, %{
          "catalogue_references" => "Hollstein 106",
          "state" => "Second state of two",
          "sheet_size" => "55 × 68mm"
        })

      html = conn |> get(SEO.print_path(print)) |> html_response(200)
      assert html =~ ~r{>Catalogue reference</dt>}
      assert html =~ "Hollstein 106"
      refute html =~ "Second state of two"
      assert html =~ "Sheet"
      assert html =~ "55 × 68mm"
      assert json_ld(html)["citation"] == "Hollstein 106"
    end

    test "show medium and date", %{conn: conn} do
      html = conn |> get("/prints/old-masters/beham-leda-and-the-swan") |> html_response(200)
      # The first row of the details, as well as in the title and JSON-LD.
      assert html =~ ~r{>Medium</dt>\s*<dd[^>]*>\s*Engraving, 1548\s*</dd>}
      assert json_ld(html)["artMedium"] == "Engraving"
    end

    test "escape </script> inside JSON-LD", %{conn: conn} do
      {:ok, print} =
        Catalog.create_print(%{
          "category" => "modern",
          "artist" => "TEST, Artist",
          "title" => "Trouble </script><script>alert(1)</script>",
          "image" => "/images/catalogue/beham-leda-lg.jpg"
        })

      html = conn |> get(SEO.print_path(print)) |> html_response(200)

      refute html =~ "<script>alert(1)"
      assert json_ld(html)["name"] == "Trouble </script><script>alert(1)</script>"
    end
  end

  test "home and about pages describe the gallery", %{conn: conn} do
    for path <- ["/", "/about"] do
      data = conn |> get(path) |> html_response(200) |> json_ld()

      assert data["@type"] == "ArtGallery"
      assert data["foundingDate"] == "1979"
      assert data["address"]["postalCode"] == "J3L 1L8"
      assert data["address"]["addressCountry"] == "CA"
      assert data["telephone"] =~ "450"
    end

    html = conn |> get("/about?print=beham-leda-and-the-swan") |> html_response(200)
    assert html =~ ~s(rel="canonical" href="#{base()}/about")
  end

  test "category pages list their prints in a CollectionPage", %{conn: conn} do
    html = conn |> get("/prints/canadian") |> html_response(200)
    data = json_ld(html)

    assert data["@type"] == "CollectionPage"
    assert data["mainEntity"]["numberOfItems"] == 37

    [first | _] = data["mainEntity"]["itemListElement"]
    assert first["position"] == 1
    assert String.starts_with?(first["url"], base() <> "/prints/canadian/")

    assert html =~ ~s(rel="canonical" href="#{base()}/prints/canadian")
    assert html =~ "Canadian Prints at Jan Johnson: 37 in stock."
  end

  describe "crawler files" do
    test "sitemap.xml lists the pages and every print, sold ones included", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")
      xml = response(conn, 200)

      assert response_content_type(conn, :xml) =~ "application/xml"
      assert xml =~ ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
      assert xml =~ "<loc>#{base()}/</loc>"
      assert xml =~ "<loc>#{base()}/prints/old-masters</loc>"
      assert xml =~ "<loc>#{base()}/terms-of-sale</loc>"
      assert xml =~ "<loc>#{base()}/prints/old-masters/beham-leda-and-the-swan</loc><lastmod>"

      sold = Enum.find(Catalog.list_prints(), &(&1.status == "sold"))
      assert xml =~ base() <> SEO.print_path(sold)
      assert length(Regex.scan(~r/<url>/, xml)) == 7 + length(Catalog.list_prints())
    end

    test "robots.txt allows crawlers and points at the sitemap", %{conn: conn} do
      text = conn |> get("/robots.txt") |> response(200)

      assert text =~ "User-agent: *\nAllow: /"
      assert text =~ "Sitemap: #{base()}/sitemap.xml"
    end

    test "llms.txt summarises the gallery in markdown", %{conn: conn} do
      conn = get(conn, "/llms.txt")
      text = response(conn, 200)

      assert response_content_type(conn, :markdown) =~ "text/markdown"
      assert text =~ "London in 1979"
      assert text =~ "#{base()}/prints/canadian"
      assert text =~ "#{base()}/sitemap.xml"
      assert text =~ "jan@janjohnsonprints.com"
      assert length(String.split(text, "\n")) < 60
    end
  end

  describe "canonical host redirect" do
    setup do
      on_exit(fn -> Application.delete_env(:jan_paintings, :canonical_host) end)
    end

    test "does nothing when no canonical host is configured", %{conn: conn} do
      Application.delete_env(:jan_paintings, :canonical_host)
      assert conn |> Map.put(:host, "jan-prints.fly.dev") |> get("/about") |> html_response(200)
    end

    test "301-redirects other hosts, keeping the path and query", %{conn: conn} do
      Application.put_env(:jan_paintings, :canonical_host, "janjohnsonprints.com")
      conn = conn |> Map.put(:host, "jan-prints.fly.dev") |> get("/prints?q=dore")

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["https://janjohnsonprints.com/prints?q=dore"]
    end

    test "leaves requests on the canonical host alone", %{conn: conn} do
      Application.put_env(:jan_paintings, :canonical_host, "janjohnsonprints.com")
      conn = conn |> Map.put(:host, "janjohnsonprints.com") |> get("/about")

      assert conn.status == 200
    end
  end

  describe "helpers" do
    test "artist_name/1 turns catalogue names around" do
      assert SEO.artist_name("BEHAM, Hans Sebald") == "Hans Sebald Beham"
      assert SEO.artist_name("GHISI, Giorgio, attributed to") == "Giorgio Ghisi (attributed to)"
      assert SEO.artist_name("VAN DE VELDE, Jan") == "Jan Van de Velde"
      assert SEO.artist_name("MCARDELL, James") == "James McArdell"
    end

    test "prices/1, dimensions_mm/1 and life_dates/1 parse catalogue text" do
      assert SEO.prices("$1,500 USD") == [{"1500", "USD"}]
      assert SEO.prices("Framed $550 CAD") == [{"550", "CAD"}]
      assert SEO.prices("On request") == []
      assert SEO.dimensions_mm("206 × 160mm") == {206, 160}
      assert SEO.dimensions_mm("20.5 x 16 cm") == {205, 160}
      assert SEO.dimensions_mm("") == {nil, nil}
      assert SEO.life_dates("1520–82") == {"1520", "1582"}
      assert SEO.life_dates("1823–1902") == {"1823", "1902"}
      assert SEO.life_dates("1530?–98") == {nil, nil}
    end

    test "truncate/2 cuts at a word boundary" do
      assert SEO.truncate("short", 155) == "short"
      cut = SEO.truncate(String.duplicate("word ", 60), 155)
      assert String.length(cut) <= 155
      assert String.ends_with?(cut, "word…")
    end
  end
end
