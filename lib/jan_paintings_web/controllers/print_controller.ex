defmodule JanPaintingsWeb.PrintController do
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog

  defmodule NotFoundError do
    defexception message: "print not found", plug_status: 404
  end

  def index(conn, %{"category" => category_slug}) do
    category = Catalog.get_category(category_slug) || raise_not_found()

    render(conn, :index,
      page_title: category.name,
      category: category,
      prints: Catalog.list_prints(category.slug)
    )
  end

  def index(conn, _params) do
    render(conn, :index, page_title: "All Prints", category: nil, prints: Catalog.list_prints())
  end

  def show(conn, %{"category" => category_slug, "slug" => slug}) do
    category = Catalog.get_category(category_slug) || raise_not_found()
    print = Catalog.get_print(slug)

    if is_nil(print) or print.category != category.slug, do: raise_not_found()

    render(conn, :show, page_title: print.title, category: category, print: print)
  end

  defp raise_not_found, do: raise(NotFoundError)
end
