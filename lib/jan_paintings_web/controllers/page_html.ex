defmodule JanPaintingsWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use JanPaintingsWeb, :html

  alias JanPaintings.Catalog

  embed_templates "page_html/*"

  @doc "The gallery's email and phone numbers, and visits by appointment."
  attr :class, :any, default: nil

  def contact_details(assigns) do
    ~H"""
    <dl id="contact-details" class={["grid gap-x-6 gap-y-3 sm:grid-cols-[6rem_1fr]", @class]}>
      <dt class="type-eyebrow sm:pt-0.5">Email</dt>
      <dd><a href="mailto:jan@janjohnsonprints.com" class="link">jan@janjohnsonprints.com</a></dd>
      <dt class="type-eyebrow sm:pt-0.5">Phone</dt>
      <dd><a href="tel:+14506582752" class="link">450.658.2752</a></dd>
      <dt class="type-eyebrow sm:pt-0.5">Cell</dt>
      <dd><a href="tel:+15146086959" class="link">514.608.6959</a></dd>
      <dt class="type-eyebrow sm:pt-0.5">Visits</dt>
      <dd>By appointment</dd>
    </dl>
    """
  end

  @doc """
  The terms of sale, one short section each, shown on the Terms of Sale page
  and under the contact details on the Contact page. `heading` is the tag for
  the section headings, so they nest under the page's own headings.
  """
  attr :heading, :string, default: "h2"
  attr :class, :any, default: nil

  def terms_of_sale(assigns) do
    ~H"""
    <div class={["terms-of-sale space-y-7 text-[1rem]", @class]}>
      <section>
        <.dynamic_tag tag_name={@heading} class="terms-heading">Authenticity</.dynamic_tag>
        <p class="mt-1.5">
          Every print is guaranteed authentic and as described. We take great care to describe each
          print accurately, including its condition. If, when your purchase arrives, you can show that
          a print is not as described, we will refund your payment in full.
        </p>
      </section>

      <section>
        <.dynamic_tag tag_name={@heading} class="terms-heading">Prints on approval</.dynamic_tag>
        <p class="mt-1.5">
          We are happy to send prints on approval to clients we know, or who can give us references,
          for a period of ten days after receipt.
        </p>
      </section>

      <section>
        <.dynamic_tag tag_name={@heading} class="terms-heading">Packing and shipping</.dynamic_tag>
        <p class="mt-1.5">
          Packing, shipping, and Customs fees or duties, if any, are charged in addition to the price of
          the print. Packages are usually sent by Federal Express.
        </p>
      </section>

      <section>
        <.dynamic_tag tag_name={@heading} class="terms-heading">Payment</.dynamic_tag>
        <p class="mt-1.5">
          We accept cheques and wire transfers in US dollars. We expect to begin accepting credit cards
          during 2027.
        </p>
      </section>

      <section>
        <.dynamic_tag tag_name={@heading} class="terms-heading">Canadian clients</.dynamic_tag>
        <p class="mt-1.5">
          Prices can be converted to Canadian dollars for immediate payments. HST, or GST and provincial
          sales tax, will be added.
        </p>
      </section>
    </div>
    """
  end

  @doc "Search box for artist names and print titles; submits to the print list."
  attr :value, :string, default: ""
  attr :class, :any, default: nil
  attr :id, :string, default: "search-form"
  attr :rest, :global, doc: "LiveView bindings such as phx-change and phx-submit"

  def search_form(assigns) do
    ~H"""
    <form
      id={@id}
      action={~p"/prints"}
      method="get"
      role="search"
      class={["flex", @class]}
      {@rest}
    >
      <label class="input flex-1 rounded-r-none">
        <span class="sr-only">Search by artist or title</span>
        <input
          id={"#{@id}-input"}
          type="search"
          name="q"
          value={@value}
          phx-debounce="250"
          placeholder="Search by artist or title"
          autocomplete="off"
          class="grow"
        />
      </label>
      <button
        type="submit"
        class="btn rounded-l-none border-2 border-rose bg-rose-tint font-semibold text-rose shadow-none hover:border-rose-2 hover:bg-rose-tint hover:text-rose-2"
      >
        Search
      </button>
    </form>
    """
  end

  @doc "A small Sold or Reserved label; renders nothing for available prints."
  attr :status, :string, required: true
  attr :class, :any, default: nil

  def status_badge(assigns) do
    ~H"""
    <span
      :if={@status in ["sold", "reserved"]}
      class={["block text-xs font-semibold uppercase tracking-[0.12em] text-sold", @class]}
    >
      {@status}
    </span>
    """
  end

  @doc """
  "From the stock": a grid of featured prints under a heading. No longer shown
  on the homepage; to bring it back, add this to `home.html.heex`:

      <.from_the_stock prints={JanPaintings.Catalog.featured_prints()} />
  """
  attr :prints, :list, required: true

  def from_the_stock(assigns) do
    ~H"""
    <section class="mt-12 md:mt-16">
      <h2 class="type-h2 border-b border-rule pb-3">From the stock</h2>
      <div class="print-grid mt-8">
        <.print_card :for={print <- @prints} print={print} />
      </div>
    </section>
    """
  end

  @doc """
  A print in a grid: the print on a 4:5 mat (never cropped), then the artist,
  title and medium. Links to the print's detail page.
  """
  attr :print, :map, required: true

  def print_card(assigns) do
    ~H"""
    <%!-- The id is the anchor the print page's back link returns to; the
         scroll margin keeps the card clear of the sticky menu bar. --%>
    <.link
      id={"print-#{@print.slug}"}
      navigate={~p"/prints/#{@print.category}/#{@print.slug}"}
      class="group flex min-w-0 scroll-mt-20 flex-col"
    >
      <div class="mat flex aspect-[4/5] items-center justify-center p-4">
        <img
          src={Catalog.image_url(@print.image)}
          alt={"#{@print.artist}, #{@print.title}"}
          loading="lazy"
          class={[
            "max-h-full max-w-full object-contain",
            @print.status == "sold" && "opacity-85"
          ]}
        />
      </div>
      <.status_badge status={@print.status} class="mt-2" />
      <p class={[
        "type-artist truncate",
        if(@print.status in ["sold", "reserved"], do: "mt-0.5", else: "mt-2")
      ]}>
        {@print.artist}
      </p>
      <p class="mt-1 line-clamp-3 font-serif text-lg leading-snug decoration-rose decoration-1 underline-offset-3 group-hover:underline">
        {@print.title}
      </p>
      <p :if={@print.medium != ""} class="type-meta mt-1">{@print.medium}</p>
    </.link>
    """
  end
end
