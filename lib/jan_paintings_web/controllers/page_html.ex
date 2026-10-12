defmodule JanPaintingsWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use JanPaintingsWeb, :html

  alias JanPaintings.Catalog

  embed_templates "page_html/*"

  @doc "The gallery's address, email and phone numbers."
  attr :class, :any, default: nil

  def contact_details(assigns) do
    ~H"""
    <dl class={["grid gap-x-6 gap-y-3 sm:grid-cols-[6rem_1fr]", @class]}>
      <dt class="text-xs uppercase tracking-widest text-base-content/60 sm:pt-1">Email</dt>
      <dd>
        <a href="mailto:jan@janjohnsonprints.com" class="text-accent underline underline-offset-4">
          jan@janjohnsonprints.com
        </a>
      </dd>
      <dt class="text-xs uppercase tracking-widest text-base-content/60 sm:pt-1">Phone</dt>
      <dd><a href="tel:+14506582752" class="hover:text-accent">450.658.2752</a></dd>
      <dt class="text-xs uppercase tracking-widest text-base-content/60 sm:pt-1">Fax</dt>
      <dd>450.658.7654</dd>
      <dt class="text-xs uppercase tracking-widest text-base-content/60 sm:pt-1">Address</dt>
      <dd>189 rue Saint-Pierre<br />Chambly, QC, Canada J3L 1L8</dd>
      <dt class="text-xs uppercase tracking-widest text-base-content/60 sm:pt-1">Visits</dt>
      <dd>By appointment</dd>
    </dl>
    """
  end

  @doc "A mounted print card linking to a print's detail page."
  attr :print, :map, required: true

  def print_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/prints/#{@print.category}/#{@print.slug}"}
      class="group flex min-w-0 flex-col"
    >
      <div class="print-mount flex aspect-[4/5] items-center justify-center p-[10%] transition group-hover:-translate-y-0.5 group-hover:shadow-lg">
        <img
          src={Catalog.image_url(@print.image)}
          alt={"#{@print.artist}, #{@print.title}"}
          loading="lazy"
          class="max-h-full max-w-full object-contain shadow-md"
        />
      </div>
      <p class="mt-3 truncate text-[0.65rem] uppercase tracking-widest text-base-content/60 sm:text-xs">
        {@print.artist}
      </p>
      <p class="line-clamp-3 font-serif text-base leading-snug group-hover:text-accent sm:text-lg">
        {@print.title}
      </p>
      <p :if={@print.medium != ""} class="mt-0.5 text-xs text-base-content/60 sm:text-sm">
        {@print.medium}
      </p>
    </.link>
    """
  end
end
