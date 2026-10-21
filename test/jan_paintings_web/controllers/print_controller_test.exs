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

  test "lists all prints, with no category buttons (the menu bar has them)", %{conn: conn} do
    html = conn |> get(~p"/prints") |> html_response(200)
    assert html =~ "All Prints"
    assert html =~ "#{length(Catalog.list_prints())} prints shown"

    refute html =~ ~s(aria-label="Filter by category")

    for category <- Catalog.categories() do
      assert html =~ ~s(href="/prints/#{category.slug}")
    end
  end

  test "marks the category in the menu bar", %{conn: conn} do
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
      # No visible label: the country names speak for themselves.
      refute html =~ ~r/>\s*Nationality\s*</
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

    test "the search and the nationality keep each other", %{conn: conn, german: german} do
      q = german.artist |> String.split(",") |> hd() |> String.downcase()
      html = conn |> get(~p"/prints?#{[nationality: "german", q: q]}") |> html_response(200)
      assert html =~ ~s(href="/prints/#{german.category}/#{german.slug}")
      # Unselecting the nationality keeps the search...
      assert html =~ ~r/href="\/prints\?q=#{q}"[^>]*aria-current="true"/
      # ...and clearing the search keeps the nationality.
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
    # A slightly smaller title and larger artist line than on other pages.
    assert html =~ ~r/<h1[^>]*class="type-h1 print-detail-title/
    assert html =~ ~r/<p[^>]*class="type-artist print-detail-artist"/
  end

  test "the back link returns to the print's place in its category list", %{conn: conn} do
    print = hd(Catalog.list_prints("old-masters"))
    html = conn |> get(~p"/prints/old-masters/#{print.slug}") |> html_response(200)
    anchor = "print-#{print.slug}"

    assert html =~
             ~r/<a(?=[^>]*class="link-more")[^>]*href="\/prints\/old-masters##{anchor}"/

    list = conn |> get(~p"/prints/old-masters") |> html_response(200)
    assert list =~ ~r/<a(?=[^>]*id="#{anchor}")[^>]*href="\/prints\/old-masters\/#{print.slug}"/
  end

  test "lists the details in the gallery's order", %{conn: conn} do
    print = Catalog.get_print("dusart-fiddler-in-an-inn")

    {:ok, _} =
      Catalog.update_print(print, %{
        "medium" => "Etching",
        "catalogue_references" => "Hollstein 15",
        "state" => "Only state",
        "watermark" => "Arms of Amsterdam",
        "provenance" => "A collection",
        "condition" => "Fine",
        "dimensions" => "282 × 253mm",
        "sheet_size" => "300 × 270mm"
      })

    html = conn |> get(~p"/prints/old-masters/#{print.slug}") |> html_response(200)
    labels = Regex.scan(~r{<dt[^>]*>([^<]+)</dt>}, html, capture: :all_but_first) |> List.flatten()

    assert labels ==
             ~w(Medium References State Watermark Provenance Condition Size Sheet Price)
  end

  test "shows the print description", %{conn: conn} do
    print = Catalog.get_print("dusart-fiddler-in-an-inn")
    html = conn |> get(~p"/prints/old-masters/#{print.slug}") |> html_response(200)

    assert html =~ "Hollstein 15"
    assert html =~ "282 × 253mm"
    assert html =~ "Provenance"
    assert html =~ "Arms of Amsterdam"
  end

  test "shows additional notes, one paragraph each, only when there are some", %{conn: conn} do
    print = Catalog.get_print("dusart-fiddler-in-an-inn")
    html = conn |> get(~p"/prints/old-masters/#{print.slug}") |> html_response(200)
    refute html =~ "Additional notes"

    {:ok, _} =
      Catalog.update_print(print, %{"additional_notes" => "First thought.\n\nSecond thought."})

    html = conn |> get(~p"/prints/old-masters/#{print.slug}") |> html_response(200)
    assert html =~ "Additional notes"
    assert html =~ ~r/<p[^>]*italic[^>]*>\s*First thought.\s*<\/p>/
    assert html =~ ~r/<p[^>]*italic[^>]*>\s*Second thought.\s*<\/p>/

    # A row of the details, after Condition and before Price.
    [_, after_condition] = String.split(html, ">Condition</dt>", parts: 2)
    [notes_row, _] = String.split(after_condition, ">Price</dt>", parts: 2)
    assert notes_row =~ ">Additional notes</dt>"
    assert notes_row =~ "First thought."

    # That row is for phones; from md the notes sit under the images, unlabelled.
    assert html =~
             ~r/<div[^>]*class="[^"]*md:hidden[^"]*"[^>]*>\s*<dt[^>]*>Additional notes<\/dt>/

    [_, under_images] = String.split(html, ~s(id="print-notes"), parts: 2)
    [under_images, _] = String.split(under_images, "</div>", parts: 2)
    assert under_images =~ ~r/class="[^"]*hidden[^"]*md:block/
    assert under_images =~ ~r/<p[^>]*italic[^>]*>\s*Second thought.\s*<\/p>/
    refute under_images =~ "Additional notes"
    assert String.split(html, ~s(id="print-notes")) |> hd() =~ ~s(id="print-main-image")
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
    # No price. Match a price, not bare "CAD", which the random CSRF token can contain.
    refute detail =~ ~r/\d CAD\b/
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

  test "searches by artist or title within a category", %{conn: conn} do
    html = conn |> get(~p"/prints?q=neilson") |> html_response(200)
    assert html =~ "4 prints matching"
    assert html =~ "Dredging the St. Charles River"

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

    large = "/images/prints/tiepolo-venice-receiving-neptunes-homage-large.jpg"

    # A button with a magnifier, and the image itself, both open the larger view...
    assert html =~
             ~r/<a(?=[^>]*id="print-view-larger")(?=[^>]*href="#{large}")(?=[^>]*data-lightbox)[^>]*class="btn[^"]*"[^>]*>\s*<span[^>]*hero-magnifying-glass-plus/

    assert html =~
             ~r/<a(?=[^>]*id="print-main-link")(?=[^>]*data-lightbox)[^>]*href="#{large}"/

    # ...in a full-screen dialog with a Close button, not a new tab.
    refute html =~ ~s(target="_blank")
    assert html =~ ~r/<dialog[^>]*id="print-lightbox"/
    assert html =~ ~r/<form method="dialog"[^>]*>\s*<button[^>]*id="print-lightbox-close"[^>]*>[\s\S]*?Close/
    assert html =~ ~s(id="print-lightbox-image")
    refute html =~ ~s(id="print-gallery")
  end

  test "has no larger view or image link when there is no larger image", %{conn: conn} do
    html = conn |> get(~p"/prints/old-masters/dusart-fiddler-in-an-inn") |> html_response(200)
    refute html =~ "View larger"
    refute html =~ ~s(id="print-main-link")
    assert html =~ ~s(id="print-main-image")
    refute html =~ ~s(id="print-lightbox")
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

  test "drafts are not on the site", %{conn: conn} do
    {:ok, draft} =
      "neilson-dredging-the-st-charles-river"
      |> Catalog.get_print()
      |> Catalog.set_status("draft")

    assert_error_sent 404, fn -> get(conn, ~p"/prints/canadian/#{draft.slug}") end

    for path <- [~p"/prints", ~p"/prints/canadian", ~p"/prints?q=neilson", ~p"/sitemap.xml"] do
      refute conn |> get(path) |> response(200) =~ draft.slug
    end

    enquiry = conn |> get(~p"/about?#{[print: draft.slug]}") |> html_response(200)
    refute enquiry =~ draft.title
  end
end
