defmodule JanPaintingsWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use JanPaintingsWeb, :html

  alias JanPaintings.Catalog

  embed_templates "page_html/*"

  @doc "A thumbnail card linking to a print's detail page."
  attr :print, :map, required: true

  def print_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/prints/#{@print.category}/#{@print.slug}"}
      class="group flex flex-col"
    >
      <div class="aspect-[4/5] flex items-center justify-center bg-base-200 p-4">
        <img
          src={Catalog.image_url(@print.thumb)}
          alt={"#{@print.artist}, #{@print.title}"}
          loading="lazy"
          class="max-h-full max-w-full object-contain shadow-sm transition group-hover:shadow-md"
        />
      </div>
      <p class="mt-3 text-xs uppercase tracking-widest text-base-content/60">{@print.artist}</p>
      <p class="font-serif text-lg leading-snug group-hover:text-primary">{@print.title}</p>
      <p :if={@print.medium != ""} class="text-sm text-base-content/60">{@print.medium}</p>
    </.link>
    """
  end
end
