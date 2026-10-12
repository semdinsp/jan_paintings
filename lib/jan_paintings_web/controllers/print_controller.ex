defmodule JanPaintingsWeb.PrintController do
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog

  defmodule NotFoundError do
    defexception message: "print not found", plug_status: 404
  end

  def index(conn, params) do
    category =
      case params["category"] do
        nil -> nil
        slug -> Catalog.get_category(slug) || raise_not_found()
      end

    query = params |> Map.get("q", "") |> to_string() |> String.trim()
    prints = if category, do: Catalog.list_prints(category.slug), else: Catalog.list_prints()

    render(conn, :index,
      page_title:
        if(query != "", do: "Search: #{query}", else: (category && category.name) || "All Prints"),
      category: category,
      query: query,
      prints: Catalog.search(prints, query)
    )
  end

  def show(conn, %{"category" => category_slug, "slug" => slug}) do
    category = Catalog.get_category(category_slug) || raise_not_found()
    print = Catalog.get_print(slug)

    if is_nil(print) or print.category != category.slug, do: raise_not_found()

    render(conn, :show, page_title: print.title, category: category, print: print)
  end

  defp raise_not_found, do: raise(NotFoundError)
end
