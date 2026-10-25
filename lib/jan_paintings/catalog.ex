defmodule JanPaintings.Catalog do
  @moduledoc """
  The print catalogue, stored in the `prints` table.

  The stock was first scraped from the "Selected Stock" pages of
  janjohnsonprints.com into `priv/data/prints.json`, which a migration loads
  once; after that, prints are managed from the admin pages. Images copied
  from that site (colour-corrected where the photo had a yellow cast) are
  served from priv/static/images/catalogue.
  """

  import Ecto.Query

  alias JanPaintings.Catalog.Print
  alias JanPaintings.Repo

  @categories [
    %{
      slug: "old-masters",
      banner: "/images/catalogue/new-banner-old-masters.jpg",
      name: "Old Master Prints",
      short: "Old Masters",
      blurb:
        "Engravings, etchings, woodcuts and mezzotints from the fifteenth to the eighteenth century."
    },
    %{
      slug: "modern",
      banner: "/images/catalogue/new-banner-mods.jpg",
      name: "Modern Prints",
      short: "Modern",
      blurb: "European printmaking of the nineteenth and early twentieth centuries."
    },
    %{
      slug: "canadian",
      banner: "/images/catalogue/new-banner-canadians.jpg",
      name: "Canadian Prints",
      short: "Canadian",
      blurb:
        "Etchings, woodcuts and linocuts by Canadian printmakers of the early twentieth century."
    }
  ]

  def categories, do: @categories

  def get_category(slug), do: Enum.find(@categories, &(&1.slug == slug))

  @doc "Header banner image for a category, falling back to the Old Masters banner."
  def banner_url(category_slug) do
    category = get_category(category_slug) || hd(@categories)
    image_url(category.banner)
  end

  @doc """
  The prints on the public site, grouped by category in menu order, then by
  artist and title. Drafts are left out; `list_all_prints/0` includes them.
  """
  def list_prints, do: published() |> Repo.all() |> sort()

  @doc "Prints on the public site in one category, by artist and title."
  def list_prints(category_slug) do
    from(p in published(), where: p.category == ^category_slug) |> Repo.all() |> sort()
  end

  @doc "Every print, drafts included, for the admin pages."
  def list_all_prints, do: Print |> Repo.all() |> sort()

  @doc "A print by slug, whatever its status."
  def get_print(slug), do: Repo.get_by(Print, slug: slug)

  @doc "A print by slug, or nil when there is none or it is a draft."
  def get_public_print(slug), do: Repo.get_by(published(), slug: slug)

  defp published, do: from(p in Print, where: p.status != "draft")

  @doc """
  Keeps the prints whose artist has the given nationality key, such as
  `"french"`. A nil or blank key keeps them all.
  """
  def filter_nationality(prints, nationality) when nationality in [nil, ""], do: prints

  def filter_nationality(prints, nationality),
    do: Enum.filter(prints, &(&1.nationality == nationality))

  # Sorted in Elixir so accented names ("DORÉ") sort with their plain letters.
  defp sort(prints) do
    order = @categories |> Enum.map(& &1.slug) |> Enum.with_index() |> Map.new()

    Enum.sort_by(
      prints,
      &{Map.get(order, &1.category, 99), fold(&1.artist), fold(plain_title(&1.title))}
    )
  end

  ## Admin

  def get_print!(id), do: Repo.get!(Print, id)

  def change_print(%Print{} = print, attrs \\ %{}) do
    Print.changeset(print, attrs, Enum.map(@categories, & &1.slug))
  end

  def create_print(attrs) do
    %Print{} |> change_print(attrs) |> Repo.insert()
  end

  def update_print(%Print{} = print, attrs) do
    print |> change_print(attrs) |> Repo.update()
  end

  @doc "Sets a print's status: \"available\", \"sold\", \"reserved\" or \"draft\"."
  def set_status(%Print{} = print, status) do
    update_print(print, %{"status" => status})
  end

  def delete_print(%Print{} = print), do: Repo.delete(print)

  @doc """
  Every image of a print for its detail page gallery: the main image first,
  then any additional sheets or states. Each view has a display `src` and a
  `large` URL for the "View larger" link.
  """
  def views(print) do
    main = %{
      src: image_url(print.image),
      large: image_url(large_or(print.large_image, print.image))
    }

    [main | Enum.map(print.gallery, &%{src: image_url(&1), large: image_url(&1)})]
  end

  defp large_or("", image), do: image
  defp large_or(large, _image), do: large

  @doc """
  Other prints by the same artist as `print`, in catalogue order.

  Artists are matched on surname plus first given name, so "ARMINGTON,
  Caroline" and "ARMINGTON, Frank" stay apart, while qualifiers such as
  "GHISI, Giorgio, attributed to" still match "GHISI, Giorgio".
  """
  def more_by_artist(print) do
    key = artist_key(print.artist)
    Enum.filter(list_prints(), &(&1.slug != print.slug && artist_key(&1.artist) == key))
  end

  @doc """
  Search terms that find every print by `print`'s artist on the print list.

  Uses the same surname plus first given name as `more_by_artist/1`, so
  "BONNET, Louis-Marin direxit" gives "BONNET Louis", which also finds
  "BONNET, Louis-Marin".
  """
  def artist_query(print) do
    {surname, first_given} = artist_name(print.artist)
    Enum.join([surname | List.wrap(first_given)], " ")
  end

  defp artist_key(artist) do
    {surname, first_given} = artist_name(artist)
    {fold(surname), first_given && fold(first_given)}
  end

  defp artist_name(artist) do
    cleaned = String.replace(artist, ~r/\(.*?\)/, " ")

    {surname, given} =
      case String.split(cleaned, ",", parts: 2) do
        [surname, given] -> {surname, given}
        [single] -> single |> String.split(" ", parts: 2, trim: true) |> List.to_tuple() |> pad()
      end

    first_given = given |> String.split(~r/[^\p{L}]+/u, trim: true) |> List.first()
    {String.trim(surname), first_given}
  end

  defp pad({surname}), do: {surname, ""}
  defp pad(pair), do: pair

  @doc """
  Filters prints to those whose artist or title contains every word of the query.

  Matching ignores case and accents, so "dore" finds "DORÉ". A blank query
  returns the prints unchanged.
  """
  def search(prints, query) when is_binary(query) do
    case query |> fold() |> String.split(~r/[^\p{L}\p{N}]+/u, trim: true) do
      [] ->
        prints

      terms ->
        Enum.filter(prints, fn print ->
          haystack = fold(print.artist <> " " <> plain_title(print.title))
          Enum.all?(terms, &String.contains?(haystack, &1))
        end)
    end
  end

  def search(prints, _query), do: prints

  defp fold(text) do
    text
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
  end

  @doc "A spread of prints across the catalogue for the homepage, excluding category covers."
  def featured_prints do
    prints = list_prints()
    covers = Enum.map(@categories, fn c -> first_with_medium(prints, c.slug) end)

    prints
    |> Enum.filter(&(&1.medium != "" && &1 not in covers))
    |> Enum.take_every(17)
    |> Enum.take(6)
  end

  @doc "A representative print for a category, used on category cards."
  def cover_print(category_slug) do
    category_slug |> list_prints() |> first_with_medium(category_slug)
  end

  defp first_with_medium(prints, category_slug) do
    Enum.find(prints, &(&1.category == category_slug && &1.medium != ""))
  end

  @italic ~r/\*([^*\n]+)\*/

  @doc """
  A print title split into plain and italic parts. In the stored title a book
  or series title is marked with asterisks, as in `plate VIII from *La défense
  et l'attaque des petites postes*`; a lone asterisk is kept as it is.

      iex> JanPaintings.Catalog.title_parts("Plate 4 from *Souvenirs*, 1830")
      [{:plain, "Plate 4 from "}, {:italic, "Souvenirs"}, {:plain, ", 1830"}]
  """
  def title_parts(title) do
    @italic
    |> Regex.split(title, include_captures: true, trim: true)
    |> Enum.map(fn part ->
      case Regex.run(@italic, part) do
        [^part, inner] -> {:italic, inner}
        _ -> {:plain, part}
      end
    end)
  end

  @doc """
  A print title without its italic markers, for places that can only show plain
  text: page titles, image alt text, emails, structured data and sorting.

      iex> JanPaintings.Catalog.plain_title("Plate 4 from *Souvenirs*")
      "Plate 4 from Souvenirs"
  """
  def plain_title(title), do: Regex.replace(@italic, title, "\\1")

  @doc "URL for an image path stored in the catalogue. All images are served by this site."
  def image_url("/" <> _ = path), do: path
end
