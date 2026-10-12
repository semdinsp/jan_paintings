defmodule JanPaintingsWeb.PrintHTML do
  use JanPaintingsWeb, :html

  import JanPaintingsWeb.PageHTML, only: [print_card: 1, search_form: 1, status_badge: 1]

  embed_templates "print_html/*"

  @doc "One labelled row in a print's description."
  attr :label, :string, required: true
  slot :inner_block, required: true

  def detail(assigns) do
    ~H"""
    <div class="sm:grid sm:grid-cols-[7rem_1fr] sm:gap-4">
      <dt class="text-xs uppercase tracking-widest text-base-content/60 sm:pt-0.5">{@label}</dt>
      <dd class="mt-1 text-base-content/80 sm:mt-0">{render_slot(@inner_block)}</dd>
    </div>
    """
  end

  @doc "Filter tabs for switching between all prints and each category."
  attr :current, :map, default: nil
  attr :query, :string, default: ""

  def category_filter(assigns) do
    # Switching category keeps the current search.
    params = if assigns.query != "", do: [q: assigns.query], else: []

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
        navigate={path}
        aria-current={active && "page"}
        class={[
          "shrink-0 rounded-full border px-4 py-1.5 text-sm transition",
          if(active,
            do: "border-primary bg-primary text-primary-content",
            else: "border-base-300 bg-base-100/60 hover:border-accent hover:text-accent"
          )
        ]}
      >
        {label}
      </.link>
    </nav>
    """
  end
end
