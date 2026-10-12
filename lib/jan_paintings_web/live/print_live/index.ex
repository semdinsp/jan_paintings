defmodule JanPaintingsWeb.PrintLive.Index do
  @moduledoc "Print grid for all prints or one category, with live search."
  use JanPaintingsWeb, :live_view

  import JanPaintingsWeb.PageHTML, only: [print_card: 1, search_form: 1]
  import JanPaintingsWeb.PrintHTML, only: [category_filter: 1]

  alias JanPaintings.Catalog

  @impl true
  def handle_params(params, _uri, socket) do
    category =
      case params["category"] do
        nil -> nil
        slug -> Catalog.get_category(slug) || raise JanPaintingsWeb.NotFoundError
      end

    query = params |> Map.get("q", "") |> to_string() |> String.trim()
    prints = if category, do: Catalog.list_prints(category.slug), else: Catalog.list_prints()

    {:noreply,
     assign(socket,
       page_title: page_title(category, query),
       category: category,
       query: query,
       prints: Catalog.search(prints, query)
     )}
  end

  # Keep the URL in sync with the search box, without a history entry per keystroke.
  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, push_patch(socket, to: search_path(socket.assigns.category, query), replace: true)}
  end

  defp search_path(category, query) do
    params = if String.trim(query) != "", do: [q: String.trim(query)], else: []
    if category, do: ~p"/prints/#{category.slug}?#{params}", else: ~p"/prints?#{params}"
  end

  defp page_title(_category, query) when query != "", do: "Search: #{query}"
  defp page_title(nil, _query), do: "All Prints"
  defp page_title(category, _query), do: category.name
end
