defmodule JanPaintingsWeb.PageControllerTest do
  use JanPaintingsWeb.ConnCase

  test "GET /", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    assert html =~ "Old Master Prints"
    assert html =~ "Canadian Prints"
  end

  test "GET /about", %{conn: conn} do
    assert conn |> get(~p"/about") |> html_response(200) =~ "International Fine Print Dealers"
  end
end
