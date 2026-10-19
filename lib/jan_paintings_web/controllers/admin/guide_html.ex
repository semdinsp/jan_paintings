defmodule JanPaintingsWeb.Admin.GuideHTML do
  use JanPaintingsWeb, :html

  embed_templates "guide_html/*"

  @doc """
  A guide's icon: a framed print in a gold-ringed medallion, with a rose
  badge showing an upload arrow (`:adding`) or a pencil (`:editing`).
  """
  attr :guide, :atom, values: [:adding, :editing], required: true
  attr :class, :any, default: "size-16"

  def guide_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 64 64" class={@class} aria-hidden="true">
      <circle cx="32" cy="32" r="30" class="fill-rose-tint stroke-gold" stroke-width="2" />
      <rect
        x="15"
        y="15"
        width="28"
        height="33"
        rx="1"
        class="fill-paper stroke-ink"
        stroke-width="1.6"
      />
      <rect x="19" y="19" width="20" height="25" class="stroke-ink" fill="none" stroke-width="0.8" />
      <circle cx="33.5" cy="24.5" r="2" class="fill-ink" opacity="0.45" />
      <path d="M19 38 l5-6 4 3.5 4-5 7 6.5 V44 H19 Z" class="fill-ink" opacity="0.3" />
      <circle cx="45" cy="45" r="10.5" class="fill-rose stroke-paper" stroke-width="2" />
      <path
        :if={@guide == :adding}
        d="M45 50.5 V39.5 M40.5 44 L45 39.5 L49.5 44"
        class="stroke-paper"
        fill="none"
        stroke-width="2.4"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <g :if={@guide == :editing} class="fill-paper">
        <path d="M40 50 l1.2 -4.4 7.3 -7.3 3.2 3.2 -7.3 7.3 Z" />
        <path d="M49.4 37.4 l1.2 -1.2 a1.2 1.2 0 0 1 1.7 0 l1.5 1.5 a1.2 1.2 0 0 1 0 1.7 l-1.2 1.2 Z" />
      </g>
    </svg>
    """
  end

  @doc "A numbered step in a guide."
  attr :n, :integer, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  def step(assigns) do
    ~H"""
    <li class="grid grid-cols-[2rem_1fr] gap-x-3">
      <span class="flex size-8 items-center justify-center rounded-full bg-rose-tint font-semibold text-rose">
        {@n}
      </span>
      <div>
        <h3 class="pt-1 font-semibold">{@title}</h3>
        <div class="mt-1 space-y-2 text-ink-2">{render_slot(@inner_block)}</div>
      </div>
    </li>
    """
  end

  @doc "A highlighted note, such as the rules for drafts."
  attr :title, :string, required: true
  attr :icon, :string, default: "hero-information-circle"
  attr :id, :string, default: nil
  slot :inner_block, required: true

  def callout(assigns) do
    ~H"""
    <aside id={@id} class="border-l-4 border-gold bg-paper-2 px-5 py-4">
      <h3 class="flex items-center gap-2 font-semibold">
        <.icon name={@icon} class="size-5 text-gold" /> {@title}
      </h3>
      <div class="mt-2 space-y-2 text-ink-2">{render_slot(@inner_block)}</div>
    </aside>
    """
  end

  @doc "Back link to the list of guides."
  def back(assigns) do
    ~H"""
    <.link
      navigate={~p"/admin/guides"}
      class="text-sm uppercase tracking-widest text-base-content/60 hover:text-accent"
    >
      <span aria-hidden="true">&larr;</span> All guides
    </.link>
    """
  end
end
