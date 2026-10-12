defmodule JanPaintingsWeb.PrintHTML do
  use JanPaintingsWeb, :html

  import JanPaintingsWeb.PageHTML, only: [print_card: 1]

  embed_templates "print_html/*"

  @doc "Filter tabs for switching between all prints and each category."
  attr :current, :map, default: nil

  def category_filter(assigns) do
    assigns =
      assign(assigns,
        options: [
          {"All", ~p"/prints", is_nil(assigns.current)}
          | for(
              c <- JanPaintings.Catalog.categories(),
              do:
                {c.short, ~p"/prints/#{c.slug}",
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
