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
    # The references moved out of the description; only the medium was left.
    assert abel.details == ""
    assert abel.medium == "Etching"

    penance = Catalog.get_print("beham-the-penance-of-st-john-chrysostom")
    assert penance.medium == "Engraving, ca. 1545"
    assert penance.catalogue_references =~ "Hollstein 70"

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

  describe "load_nationalities/1" do
    test "the shipped file gives every print in the catalogue a nationality, once" do
      first = Seed.load_nationalities()
      assert first.missing == []
      assert first.updated == length(Catalog.list_prints())
      assert Enum.all?(Catalog.list_prints(), &(&1.nationality != ""))

      assert %{updated: 0, missing: []} = Seed.load_nationalities()

      assert Catalog.get_print("neilson-dredging-the-st-charles-river").nationality == "canadian"
    end

    test "keeps nationalities chosen in the admin pages", %{tmp_dir: dir} do
      print = Catalog.get_print("neilson-dredging-the-st-charles-river")
      {:ok, _} = Catalog.update_print(print, %{"nationality" => "british"})

      path = Path.join(dir, "nationalities.json")

      File.write!(
        path,
        Jason.encode!(%{
          "artists" => [
            %{"artist" => print.artist, "nationality" => "canadian"},
            %{"artist" => "NOBODY, Anyone", "nationality" => "other"}
          ]
        })
      )

      summary = Seed.load_nationalities(path)
      assert summary.missing == ["NOBODY, Anyone"]
      assert Catalog.get_print(print.slug).nationality == "british"
      # The artist's other prints were still blank, so they were filled.
      others = Enum.filter(Catalog.list_prints(), &(&1.artist == print.artist))
      assert summary.updated == length(others) - 1
    end

    test "refuses an unknown nationality", %{tmp_dir: dir} do
      path = Path.join(dir, "bad.json")

      File.write!(
        path,
        Jason.encode!(%{"artists" => [%{"artist" => "ABEL, Josef", "nationality" => "martian"}]})
      )

      assert_raise ArgumentError, ~r/martian/, fn -> Seed.load_nationalities(path) end
    end
  end

  describe "load_additional_notes/1" do
    test "the shipped file matches every print it names, once" do
      first = Seed.load_additional_notes()
      assert first.missing == []
      assert first.updated == 67

      assert %{updated: 0, missing: []} = Seed.load_additional_notes()

      della_bella =
        Catalog.get_print(
          "della-bella-diverses-exercices-de-cavalerie-the-set-of-19-plates-including-title"
        )

      assert della_bella.additional_notes =~ ~r/^Massar proposes .* date to 1645\.$/
    end

    test "keeps notes edited in the admin pages", %{tmp_dir: dir} do
      print = Catalog.get_print("neilson-dredging-the-st-charles-river")
      {:ok, _} = Catalog.update_print(print, %{"additional_notes" => "Jan's note"})
      other = Catalog.get_print("bleker-a-cowherd-playing-his-horn")

      path = Path.join(dir, "notes.json")

      File.write!(
        path,
        Jason.encode!(%{
          "prints" => [
            %{"slug" => print.slug, "additional_notes" => "From the seed"},
            %{"slug" => other.slug, "additional_notes" => "From the seed"},
            %{"slug" => "no-such-print", "additional_notes" => "x"}
          ]
        })
      )

      assert %{updated: 1, missing: ["no-such-print"]} = Seed.load_additional_notes(path)
      assert Catalog.get_print(print.slug).additional_notes == "Jan's note"
      assert Catalog.get_print(other.slug).additional_notes == "From the seed"
    end
  end

  describe "load_catalogue_entries/1" do
    test "the shipped file covers every print, once" do
      first = Seed.load_catalogue_entries()
      assert first.missing == []
      assert first.updated > 150

      assert %{updated: 0, missing: []} = Seed.load_catalogue_entries()

      ghisi = Catalog.get_print("ghisi-the-visitation-after-francesco-salviati")

      assert ghisi.catalogue_details ==
               "Engraving, c. 1540-50. Lewis, Lewis and Boorsch 10, fourth state of six, " <>
                 "with the name of Lafreri erased but before that of Rossi, or later Losi\n" <>
                 "Watermark: Pilgrim in circle with star (L, L & B 55; Briquet 7578)\n" <>
                 "Provenance: Unidentified (Lugt 896); Somerville & Simpson 1970’s; " <>
                 "Dr.Eric Stanley (not in Lugt)"

      assert ghisi.provenance ==
               "Unidentified (Lugt 896); Somerville & Simpson 1970’s; Dr.Eric Stanley (not in Lugt)"
    end

    test "fills each field only while it is blank", %{tmp_dir: dir} do
      print = Catalog.get_print("ghisi-the-visitation-after-francesco-salviati")
      {:ok, _} = Catalog.update_print(print, %{"provenance" => "Jan's records"})

      path = Path.join(dir, "entries.json")

      File.write!(
        path,
        Jason.encode!(%{
          "prints" => [
            %{"slug" => print.slug, "catalogue_details" => "Engraving", "provenance" => "Seed"},
            %{"slug" => "no-such-print", "catalogue_details" => "x", "provenance" => ""}
          ]
        })
      )

      assert %{updated: 1, missing: ["no-such-print"]} = Seed.load_catalogue_entries(path)
      print = Catalog.get_print(print.slug)
      assert print.catalogue_details == "Engraving"
      assert print.provenance == "Jan's records"
    end
  end
end
