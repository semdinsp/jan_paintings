defmodule JanPaintingsWeb.PrintController do
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog

  def show(conn, %{"category" => category_slug, "slug" => slug}) do
    category = Catalog.get_category(category_slug) || raise_not_found()
    print = Catalog.get_print(slug)

    if is_nil(print) or print.category != category.slug, do: raise_not_found()

    render(conn, :show,
      page_title: print.title,
      category: category,
      print: print,
      views: Catalog.views(print),
      more_by_artist: Catalog.more_by_artist(print)
    )
  end

  defp raise_not_found, do: raise(JanPaintingsWeb.NotFoundError)
end
