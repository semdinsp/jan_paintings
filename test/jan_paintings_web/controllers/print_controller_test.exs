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

    html = conn |> get(~p"/prints/canadian") |> html_response(200)
    assert html =~ "$275 CAD"
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

  test "404s for unknown category or mismatched print", %{conn: conn} do
    print = hd(Catalog.list_prints("old-masters"))

    assert_error_sent 404, fn -> get(conn, ~p"/prints/nope") end
    assert_error_sent 404, fn -> get(conn, ~p"/prints/modern/#{print.slug}") end
  end
end
