defmodule JanPaintingsWeb.SearchLive do
  @moduledoc """
  Home page search box that shows matching prints as you type.

  Pressing Enter (or submitting without JavaScript) opens the full results
  on the print list.
  """
  use JanPaintingsWeb, :live_view

  import JanPaintingsWeb.PageHTML, only: [search_form: 1]

  alias JanPaintings.Catalog

  @limit 6

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: [], total: 0), layout: false}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    query = String.trim(query)
    matches = if query == "", do: [], else: Catalog.search(Catalog.list_prints(), query)

    {:noreply,
     assign(socket, query: query, results: Enum.take(matches, @limit), total: length(matches))}
  end

  def handle_event("submit", %{"q" => query}, socket) do
    {:noreply, redirect(socket, to: ~p"/prints?#{[q: String.trim(query)]}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative max-w-lg" phx-click-away={JS.hide(to: "#home-search-results")}>
      <.search_form
        id="home-search"
        value={@query}
        phx-change="search"
        phx-submit="submit"
        phx-focus={JS.show(to: "#home-search-results")}
      />

      <div
        :if={@query != ""}
        id="home-search-results"
        class="absolute inset-x-0 z-30 mt-2 overflow-hidden rounded-box border border-base-300 bg-base-100 shadow-xl"
      >
        <p :if={@results == []} class="px-4 py-3 text-sm text-base-content/70">
          No prints match “{@query}”.
        </p>

        <ul :if={@results != []} class="divide-y divide-base-300">
          <li :for={print <- @results}>
            <a
              href={~p"/prints/#{print.category}/#{print.slug}"}
              class="flex items-center gap-3 px-3 py-2 hover:bg-base-200"
            >
              <img
                src={Catalog.image_url(print.thumb)}
                alt=""
                class="size-12 shrink-0 bg-base-200 object-contain"
              />
              <span class="min-w-0">
                <span class="block truncate text-[0.65rem] uppercase tracking-widest text-base-content/60">
                  {print.artist}
                </span>
                <span class="block truncate font-serif">{print.title}</span>
              </span>
            </a>
          </li>
        </ul>

        <a
          :if={@total > 0}
          href={~p"/prints?#{[q: @query]}"}
          class="block bg-base-200 px-4 py-2.5 text-sm font-medium text-accent hover:underline"
        >
          See all {@total} {if @total == 1, do: "result", else: "results"}
          <span aria-hidden="true">&rarr;</span>
        </a>
      </div>
    </div>
    """
  end
end
