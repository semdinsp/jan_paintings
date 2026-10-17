defmodule JanPaintingsWeb.PrintHTML do
  use JanPaintingsWeb, :html

  import JanPaintingsWeb.PageHTML, only: [print_card: 1, status_badge: 1]

  embed_templates "print_html/*"

  @doc "One labelled row in a print's description."
  attr :label, :string, required: true
  slot :inner_block, required: true

  def detail(assigns) do
    ~H"""
    <div class="border-b border-rule py-3 sm:grid sm:grid-cols-[7rem_1fr] sm:gap-4">
      <dt class="type-eyebrow sm:pt-1">{@label}</dt>
      <dd class="mt-1 sm:mt-0">{render_slot(@inner_block)}</dd>
    </div>
    """
  end

  @doc "Filter tabs for switching between all prints and each category."
  attr :current, :map, default: nil
  attr :query, :string, default: ""
  attr :sort, :string, default: nil

  def category_filter(assigns) do
    # Switching category keeps the current search and sort.
    params = listing_params(assigns.query, assigns.sort)

    assigns =
      assign(assigns,
        options: [
          {"All", ~p"/prints?#{params}", is_nil(assigns.current)}
          | for(
              c <- JanPaintings.Catalog.categories(),
              do:
                {c.short, ~p"/prints/#{c.slug}?#{params}",
                 assigns.current && assigns.current.slug == c.slug}
            )
        ]
      )

    ~H"""
    <nav
      aria-label="Filter by category"
      class="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1 sm:mx-0 sm:flex-wrap sm:px-0"
    >
      <.link
        :for={{label, path, active} <- @options}
        patch={path}
        aria-current={active && "page"}
        class={chip_class(active)}
      >
        {label}
      </.link>
    </nav>
    """
  end

  @doc """
  Price and Size buttons that reorder the listing, smallest first. Clicking
  the active one again returns to the usual artist order.
  """
  attr :current, :map, default: nil
  attr :query, :string, default: ""
  attr :sort, :string, default: nil

  def sort_toggles(assigns) do
    assigns =
      assign(assigns,
        options:
          for {key, label, order} <- [{"price", "Price", "lowest"}, {"size", "Size", "smallest"}] do
            active = assigns.sort == key
            params = listing_params(assigns.query, if(active, do: nil, else: key))

            path =
              if assigns.current,
                do: ~p"/prints/#{assigns.current.slug}?#{params}",
                else: ~p"/prints?#{params}"

            {label, order, path, active}
          end
      )

    ~H"""
    <div role="group" aria-label="Sort prints" class="flex flex-wrap items-center gap-2 pb-1">
      <span class="type-meta mr-1">Sort by</span>
      <.link
        :for={{label, order, path, active} <- @options}
        patch={path}
        aria-current={active && "true"}
        class={chip_class(active)}
      >
        {label}
        <span :if={active} aria-hidden="true" class="ml-1">↑</span>
        <span class="sr-only">
          {if active, do: "(#{order} first; select again to undo)", else: "(#{order} first)"}
        </span>
      </.link>
    </div>
    """
  end

  defp listing_params(query, sort) do
    [q: if(query != "", do: query), sort: sort] |> Enum.reject(fn {_, v} -> is_nil(v) end)
  end

  defp chip_class(active) do
    [
      "flex min-h-11 shrink-0 items-center rounded-[2px] border-2 px-3 text-[0.9375rem] transition sm:px-4",
      if(active,
        do: "border-rose bg-rose-tint font-semibold text-rose",
        else: "border-lemon text-ink hover:border-rose hover:text-rose"
      )
    ]
  end
end
