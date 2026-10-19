defmodule JanPaintingsWeb.PageControllerTest do
  use JanPaintingsWeb.ConnCase

  test "GET /", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    assert html =~ "Old Master Prints"
    assert html =~ "Canadian Prints"
  end

  test "GET /about", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ "International Fine Print Dealers"
    assert html =~ ~s(href="/about#contact")
  end
end
