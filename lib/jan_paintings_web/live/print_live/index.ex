defmodule JanPaintingsWeb.PrintLive.Index do
  @moduledoc "Print grid for all prints or one category, with live search and a nationality filter."
  use JanPaintingsWeb, :live_view

  import JanPaintingsWeb.PageHTML, only: [print_card: 1, search_form: 1]
  import JanPaintingsWeb.PrintHTML, only: [nationality_filter: 1]

  alias JanPaintings.Catalog
  alias JanPaintings.Catalog.Print
  alias JanPaintingsWeb.SEO

  @impl true
  def handle_params(params, _uri, socket) do
    category =
      case params["category"] do
        nil -> nil
        slug -> Catalog.get_category(slug) || raise JanPaintingsWeb.NotFoundError
      end

    query = params |> Map.get("q", "") |> to_string() |> String.trim()

    nationality =
      Enum.find_value(Print.nationalities(), fn {key, _} ->
        key == params["nationality"] && key
      end)

    prints = if category, do: Catalog.list_prints(category.slug), else: Catalog.list_prints()

    matching = Catalog.search(prints, query)
    shown = Catalog.filter_nationality(matching, nationality)
    path = if category, do: "/prints/#{category.slug}", else: "/prints"
    description = description(category, length(prints))

    {:noreply,
     assign(socket,
       page_title: page_title(category, query),
       meta_description: description,
       canonical_path: path,
       og_image: List.first(Enum.map(shown, & &1.image)),
       json_ld:
         SEO.collection_json_ld(
           (category && category.name) || "All Prints",
           description,
           path,
           shown
         ),
       category: category,
       query: query,
       nationality: nationality,
       nationalities: nationalities_present(matching, nationality),
       clear_search_path: search_path(category, "", nationality),
       prints: shown
     )}
  end

  # Keep the URL in sync with the search box, without a history entry per keystroke.
  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    %{category: category, nationality: nationality} = socket.assigns
    {:noreply, push_patch(socket, to: search_path(category, query, nationality), replace: true)}
  end

  # Only offer nationalities that would show prints, plus the one selected,
  # and no filter at all when it would just repeat the whole list.
  defp nationalities_present(prints, selected) do
    present = MapSet.new(prints, & &1.nationality)

    case Enum.filter(Print.nationalities(), fn {key, _} -> key == selected or key in present end) do
      [{key, _}] when key != selected -> []
      options -> options
    end
  end

  defp search_path(category, query, nationality) do
    params =
      [q: if(String.trim(query) != "", do: String.trim(query)), nationality: nationality]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    if category, do: ~p"/prints/#{category.slug}?#{params}", else: ~p"/prints?#{params}"
  end

  defp description(nil, count) do
    "#{count} fine prints in stock: Old Master engravings and etchings, nineteenth- and early twentieth-century European prints, and Canadian printmaking."
  end

  defp description(category, count) do
    "#{category.name} at Jan Johnson: #{count} in stock. #{category.blurb}"
  end

  defp page_title(_category, query) when query != "", do: "Search: #{query}"
  defp page_title(nil, _query), do: "All Prints: Old Master, Modern and Canadian"
  defp page_title(category, _query), do: category.name
end
