defmodule JanPaintingsWeb.PageController do
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog

  def home(conn, _params) do
    render(conn, :home,
      categories: Catalog.categories(),
      featured: Catalog.featured_prints()
    )
  end

  def about(conn, _params), do: render(conn, :about, page_title: "About")

  def contact(conn, _params), do: render(conn, :contact, page_title: "Contact")
end
