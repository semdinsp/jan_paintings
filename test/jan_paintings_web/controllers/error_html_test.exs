defmodule JanPaintingsWeb.ErrorHTMLTest do
  use JanPaintingsWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders a branded 404 page with links back into the site" do
    html = render_to_string(JanPaintingsWeb.ErrorHTML, "404", "html", [])
    assert html =~ ~r/<h1[^>]*>Page not found<\/h1>/
    assert html =~ ~s(href="/prints")
    assert html =~ ~s(href="/contact")
  end

  test "renders a branded 500 page" do
    html = render_to_string(JanPaintingsWeb.ErrorHTML, "500", "html", [])
    assert html =~ ~r/<h1[^>]*>Something went wrong<\/h1>/
    assert html =~ "mailto:jan@janjohnsonprints.com"
  end

  test "other statuses fall back to the plain status message" do
    assert render_to_string(JanPaintingsWeb.ErrorHTML, "403", "html", []) == "Forbidden"
  end

  test "an unknown URL gets the 404 page inside the full site layout", %{conn: conn} do
    body = conn |> get("/no-such-page") |> html_response(404)

    assert body =~ "<!DOCTYPE html>"
    assert body =~ ~s(/assets/css/app.css)
    assert body =~ ~r/<nav[^>]*aria-label="Main"/
    assert body =~ "Page not found"
  end
end
