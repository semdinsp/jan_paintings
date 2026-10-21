defmodule JanPaintingsWeb.PrintHTML do
  use JanPaintingsWeb, :html

  import JanPaintingsWeb.PageHTML, only: [status_badge: 1]

  embed_templates "print_html/*"

  @doc "One labelled row in a print's description."
  attr :label, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def detail(assigns) do
    ~H"""
    <div class={["border-b border-rule py-3 sm:grid sm:grid-cols-[7rem_1fr] sm:gap-4", @class]}>
      <dt class="type-eyebrow sm:pt-1">{@label}</dt>
      <dd class="mt-1 sm:mt-0">{render_slot(@inner_block)}</dd>
    </div>
    """
  end

  @doc """
  Buttons that narrow the listing to one artist nationality. Clicking the
  active one again shows every nationality.
  """
  attr :current, :map, default: nil
  attr :query, :string, default: ""
  attr :nationality, :string, default: nil
  attr :options, :list, required: true, doc: "`{key, label}` pairs to offer"
  attr :class, :any, default: nil

  def nationality_filter(assigns) do
    assigns =
      assign(assigns,
        buttons:
          for {key, label} <- assigns.options do
            active = assigns.nationality == key
            params = listing_params(assigns.query, if(active, do: nil, else: key))

            path =
              if assigns.current,
                do: ~p"/prints/#{assigns.current.slug}?#{params}",
                else: ~p"/prints?#{params}"

            {label, path, active}
          end
      )

    ~H"""
    <div
      :if={@buttons != []}
      role="group"
      aria-label="Filter by nationality"
      class={[
        "flex flex-wrap items-center gap-2",
        @class
      ]}
    >
      <.link
        :for={{label, path, active} <- @buttons}
        patch={path}
        aria-current={active && "true"}
        class={chip_class(active)}
      >
        {label}
        <span :if={active} class="sr-only">(selected; select again to show all)</span>
      </.link>
    </div>
    """
  end

  defp listing_params(query, nationality) do
    [q: if(query != "", do: query), nationality: nationality]
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
  end

  defp chip_class(active) do
    [
      "flex min-h-11 shrink-0 items-center rounded-[2px] border-2 px-3 text-[0.9375rem] transition sm:px-4",
      if(active,
        do: "border-rose bg-rose-tint font-semibold text-rose",
        else: "border-gold text-ink hover:border-rose hover:text-rose"
      )
    ]
  end
end
