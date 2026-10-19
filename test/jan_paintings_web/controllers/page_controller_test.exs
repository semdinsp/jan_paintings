defmodule JanPaintingsWeb.PageControllerTest do
  use JanPaintingsWeb.ConnCase

  test "GET /", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    assert html =~ "Old Master Prints"
    assert html =~ "Canadian Prints"
  end

  test "the menu bar has a home icon, marked current on the home page", %{conn: conn} do
    home = conn |> get(~p"/") |> html_response(200)
    about = conn |> get(~p"/about") |> html_response(200)

    home_links = fn html -> Regex.scan(~r{<a[^>]*href="/"[^>]*title="Home"[^>]*>}, html) end
    current? = fn [tag] -> tag =~ ~s(aria-current="page") end

    assert [_desktop, _phone] = home_links.(home)
    assert Enum.all?(home_links.(home), current?)
    assert [_, _] = home_links.(about)
    refute Enum.any?(home_links.(about), current?)
  end

  test "the menu bar has a search box that opens the matches on /prints", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ ~r{<form[^>]* id="menu-search" action="/prints" method="get"}
    assert html =~ ~s(id="menu-search-input")
    assert html =~ ~s(id="drawer-search-input")
  end

  test "GET /about", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ "International Fine Print Dealers"
    assert html =~ ~s(href="/about#contact")
    assert html =~ ~s(src="/images/jan-johnson.jpg")
    assert html =~ ~r{property="og:image" content="[^"]*/images/jan-johnson.jpg"}
  end
end
