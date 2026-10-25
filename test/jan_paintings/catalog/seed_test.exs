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

  describe "load_mediums/1" do
    test "the shipped file covers every print and leaves none blank" do
      assert %{missing: []} = Seed.load_mediums()
      assert %{updated: 0, missing: []} = Seed.load_mediums()
      assert Enum.all?(Catalog.list_all_prints(), &(&1.medium != ""))

      assert Catalog.get_print("cochin-le-garcon-cabartier-after-j-b-s-chardin").medium ==
               "Engraving"

      assert Catalog.get_print(
               "goldhamer-lithographs-of-ontario-georgian-bay-and-haliburton-a-portfolio-contain"
             ).medium == "Lithographs, c. 1932"
    end

    test "corrects a wrong medium, but not one changed in the admin pages", %{tmp_dir: dir} do
      slug = "saenredam-adam-and-eve-forced-to-labour-plate-5-from-the-six-plate-series-histor"
      print = Catalog.get_print(slug)
      {:ok, _} = Catalog.update_print(print, %{"medium" => "Engravings, 1601"})

      path =
        write_seed(dir, [
          %{
            "slug" => slug,
            "medium" => "Engraving, 1604",
            "corrections" => [
              %{"field" => "medium", "from" => "Engravings, 1601", "to" => "Engraving, 1604"}
            ]
          }
        ])

      assert %{updated: 1} = Seed.load_mediums(path)
      assert Catalog.get_print(slug).medium == "Engraving, 1604"

      {:ok, _} = Catalog.update_print(Catalog.get_print(slug), %{"medium" => "Engraving"})
      assert %{updated: 0} = Seed.load_mediums(path)
      assert Catalog.get_print(slug).medium == "Engraving"
    end
  end

  describe "load_catalogue_references/1" do
    test "fills blank references from the shipped file" do
      slug = "bonnet-premiere-feuille-darabesques-after-carle-first-name-unknown"
      {:ok, _} = Catalog.update_print(Catalog.get_print(slug), %{"catalogue_references" => ""})

      assert %{missing: []} = Seed.load_catalogue_references()
      assert Catalog.get_print(slug).catalogue_references == "Hérold 967"
      assert %{updated: 0, missing: []} = Seed.load_catalogue_references()
    end

    test "keeps a reference typed in the admin pages" do
      slug = "bonnet-premiere-feuille-darabesques-after-carle-first-name-unknown"

      {:ok, _} =
        Catalog.update_print(Catalog.get_print(slug), %{"catalogue_references" => "Hérold 966"})

      Seed.load_catalogue_references()
      assert Catalog.get_print(slug).catalogue_references == "Hérold 966"
    end
  end

  describe "load_sizes/1" do
    @berchem "berchem-shepherd-playing-a-flute"

    # Puts the print back as the original import left it: no size, and the
    # size at the end of the details.
    defp unmove_size(slug, details) do
      print = Catalog.get_print(slug)
      {:ok, _} = Catalog.update_print(print, %{"dimensions" => "", "details" => details})
    end

    defp seed_details(slug) do
      %{"prints" => prints} = Seed.sizes_path() |> File.read!() |> Jason.decode!()
      %{"corrections" => corrections} = Enum.find(prints, &(&1["slug"] == slug))
      Enum.find(corrections, &(&1["field"] == "details"))
    end

    test "moves the size from the end of the details into the size field" do
      %{"from" => old, "to" => new} = seed_details(@berchem)
      unmove_size(@berchem, old)

      assert %{missing: []} = Seed.load_sizes()
      print = Catalog.get_print(@berchem)
      assert print.dimensions == "196 × 147mm"
      assert print.details == new
      refute print.details =~ "147mm"

      assert %{updated: 0, missing: []} = Seed.load_sizes()
    end

    test "leaves a print alone once its details were edited in the admin pages" do
      %{"from" => old} = seed_details(@berchem)
      unmove_size(@berchem, old <> " Edited by Jan.")

      Seed.load_sizes()
      print = Catalog.get_print(@berchem)
      assert print.details =~ "Edited by Jan."
      assert print.details =~ "147mm"
    end
  end

  describe "load_title_italics/1" do
    test "marks the series titles and fixes défense, once" do
      assert %{missing: []} = Seed.load_title_italics()

      assert Catalog.get_print("isabey-souvenir-de-bretagne-plate-4-from-souvenirs").title ==
               "Souvenir de Bretagne, plate 4 from *Souvenirs*"

      bonnet =
        Enum.find(Catalog.list_all_prints(), &String.contains?(&1.title, "petites postes"))

      assert bonnet.title =~ "from *La défense et l’attaque des petites postes*, published"
      assert %{updated: 0} = Seed.load_title_italics()
    end

    test "cuts the catalogue entry off the end of a run-on title" do
      weirotter =
        Enum.find(Catalog.list_all_prints(), &String.starts_with?(&1.title, "Nella venuta"))

      Seed.load_title_italics()
      title = Catalog.get_print(weirotter.slug).title
      assert String.ends_with?(title, "by various hands in the original booklet")
      refute title =~ "Etchings, 1764"
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
