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
        patch={path}
        aria-current={active && "page"}
        class={[
          "flex min-h-11 shrink-0 items-center rounded-[2px] border px-4 text-[0.9375rem] transition",
          if(active,
            do: "border-rose bg-rose-tint font-semibold text-rose",
            else: "border-rule text-ink hover:border-rose hover:text-rose"
          )
        ]}
      >
        {label}
      </.link>
    </nav>
    """
  end
end
