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

  @doc "Absolute URL for an image path stored in the catalogue."
  def image_url(path), do: @image_host <> URI.encode(path)
end
