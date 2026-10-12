defmodule JanPaintings.Catalog do
  @moduledoc """
  Read-only print catalogue, compiled from `priv/data/prints.json`.

  The data was scraped from the "Selected Stock" pages of janjohnsonprints.com.
  Images are served from that site, so only relative paths are stored here.
  """

  @image_host "https://janjohnsonprints.com/"

  @categories [
    %{
      slug: "old-masters",
      banner: "images/New banner Old Masters.jpg",
      name: "Old Master Prints",
      short: "Old Masters",
      blurb:
        "Engravings, etchings, woodcuts and mezzotints from the fifteenth to the eighteenth century."
    },
    %{
      slug: "modern",
      banner: "images/New banner Mods.jpg",
      name: "Modern Prints",
      short: "Modern",
      blurb: "European printmaking of the nineteenth and early twentieth centuries."
    },
    %{
      slug: "canadian",
      banner: "images/New banner Canadians.jpg",
      name: "Canadian Prints",
      short: "Canadian",
      blurb:
        "Etchings, woodcuts and linocuts by Canadian printmakers of the early twentieth century."
    }
  ]

  @data_path Path.join(:code.priv_dir(:jan_paintings), "data/prints.json")
  @external_resource @data_path

  @prints @data_path
          |> File.read!()
          |> Jason.decode!(keys: :atoms)

  def categories, do: @categories

  def get_category(slug), do: Enum.find(@categories, &(&1.slug == slug))

  @doc "Header banner image for a category, falling back to the Old Masters banner."
  def banner_url(category_slug) do
    category = get_category(category_slug) || hd(@categories)
    image_url(category.banner)
  end

  def list_prints, do: @prints

  def list_prints(category_slug), do: Enum.filter(@prints, &(&1.category == category_slug))

  def get_print(slug), do: Enum.find(@prints, &(&1.slug == slug))

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
    Enum.filter(@prints, &(&1.slug != print.slug && artist_key(&1.artist) == key))
  end

  defp artist_key(artist) do
    folded = artist |> String.replace(~r/\(.*?\)/, " ") |> fold()

    {surname, given} =
      case String.split(folded, ",", parts: 2) do
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
          haystack = fold(print.artist <> " " <> print.title)
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
    covers = Enum.map(@categories, &cover_print(&1.slug))

    @prints
    |> Enum.filter(&(&1.medium != "" && &1 not in covers))
    |> Enum.take_every(17)
    |> Enum.take(6)
  end

  @doc "A representative print for a category, used on category cards."
  def cover_print(category_slug) do
    Enum.find(@prints, &(&1.category == category_slug && &1.medium != ""))
  end

  @doc """
  URL for an image path stored in the catalogue.

  Paths starting with "/" are images served by this site (for example
  colour-corrected photos in priv/static/images/prints); anything else is
  still loaded from the original site.
  """
  def image_url("/" <> _ = local_path), do: local_path
  def image_url(path), do: @image_host <> URI.encode(path)
end
