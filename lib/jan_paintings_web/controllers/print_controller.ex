defmodule JanPaintingsWeb.PrintController do
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog
  alias JanPaintingsWeb.SEO

  def show(conn, %{"category" => category_slug, "slug" => slug}) do
    category = Catalog.get_category(category_slug) || raise_not_found()
    print = Catalog.get_public_print(slug)

    if is_nil(print) or print.category != category.slug, do: raise_not_found()

    render(conn, :show,
      page_title: SEO.print_title(print),
      meta_description: SEO.print_description(print),
      canonical_path: SEO.print_path(print),
      og_image: print.image,
      og_type: "product",
      json_ld: SEO.print_json_ld(print),
      category: category,
      print: print,
      views: Catalog.views(print),
      enlargeable?: print.large_image != "" or print.gallery != [],
      # One paragraph per blank-line-separated block of the additional notes.
      notes: String.split(print.additional_notes, ~r/\n\s*\n/, trim: true),
      more_by_artist?: Catalog.more_by_artist(print) != []
    )
  end

  defp raise_not_found, do: raise(JanPaintingsWeb.NotFoundError)
end
