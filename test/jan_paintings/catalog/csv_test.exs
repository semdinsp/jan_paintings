defmodule JanPaintings.Catalog.CSVTest do
  use JanPaintings.DataCase, async: true

  alias JanPaintings.Catalog
  alias JanPaintings.Catalog.CSV

  @image "/images/catalogue/abel-josef-portrait-of-melchior-lg.jpg"

  defp csv(rows),
    do: [CSV.columns() | rows] |> CSV.Parser.dump_to_iodata() |> IO.iodata_to_binary()

  defp row(fields) do
    Enum.map(CSV.columns(), fn column -> Map.get(fields, column, "") end)
  end

  defp new_print(fields \\ %{}) do
    Map.merge(
      %{
        "category" => "modern",
        "artist" => "DOE, Jane",
        "title" => "A New Etching",
        "image" => @image,
        "price" => "$900 USD"
      },
      fields
    )
  end

  test "every column is a print field" do
    fields = JanPaintings.Catalog.Print.__schema__(:fields)
    assert Enum.all?(CSV.columns(), &(String.to_existing_atom(&1) in fields))
  end

  test "exports every print, with text that needs quoting kept intact" do
    print = Catalog.get_print("ghisi-the-visitation-after-francesco-salviati")

    {:ok, print} =
      Catalog.update_print(print, %{"catalogue_details" => "Engraving, \"proof\"\nLine two"})

    [header | rows] =
      Catalog.list_prints()
      |> CSV.export()
      |> IO.iodata_to_binary()
      |> CSV.Parser.parse_string(skip_headers: false)

    assert header == CSV.columns()
    assert length(rows) == length(Catalog.list_prints())

    ghisi =
      Enum.find(rows, &(hd(&1) == print.slug)) |> then(&Enum.zip(CSV.columns(), &1)) |> Map.new()

    assert ghisi["catalogue_details"] == "Engraving, \"proof\"\nLine two"
    assert ghisi["title"] == print.title
  end

  test "importing the exported file adds nothing" do
    exported = Catalog.list_prints() |> CSV.export() |> IO.iodata_to_binary()
    count = length(Catalog.list_prints())

    assert {:ok, %{created: [], skipped: skipped}} = CSV.import(exported)
    assert length(skipped) == count
  end

  test "creates new rows and skips rows already in the catalogue" do
    gallery = "#{@image} | /images/catalogue/beham-nude-650.jpg"

    file =
      csv([
        row(%{"slug" => "ghisi-the-visitation-after-francesco-salviati", "title" => "Changed"}),
        row(new_print(%{"gallery" => gallery, "nationality" => "british"})),
        row(%{})
      ])

    assert {:ok, %{created: [print], skipped: ["ghisi-the-visitation-after-francesco-salviati"]}} =
             CSV.import(file)

    assert print.slug == "doe-a-new-etching"
    assert print.status == "available"
    assert print.nationality == "british"
    assert print.price_amount == 900
    assert print.gallery == [@image, "/images/catalogue/beham-nude-650.jpg"]
    assert Catalog.get_print("ghisi-the-visitation-after-francesco-salviati").title != "Changed"
  end

  test "accepts the columns in any order, and only some of them" do
    file = "title,artist,category,image\r\nA Woodcut,\"ROE, Ray\",canadian,#{@image}\r\n"
    assert {:ok, %{created: [print]}} = CSV.import(file)
    assert {print.artist, print.category} == {"ROE, Ray", "canadian"}
  end

  test "adds nothing when any row has a problem, and says which rows" do
    file =
      csv([
        row(new_print()),
        row(new_print(%{"title" => "Second", "category" => "nowhere"})),
        row(new_print(%{"title" => "Third", "image" => "/images/no-such-file.jpg"})),
        row(new_print())
      ])

    assert {:error, problems} = CSV.import(file)
    assert [{3, category}, {4, image}, {5, duplicate}] = problems
    assert category =~ "category"
    assert image =~ "/images/no-such-file.jpg"
    assert duplicate =~ "doe-a-new-etching"
    refute Catalog.get_print("doe-a-new-etching")
  end

  test "refuses unknown columns" do
    assert {:error, [{1, message}]} = CSV.import("title,colour\r\nX,red\r\n")
    assert message =~ "colour"
  end
end
