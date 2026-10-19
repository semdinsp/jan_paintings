defmodule JanPaintingsWeb.PrintControllerTest do
  use JanPaintingsWeb.ConnCase

  alias JanPaintings.Catalog

  test "lists prints for each category", %{conn: conn} do
    for category <- Catalog.categories() do
      html = conn |> get(~p"/prints/#{category.slug}") |> html_response(200)
      assert html =~ category.name
      [print | _] = Catalog.list_prints(category.slug)
      assert html =~ ~p"/prints/#{category.slug}/#{print.slug}"
    end
  end

  test "lists all prints with category filter", %{conn: conn} do
    html = conn |> get(~p"/prints") |> html_response(200)
    assert html =~ "All Prints"
    assert html =~ "#{length(Catalog.list_prints())} prints shown"

    for category <- Catalog.categories() do
      assert html =~ ~s(href="/prints/#{category.slug}")
    end
  end

  test "marks the active filter", %{conn: conn} do
    html = conn |> get(~p"/prints/modern") |> html_response(200)

    assert html =~
             ~r/href="\/prints\/modern"[^>]*aria-current="page"|aria-current="page"[^>]*href="\/prints\/modern"/
  end

  describe "nationality filter" do
    setup do
      [durer | _] = Catalog.list_prints("old-masters")
      [modern | _] = Catalog.list_prints("modern")
      {:ok, durer} = Catalog.update_print(durer, %{"nationality" => "german"})
      {:ok, modern} = Catalog.update_print(modern, %{"nationality" => "french"})
      %{german: durer, french: modern}
    end

    test "offers only nationalities that have prints, and no sort buttons", %{conn: conn} do
      html = conn |> get(~p"/prints") |> html_response(200)
      assert html =~ ~s(aria-label="Filter by nationality")
      assert html =~ ~s(href="/prints?nationality=german")
      assert html =~ ~s(href="/prints?nationality=french")
      refute html =~ "nationality=italian"
      refute html =~ ~s(aria-label="Sort prints")
      refute html =~ "sort="
    end

    test "hides the filter when only one nationality would be offered", %{conn: conn} do
      # Only the one Modern print has a nationality, so there is nothing to choose.
      html = conn |> get(~p"/prints/modern") |> html_response(200)
      refute html =~ ~s(aria-label="Filter by nationality")

      # Once it is selected, it stays so it can be cleared.
      html = conn |> get(~p"/prints/modern?nationality=french") |> html_response(200)
      assert html =~ ~s(aria-label="Filter by nationality")
    end

    test "shows only that nationality and marks the button", %{
      conn: conn,
      german: german,
      french: french
    } do
      html = conn |> get(~p"/prints?nationality=german") |> html_response(200)
      assert html =~ ~s(href="/prints/#{german.category}/#{german.slug}")
      refute html =~ ~s(href="/prints/#{french.category}/#{french.slug}")
      assert html =~ "1 prints shown."
      # The active button links back to every nationality.
      assert html =~ ~r/href="\/prints"[^>]*aria-current="true"/
    end

    test "category links and search keep the nationality", %{conn: conn, german: german} do
      q = german.artist |> String.split(",") |> hd() |> String.downcase()
      html = conn |> get(~p"/prints?#{[nationality: "german", q: q]}") |> html_response(200)
      assert html =~ ~s(href="/prints/#{german.category}/#{german.slug}")
      assert html =~ ~s(href="/prints/old-masters?nationality=german&amp;q=#{q}")
      assert html =~ "Clear search"
      assert html =~ ~s(href="/prints?nationality=german")
    end

    test "ignores an unknown nationality", %{conn: conn} do
      html = conn |> get(~p"/prints?nationality=martian") |> html_response(200)
      refute html =~ ~s(aria-current="true")
      assert html =~ "#{length(Catalog.list_prints())} prints shown."
    end
  end

  test "shows a print", %{conn: conn} do
    print = hd(Catalog.list_prints("old-masters"))
    html = conn |> get(~p"/prints/old-masters/#{print.slug}") |> html_response(200)
    assert html =~ Phoenix.HTML.html_escape(print.title) |> Phoenix.HTML.safe_to_string()
  end

  test "shows the print description", %{conn: conn} do
    print = Catalog.get_print("dusart-fiddler-in-an-inn")
    html = conn |> get(~p"/prints/old-masters/#{print.slug}") |> html_response(200)

    assert html =~ "Hollstein 15"
    assert html =~ "282 × 253mm"
    assert html =~ "Provenance"
    assert html =~ "Arms of Amsterdam"
  end

  test "shows prices with their currency", %{conn: conn} do
    html = conn |> get(~p"/prints/old-masters/dusart-fiddler-in-an-inn") |> html_response(200)
    assert html =~ Catalog.get_print("dusart-fiddler-in-an-inn").price
    assert html =~ "USD"

    html = conn |> get(~p"/prints/canadian/greene-the-log-shack") |> html_response(200)
    assert html =~ "$275 CAD"
  end

  test "prices are not shown on the home page or print lists", %{conn: conn} do
    for path <- [~p"/", ~p"/prints", ~p"/prints/canadian"] do
      html = conn |> get(path) |> html_response(200)
      refute html =~ ~r/\$[\d,]+ (USD|CAD)/, "price shown on #{path}"
    end
  end

  test "sold prints get a badge in the list and on the detail page", %{conn: conn} do
    sold = Catalog.get_print("buller-lovers")
    assert sold.status == "sold"

    list = conn |> get(~p"/prints/canadian") |> html_response(200)
    assert list =~ ~r/>\s*sold\s*</

    detail = conn |> get(~p"/prints/canadian/#{sold.slug}") |> html_response(200)
    assert detail =~ ~r/>\s*sold\s*</
    assert detail =~ "Ask about similar prints"
    refute detail =~ "CAD"
  end

  test "reserved prints get a reserved badge", %{conn: conn} do
    html =
      conn
      |> get(~p"/prints/old-masters/pencz-the-triumph-of-death-from-the-six-triumphs-of-petrarch")
      |> html_response(200)

    assert html =~ ~r/>\s*reserved\s*</
  end

  test "home page has a search box", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    assert html =~ ~s(role="search")
    assert html =~ ~s(name="q")
  end

  test "searches by artist or title and keeps the search when filtering", %{conn: conn} do
    html = conn |> get(~p"/prints?q=neilson") |> html_response(200)
    assert html =~ "4 prints matching"
    assert html =~ "Dredging the St. Charles River"
    assert html =~ ~s(href="/prints/canadian?q=neilson")

    html = conn |> get(~p"/prints/modern?q=neilson") |> html_response(200)
    assert html =~ "0 prints matching"
    assert html =~ "No prints found"
  end

  test "links to more prints by the same artist with a button, not a section", %{conn: conn} do
    html =
      conn
      |> get(~p"/prints/canadian/neilson-dredging-the-st-charles-river")
      |> html_response(200)

    assert html =~ ~r{href="/prints\?q=NEILSON[^"]*"[^>]*>\s*More by this artist}
    refute html =~ ~s(id="more-by-artist")
    refute html =~ ~s(href="/prints/canadian/neilson-timber-ship-quebec")
  end

  test "the More by this artist button opens a search listing the artist's prints", %{conn: conn} do
    html =
      conn
      |> get(~p"/prints/canadian/neilson-dredging-the-st-charles-river")
      |> html_response(200)

    [_, href] = Regex.run(~r{href="(/prints\?q=[^"]*)"[^>]*>\s*More by this artist}, html)
    results = conn |> get(href) |> html_response(200)

    assert results =~ ~s(href="/prints/canadian/neilson-dredging-the-st-charles-river")
    assert results =~ ~s(href="/prints/canadian/neilson-timber-ship-quebec")
    assert results =~ "4 prints matching"
  end

  test "omits the button when the artist has no other prints", %{conn: conn} do
    html = conn |> get(~p"/prints/old-masters/dusart-fiddler-in-an-inn") |> html_response(200)
    refute html =~ "More by this artist"
  end

  test "shows a gallery of extra views when a print has them", %{conn: conn} do
    html =
      conn
      |> get(
        ~p"/prints/modern/tissot-the-return-from-the-parable-of-the-prodigal-son-a-set-of-four-plus-title"
      )
      |> html_response(200)

    assert html =~ ~s(id="print-gallery")
    assert html =~ "3 views"
    assert html =~ "/images/catalogue/tissot-working-proof-2-495.jpg"
  end

  test "links to a larger image when one exists", %{conn: conn} do
    html =
      conn
      |> get(~p"/prints/old-masters/tiepolo-venice-receiving-neptunes-homage-after-g-b-tiepolo")
      |> html_response(200)

    assert html =~ "View larger"
    assert html =~ "/images/prints/tiepolo-venice-receiving-neptunes-homage-large.jpg"
    refute html =~ ~s(id="print-gallery")
  end

  test "prints without extra views have no gallery", %{conn: conn} do
    html = conn |> get(~p"/prints/old-masters/dusart-fiddler-in-an-inn") |> html_response(200)
    refute html =~ "View larger"
    refute html =~ ~s(id="print-gallery")
  end

  test "404s for unknown category or mismatched print", %{conn: conn} do
    print = hd(Catalog.list_prints("old-masters"))

    assert_error_sent 404, fn -> get(conn, ~p"/prints/nope") end
    assert_error_sent 404, fn -> get(conn, ~p"/prints/modern/#{print.slug}") end
  end
end
