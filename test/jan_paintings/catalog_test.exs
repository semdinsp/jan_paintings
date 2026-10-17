defmodule JanPaintings.CatalogTest do
  use JanPaintings.DataCase, async: true

  alias JanPaintings.Catalog

  # Distinct prints on the original janjohnsonprints.com site, including those
  # reachable only through its "more by this artist" pages.
  test "matches the print count of the original site" do
    assert length(Catalog.list_prints()) == 180
    assert length(Catalog.list_prints("old-masters")) == 89
    assert length(Catalog.list_prints("modern")) == 54
    assert length(Catalog.list_prints("canadian")) == 37
  end

  test "every print has a unique slug, an artist, a title and an image" do
    prints = Catalog.list_prints()
    assert prints |> Enum.map(& &1.slug) |> Enum.uniq() |> length() == length(prints)

    for print <- prints do
      assert print.artist != "", "#{print.slug} has no artist"
      assert print.title != "", "#{print.slug} has no title"
      assert print.image != "", "#{print.slug} has no image"
    end
  end

  test "available prints have a price; sold and reserved ones match the original site" do
    by_status = Enum.group_by(Catalog.list_prints(), & &1.status)

    assert length(by_status["sold"]) == 7
    assert length(by_status["reserved"]) == 2
    assert Enum.all?(by_status["available"], &(&1.price != ""))

    for %{category: "canadian", status: "available", price: price} <- Catalog.list_prints() do
      assert price =~ "CAD"
    end
  end

  describe "search/2" do
    test "matches artist names and titles, ignoring case and accents" do
      prints = Catalog.list_prints()

      assert [%{slug: "dusart-fiddler-in-an-inn"}] = Catalog.search(prints, "fiddler")
      assert Enum.all?(Catalog.search(prints, "neilson"), &(&1.artist =~ "NEILSON"))
      assert Catalog.search(prints, "dore") |> Enum.any?(&(&1.artist =~ "DORÉ"))
      assert Catalog.search(prints, "morpoue") |> Enum.any?(&(&1.title =~ "Morpoué"))
    end

    test "requires every word to match" do
      prints = Catalog.list_prints()

      assert [print] = Catalog.search(prints, "tissot prodigal")
      assert print.artist =~ "TISSOT"
      assert Catalog.search(prints, "tissot zebra") == []
    end

    test "returns everything for a blank query" do
      prints = Catalog.list_prints()
      assert Catalog.search(prints, "  ") == prints
      assert Catalog.search(prints, nil) == prints
    end
  end

  describe "more_by_artist/1" do
    test "lists the artist's other prints" do
      print = Catalog.get_print("neilson-dredging-the-st-charles-river")
      others = Catalog.more_by_artist(print)

      assert length(others) == 3
      assert Enum.all?(others, &(&1.artist =~ "NEILSON"))
      refute print in others
    end

    test "keeps different artists with the same surname apart" do
      print = Catalog.get_print("armington-the-mosque-on-the-mount-of-olives")
      assert Catalog.more_by_artist(print) == []
    end

    test "ignores qualifiers such as 'attributed to'" do
      print = Catalog.get_print("ghisi-the-visitation-after-francesco-salviati")
      assert [%{artist: "GHISI, Giorgio, attributed to"}] = Catalog.more_by_artist(print)
    end
  end

  test "includes the Tiepolo prints from the original site's more-by-artist pages" do
    tiepolo = Catalog.list_prints() |> Enum.filter(&(&1.artist =~ "TIEPOLO"))
    assert length(tiepolo) == 3
  end

  test "every catalogue image is served by this site and exists on disk" do
    static = Path.join(:code.priv_dir(:jan_paintings), "static")

    paths =
      Enum.map(Catalog.categories(), & &1.banner) ++
        Enum.flat_map(Catalog.list_prints(), fn print ->
          Enum.reject([print.thumb, print.image, print.large_image], &(&1 == "")) ++ print.gallery
        end)

    for path <- paths do
      assert Catalog.image_url(path) == path
      assert File.exists?(Path.join(static, path)), "missing #{path}"
    end
  end

  describe "order_prints/2" do
    test "orders by price, lowest first, with unpriced prints last" do
      ordered = Catalog.order_prints(Catalog.list_prints(), "price")
      {priced, unpriced} = Enum.split_while(ordered, & &1.price_amount)

      assert Enum.map(priced, & &1.price_amount) == Enum.sort(Enum.map(priced, & &1.price_amount))
      assert unpriced != []
      assert Enum.all?(unpriced, &is_nil(&1.price_amount))
    end

    test "orders by plate area, smallest first, with unsized prints last" do
      ordered = Catalog.order_prints(Catalog.list_prints(), "size")
      {sized, unsized} = Enum.split_while(ordered, & &1.height_mm)
      areas = Enum.map(sized, &(&1.height_mm * &1.width_mm))

      assert areas == Enum.sort(areas)
      assert unsized != []
      assert Enum.all?(unsized, &is_nil(&1.height_mm))
    end

    test "keeps the usual order for no sort or an unknown one" do
      prints = Catalog.list_prints()
      assert Catalog.order_prints(prints, nil) == prints
      assert Catalog.order_prints(prints, "colour") == prints
    end
  end

  test "the stock's prices and sizes were read into sort fields" do
    prints = Catalog.list_prints()

    for print <- prints, String.contains?(print.price, "$") do
      assert print.price_amount, "no price amount for #{print.slug}: #{print.price}"
    end

    for print <- prints, print.dimensions != "" do
      assert print.height_mm && print.width_mm, "no size for #{print.slug}: #{print.dimensions}"
      assert print.dimensions =~ ~r/^\d+ × \d+mm$/
    end
  end

  describe "managing prints" do
    @valid %{
      "category" => "canadian",
      "artist" => "LEDUC, Ozias",
      "dates" => "1864–1955",
      "title" => "Neige dorée",
      "image" => "/uploads/prints/neige.jpg",
      "price" => "$900 CAD",
      "details" => ""
    }

    test "create_print/1 builds a slug from the surname and title" do
      assert {:ok, print} = Catalog.create_print(@valid)
      assert print.slug == "leduc-neige-doree"
      assert print.status == "available"
      assert print.details == ""
      assert print.gallery == []
      assert Catalog.get_print("leduc-neige-doree").id == print.id
      assert print in Catalog.list_prints("canadian")
    end

    test "create_print/1 and update_print/2 keep the sort fields in step with the text" do
      assert {:ok, print} = Catalog.create_print(Map.put(@valid, "dimensions", "260 x356 mm"))
      assert {print.price_amount, print.price_currency} == {900, "CAD"}
      assert {print.height_mm, print.width_mm} == {260, 356}
      assert print.dimensions == "260 × 356mm"

      assert {:ok, print} =
               Catalog.update_print(print, %{"price" => "On request", "dimensions" => ""})

      assert {print.price_amount, print.price_currency, print.height_mm, print.width_mm} ==
               {nil, nil, nil, nil}
    end

    test "create_print/1 validates the required fields, category and status" do
      assert {:error, changeset} =
               Catalog.create_print(%{"category" => "sculpture", "status" => "lost"})

      errors = errors_on(changeset)
      assert errors.artist == ["can't be blank"]
      assert errors.title == ["can't be blank"]
      assert errors.image == ["add an image"]
      assert errors.category == ["is invalid"]
      assert errors.status == ["is invalid"]
    end

    test "create_print/1 rejects a duplicate or malformed slug" do
      existing = hd(Catalog.list_prints())

      assert {:error, changeset} = Catalog.create_print(Map.put(@valid, "slug", existing.slug))
      assert errors_on(changeset).slug == ["has already been taken"]

      assert {:error, changeset} = Catalog.create_print(Map.put(@valid, "slug", "Not A Slug"))
      assert errors_on(changeset).slug == ["use lower-case letters, numbers and dashes"]
    end

    test "update_print/2 and set_status/2 change a print" do
      print = Catalog.get_print("neilson-dredging-the-st-charles-river")

      assert {:ok, print} =
               Catalog.update_print(print, %{"price" => "$1,000 CAD", "watermark" => ""})

      assert print.price == "$1,000 CAD"
      assert {:ok, %{status: "sold"}} = Catalog.set_status(print, "sold")
      assert {:error, _} = Catalog.set_status(print, "stolen")
    end

    test "delete_print/1 removes it from the catalogue" do
      print = Catalog.get_print("neilson-dredging-the-st-charles-river")
      assert {:ok, _} = Catalog.delete_print(print)
      refute Catalog.get_print(print.slug)
    end
  end
end
