defmodule JanPaintings.CatalogTest do
  use JanPaintings.DataCase, async: true

  alias JanPaintings.Catalog
  alias JanPaintings.Catalog.Print

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

  describe "artist_query/1" do
    test "is the surname and first given name" do
      assert Catalog.artist_query(%{artist: "BONNET, Louis-Marin direxit"}) == "BONNET Louis"
      assert Catalog.artist_query(%{artist: "GHISI, Giorgio, attributed to"}) == "GHISI Giorgio"
      assert Catalog.artist_query(%{artist: "NEILSON"}) == "NEILSON"
    end

    test "finds the print and all of its more-by-artist prints" do
      prints = Catalog.list_prints()

      for print <- prints do
        found = Catalog.search(prints, Catalog.artist_query(print))
        assert print in found
        assert Enum.all?(Catalog.more_by_artist(print), &(&1 in found)), print.slug
      end
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

  describe "filter_nationality/2" do
    test "keeps only prints with that nationality; nil or blank keeps all" do
      [a, b | _] = prints = Catalog.list_prints()
      {:ok, _} = Catalog.update_print(a, %{"nationality" => "french"})
      {:ok, _} = Catalog.update_print(b, %{"nationality" => "italian"})
      prints = Enum.map(prints, &Catalog.get_print(&1.slug))

      assert Enum.map(Catalog.filter_nationality(prints, "french"), & &1.slug) == [a.slug]
      assert Enum.map(Catalog.filter_nationality(prints, "italian"), & &1.slug) == [b.slug]
      assert Catalog.filter_nationality(prints, nil) == prints
      assert Catalog.filter_nationality(prints, "") == prints
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

    test "nationality starts unset and takes only the listed values" do
      assert {:ok, print} = Catalog.create_print(@valid)
      assert print.nationality == ""
      assert Print.nationality_label(print.nationality) == ""

      assert {:ok, print} = Catalog.update_print(print, %{"nationality" => "dutch_flemish"})
      assert Catalog.get_print(print.slug).nationality == "dutch_flemish"
      assert Print.nationality_label("dutch_flemish") == "Dutch/Flemish"

      assert {:ok, print} = Catalog.update_print(print, %{"nationality" => ""})
      assert print.nationality == ""

      assert {:error, changeset} = Catalog.update_print(print, %{"nationality" => "martian"})
      assert %{nationality: ["is invalid"]} = errors_on(changeset)
    end

    test "nationalities/0 lists the seven choices in order" do
      assert Enum.map(Print.nationalities(), &elem(&1, 1)) ==
               ~w(Dutch/Flemish Italian German French British Canadian Other)
    end

    test "create_print/1 validates the required fields, category and status" do
      assert {:error, changeset} =
               Catalog.create_print(%{"category" => "sculpture", "status" => "lost"})

      errors = errors_on(changeset)
      assert errors.artist == ["can't be blank"]
      assert errors.title == ["can't be blank"]
      assert errors.image == ["add an image, or save the print as a draft"]
      assert errors.category == ["is invalid"]
      assert errors.status == ["is invalid"]
    end

    test "a draft can be saved without an image, but not published without one" do
      attrs = @valid |> Map.put("image", "") |> Map.put("status", "draft")
      assert {:ok, draft} = Catalog.create_print(attrs)

      assert {:error, changeset} = Catalog.set_status(draft, "available")
      assert errors_on(changeset).image == ["add an image, or save the print as a draft"]

      image = "/images/catalogue/beham-nude-650.jpg"

      assert {:ok, %{status: "available"}} =
               Catalog.update_print(draft, %{"image" => image, "status" => "available"})
    end

    test "drafts are left out of everything on the public site" do
      print = Catalog.get_print("neilson-dredging-the-st-charles-river")
      {:ok, draft} = Catalog.set_status(print, "draft")

      refute draft in Catalog.list_prints()
      refute Enum.any?(Catalog.list_prints("canadian"), &(&1.id == draft.id))
      refute Enum.any?(Catalog.featured_prints(), &(&1.id == draft.id))
      neilson = Catalog.get_print("neilson-timber-ship-quebec")
      refute Enum.any?(Catalog.more_by_artist(neilson), &(&1.id == draft.id))
      assert Catalog.get_public_print(draft.slug) == nil

      assert Enum.any?(Catalog.list_all_prints(), &(&1.id == draft.id))
      assert Catalog.get_print(draft.slug).id == draft.id
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

  describe "italic titles" do
    test "title_parts/1 splits out the parts between asterisks" do
      assert Catalog.title_parts("Plate 4 from *Souvenirs*, 1830") ==
               [{:plain, "Plate 4 from "}, {:italic, "Souvenirs"}, {:plain, ", 1830"}]

      assert Catalog.title_parts("No italics") == [{:plain, "No italics"}]
      assert Catalog.title_parts("A lone * star") == [{:plain, "A lone * star"}]
    end

    test "plain_title/1 drops the asterisks" do
      assert Catalog.plain_title("From *Vedute di Roma*") == "From Vedute di Roma"
      assert Catalog.plain_title("A lone * star") == "A lone * star"
    end
  end
end
