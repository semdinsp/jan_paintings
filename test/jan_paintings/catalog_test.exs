defmodule JanPaintings.CatalogTest do
  use ExUnit.Case, async: true

  alias JanPaintings.Catalog

  # Counts of distinct prints on the original janjohnsonprints.com site.
  test "matches the print count of the original site" do
    assert length(Catalog.list_prints()) == 157
    assert length(Catalog.list_prints("old-masters")) == 81
    assert length(Catalog.list_prints("modern")) == 44
    assert length(Catalog.list_prints("canadian")) == 32
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

    assert length(by_status["sold"]) == 4
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
end
