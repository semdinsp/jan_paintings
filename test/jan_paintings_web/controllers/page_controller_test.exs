defmodule JanPaintingsWeb.PageControllerTest do
  use JanPaintingsWeb.ConnCase

  test "GET /", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    assert html =~ "Old Master Prints"
    assert html =~ "Canadian Prints"
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
