defmodule JanPaintingsWeb.SEO do
  @moduledoc """
  Search and sharing metadata: page titles, meta descriptions, canonical and
  Open Graph tags, and schema.org JSON-LD.

  Pages set any of these assigns, and the root layout renders them through
  `head_tags/1`, falling back to site-wide defaults:

    * `:page_title` - shown before the site name in the title.
    * `:meta_description` - plain text, about 155 characters.
    * `:canonical_path` - path of the page's canonical URL (defaults to the
      request path without its query string).
    * `:og_image` - site path of the image used when the page is shared.
    * `:og_type` - Open Graph type, "website" by default.
    * `:json_ld` - a map (or list of maps) rendered as JSON-LD.

  Absolute URLs use the endpoint's configured URL (PHX_HOST in production),
  so they always point at the canonical host.
  """
  use Phoenix.Component

  alias JanPaintings.Catalog

  @site_name "Jan Johnson Old Master & Modern Prints"
  @default_title "Jan Johnson · Old Master, Modern & Canadian Prints"
  @default_description "Fine Old Master, nineteenth- and early twentieth-century European and Canadian prints, offered by Jan Johnson since 1979. Viewing by appointment in Chambly, near Montreal."
  @default_image "/images/catalogue/pether-farrier-s-shop-lg.jpg"

  def site_name, do: @site_name

  @doc "Absolute URL on the canonical host for a site path."
  def url(path), do: JanPaintingsWeb.Endpoint.url() <> path

  ## Head tags

  attr :assigns, :map, required: true, doc: "the root layout's assigns"

  @doc "Renders description, canonical, Open Graph, Twitter and JSON-LD tags."
  def head_tags(%{assigns: page} = assigns) do
    title = if page[:page_title], do: "#{page[:page_title]} · #{@site_name}", else: @default_title

    assigns =
      assign(assigns,
        title: title,
        description: page[:meta_description] || @default_description,
        canonical: url(page[:canonical_path] || request_path(page[:conn])),
        image: url(page[:og_image] || @default_image),
        og_type: page[:og_type] || "website",
        json_ld: page[:json_ld]
      )

    ~H"""
    <meta name="description" content={@description} />
    <link rel="canonical" href={@canonical} />
    <meta property="og:site_name" content={site_name()} />
    <meta property="og:title" content={@title} />
    <meta property="og:description" content={@description} />
    <meta property="og:type" content={@og_type} />
    <meta property="og:url" content={@canonical} />
    <meta property="og:image" content={@image} />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={@title} />
    <meta name="twitter:description" content={@description} />
    <meta name="twitter:image" content={@image} />
    <script :if={@json_ld} type="application/ld+json">
      <%= json_ld(@json_ld) %>
    </script>
    """
  end

  @doc "The default title, used when a page sets no `:page_title`."
  def default_title, do: @default_title

  @doc "The title suffix added after a page's `:page_title`."
  def title_suffix, do: " · " <> @site_name

  defp request_path(%Plug.Conn{request_path: path}), do: path
  defp request_path(_), do: "/"

  @doc """
  Encodes JSON-LD for a `<script>` tag. `:html_safe` escaping turns `<`, `>`
  and `/` into `\\u003c`-style escapes, so text such as "</script>" in the
  data can never close the tag early.
  """
  def json_ld(data) do
    data |> Jason.encode!(escape: :html_safe) |> Phoenix.HTML.raw()
  end

  ## Gallery

  @doc "schema.org ArtGallery (a LocalBusiness) for the home and about pages."
  def gallery_json_ld do
    %{
      "@context" => "https://schema.org",
      "@type" => "ArtGallery",
      "@id" => url("/#gallery"),
      "name" => "Jan Johnson, Old Master & Modern Prints Inc.",
      "url" => url("/"),
      "logo" => url("/images/jan-johnson-logo.png"),
      "image" => url(@default_image),
      "email" => "jan@janjohnsonprints.com",
      "telephone" => "+1-450-658-2752",
      "foundingDate" => "1979",
      "address" => %{
        "@type" => "PostalAddress",
        "streetAddress" => "189 rue Saint-Pierre",
        "addressLocality" => "Chambly",
        "addressRegion" => "QC",
        "postalCode" => "J3L 1L8",
        "addressCountry" => "CA"
      }
    }
  end

  defp gallery_ref,
    do: %{"@type" => "ArtGallery", "@id" => url("/#gallery"), "name" => @site_name}

  ## Category and listing pages

  @doc "schema.org CollectionPage with an ItemList of the prints shown."
  def collection_json_ld(name, description, path, prints) do
    %{
      "@context" => "https://schema.org",
      "@type" => "CollectionPage",
      "name" => name,
      "description" => description,
      "url" => url(path),
      "isPartOf" => %{"@type" => "WebSite", "name" => @site_name, "url" => url("/")},
      "mainEntity" => %{
        "@type" => "ItemList",
        "numberOfItems" => length(prints),
        "itemListElement" =>
          prints
          |> Enum.with_index(1)
          |> Enum.map(fn {print, position} ->
            %{
              "@type" => "ListItem",
              "position" => position,
              "url" => url(print_path(print)),
              "name" => "#{artist_name(print.artist)}, #{Catalog.plain_title(print.title)}"
            }
          end)
      }
    }
  end

  ## Prints

  def print_path(print), do: "/prints/#{print.category}/#{print.slug}"

  @doc """
  Page title for a print: "{artist}, {title}, {medium and date}", leaving out
  missing parts. The site name is appended by the layout.
  """
  def print_title(print) do
    [artist_name(print.artist), Catalog.plain_title(print.title), print.medium]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(", ")
  end

  @doc "Meta description for a print, from its description, about 155 characters."
  def print_description(print) do
    body =
      [print.details, print.condition]
      |> Enum.find("", &(&1 not in [nil, ""]))

    truncate("#{artist_name(print.artist)}, #{Catalog.plain_title(print.title)}. #{body}", 155)
  end

  @doc "schema.org VisualArtwork + Product node for a print's page."
  def print_json_ld(print) do
    {height, width} = dimensions_mm(print.dimensions)

    %{
      "@context" => "https://schema.org",
      "@type" => ["VisualArtwork", "Product"],
      "@id" => url(print_path(print)) <> "#print",
      "name" => Catalog.plain_title(print.title),
      "url" => url(print_path(print)),
      "image" => url(Catalog.image_url(print.image)),
      "description" => print_description(print),
      "artform" => "Print",
      "artMedium" => medium_without_date(print.medium),
      "dateCreated" => year_created(print.medium),
      "creator" => creator(print),
      "height" => height && quantity(height),
      "width" => width && quantity(width),
      "citation" => catalogue_citation(print),
      "offers" => offers(print)
    }
    |> reject_nils()
  end

  defp creator(print) do
    {born, died} = life_dates(print.dates)

    reject_nils(%{
      "@type" => "Person",
      "name" => artist_name(print.artist),
      "birthDate" => born,
      "deathDate" => died
    })
  end

  defp quantity(mm), do: %{"@type" => "QuantitativeValue", "value" => mm, "unitCode" => "MMT"}

  defp offers(print) do
    base = %{
      "url" => url(print_path(print)),
      "availability" => availability(print.status),
      "seller" => gallery_ref()
    }

    case prices(print.price) do
      [] ->
        Map.put(base, "@type", "Offer")

      [{amount, currency}] ->
        Map.merge(base, %{"@type" => "Offer", "price" => amount, "priceCurrency" => currency})

      [{_, currency} | _] = several ->
        amounts = Enum.map(several, &elem(&1, 0))
        by_value = &(&1 |> Float.parse() |> elem(0))

        Map.merge(base, %{
          "@type" => "AggregateOffer",
          "lowPrice" => Enum.min_by(amounts, by_value),
          "highPrice" => Enum.max_by(amounts, by_value),
          "offerCount" => length(amounts),
          "priceCurrency" => currency
        })
    end
  end

  defp availability("sold"), do: "https://schema.org/SoldOut"
  defp availability("reserved"), do: "https://schema.org/LimitedAvailability"
  defp availability(_), do: "https://schema.org/InStock"

  @doc ~S"""
  Amounts in a price string, such as "$1,500 USD" or "Working Proof 1 $2,000
  USD · First state $1,500 USD", as `{amount, currency}` pairs. "On request"
  and other text without an amount give `[]`.
  """
  def prices(price) do
    ~r/\$\s?([\d,]+(?:\.\d\d)?)\s*(USD|CAD)/
    |> Regex.scan(price || "")
    |> Enum.map(fn [_, amount, currency] -> {String.replace(amount, ",", ""), currency} end)
  end

  @doc ~S"""
  Height and width in millimetres from a size such as "206 × 160mm" or
  "20.6 x 16 cm", or `{nil, nil}`.
  """
  def dimensions_mm(text) do
    case Regex.run(~r/(\d+(?:\.\d+)?)\s*[x×]\s*(\d+(?:\.\d+)?)\s*(mm|cm)/iu, text || "") do
      [_, h, w, unit] -> {to_mm(h, unit), to_mm(w, unit)}
      nil -> {nil, nil}
    end
  end

  defp to_mm(value, unit) do
    {number, _} = Float.parse(value)
    mm = if String.downcase(unit) == "cm", do: number * 10, else: number
    if mm == trunc(mm), do: trunc(mm), else: mm
  end

  @doc ~S"""
  Birth and death years from the artist's dates, such as "1520–82" ->
  {"1520", "1582"}. Uncertain dates ("1530?–98", "1561–c.1604") give nils.
  """
  def life_dates(dates) do
    case Regex.run(~r/^(\d{4})\s*[–-]\s*(\d{2,4})$/u, String.trim(dates || "")) do
      [_, born, died] ->
        died =
          if byte_size(died) < 4,
            do: String.slice(born, 0, 4 - byte_size(died)) <> died,
            else: died

        {born, died}

      nil ->
        {nil, nil}
    end
  end

  @doc "The first year in the medium line (\"Engraving, 1548\" -> \"1548\"), or nil."
  def year_created(medium) do
    case Regex.run(~r/\b(1[3-9]\d\d|20\d\d)\b/, medium || "") do
      [_, year] -> year
      nil -> nil
    end
  end

  defp medium_without_date(medium) do
    medium =
      (medium || "") |> String.replace(~r/,?\s*((c\.|ca\.?|circa|before|after)\s*)?\d{4}.*$/i, "")

    if medium == "", do: nil, else: medium
  end

  # Prefer the catalogue references field; older records may only have them
  # inside the details line.
  @catalogues ~r/Bartsch|Hollstein|TIB|Hind|Lugt|Delteil|Béraldi|Dodgson|Le ?Blanc|Nagler|Passavant|Heller|Andresen|Meyer|Wentworth|Godefroy|Guérin|Inventaire/u
  defp catalogue_citation(%{catalogue_references: refs}) when refs not in [nil, ""], do: refs

  defp catalogue_citation(%{details: details}) do
    if details && Regex.match?(@catalogues, details), do: details
  end

  @doc ~S"""
  The artist as "Given names Surname" from the catalogue's "SURNAME, Given
  names" form, keeping qualifiers: "GHISI, Giorgio, attributed to" ->
  "Giorgio Ghisi (attributed to)".
  """
  def artist_name(artist) do
    case String.split(artist || "", ",", parts: 3) |> Enum.map(&String.trim/1) do
      [surname, given, qualifier] -> "#{given} #{surname_case(surname)} (#{qualifier})"
      [surname, given] -> "#{given} #{surname_case(surname)}"
      [name] -> surname_case(name)
    end
  end

  @particles ~w(van von de der den di da du le la ter)
  defp surname_case(surname) do
    surname
    |> String.split(~r/(\s+|-)/, include_captures: true)
    |> Enum.with_index()
    |> Enum.map_join(fn {word, index} ->
      lower = String.downcase(word)

      cond do
        word =~ ~r/^(\s+|-)$/ -> word
        index > 0 and lower in @particles -> lower
        true -> capitalize_name(lower)
      end
    end)
  end

  # "o'neil" -> "O'Neil", "mcardell" -> "McArdell"
  defp capitalize_name("mc" <> rest) when rest != "", do: "Mc" <> String.capitalize(rest)

  defp capitalize_name(word) do
    word
    |> String.split("'")
    |> Enum.map_join("'", &String.capitalize/1)
  end

  @doc "Shortens text to at most `max` characters at a word boundary, adding an ellipsis."
  def truncate(text, max) do
    text = text |> String.replace(~r/\s+/u, " ") |> String.trim()

    if String.length(text) <= max do
      text
    else
      cut = String.slice(text, 0, max - 1)
      cut = Regex.replace(~r/\s+\S*$/u, cut, "")
      String.trim_trailing(cut, " ,;:.") <> "…"
    end
  end

  defp reject_nils(map), do: map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
end
