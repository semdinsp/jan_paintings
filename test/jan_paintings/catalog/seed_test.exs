defmodule JanPaintings.Catalog.SeedTest do
  use JanPaintings.DataCase, async: true

  alias JanPaintings.Catalog
  alias JanPaintings.Catalog.Seed

  @moduletag :tmp_dir

  defp write_seed(dir, prints) do
    path = Path.join(dir, "seed.json")
    File.write!(path, Jason.encode!(%{"prints" => prints}))
    path
  end

  test "the shipped seed file applies cleanly and only once" do
    # Tests start from the migrated catalogue without the seed, so the first
    # run fills fields and the second changes nothing.
    first = Seed.load_catalogue_details()
    assert first.missing == []
    assert first.updated > 100

    assert %{updated: 0, missing: []} = Seed.load_catalogue_details()

    abel = Catalog.get_print("abel-portrait-of-the-artists-father-melchior-or-self-portrait")
    assert abel.catalogue_references =~ "Heller-Andresen 2"
    assert abel.state == "First state of two"

    beham = Catalog.get_print("beham-leda-and-the-swan")
    assert beham.sheet_size == "55 × 68mm"
    assert beham.condition =~ "A fine, three-dimensional impression"
    assert beham.details == ""
  end

  test "fills blank fields but never overwrites existing values", %{tmp_dir: dir} do
    print = Catalog.get_print("neilson-dredging-the-st-charles-river")
    {:ok, _} = Catalog.update_print(print, %{"state" => "Edited by Jan"})

    path =
      write_seed(dir, [
        %{
          "slug" => print.slug,
          "catalogue_references" => "Test 1",
          "state" => "First state of two",
          "sheet_size" => ""
        },
        %{"slug" => "no-such-print", "state" => "x"}
      ])

    assert %{updated: 1, unchanged: 0, missing: ["no-such-print"]} =
             Seed.load_catalogue_details(path)

    print = Catalog.get_print(print.slug)
    assert print.catalogue_references == "Test 1"
    assert print.state == "Edited by Jan"
  end

  test "applies a correction only while the old value is still there", %{tmp_dir: dir} do
    print = Catalog.get_print("bleker-a-cowherd-playing-his-horn")

    correction = fn from ->
      write_seed(dir, [
        %{
          "slug" => print.slug,
          "corrections" => [%{"field" => "condition", "from" => from, "to" => "Fixed"}]
        }
      ])
    end

    assert %{updated: 0} = Seed.load_catalogue_details(correction.("not the current value"))
    assert Catalog.get_print(print.slug).condition == print.condition

    assert %{updated: 1} = Seed.load_catalogue_details(correction.(print.condition))
    assert Catalog.get_print(print.slug).condition == "Fixed"
  end
end
