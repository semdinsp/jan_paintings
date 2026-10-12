defmodule JanPaintingsWeb.PageController do
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog

  def home(conn, _params) do
    categories = Enum.map(Catalog.categories(), &{&1, Catalog.cover_print(&1.slug)})

    render(conn, :home,
      categories: categories,
      hero: Catalog.get_print("pether-a-farriers-shop-after-joseph-wright-of-derby"),
      featured: Catalog.featured_prints()
    )
  end

  def about(conn, _params), do: render(conn, :about, page_title: "About")

  def contact(conn, _params), do: render(conn, :contact, page_title: "Contact")
end
