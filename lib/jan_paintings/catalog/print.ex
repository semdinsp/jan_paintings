defmodule JanPaintings.Catalog.Print do
  @moduledoc """
  A print in the gallery's stock.

  Text fields are never nil: an empty field is stored as "" so templates can
  test `field != ""`. `dimensions` is the plate or image size as catalogued;
  `sheet_size` is recorded only when the sheet size is stated separately.

  `nationality` is the artist's nationality, one of the keys in
  `nationalities/0`, or "" when it has not been set.

  `price_amount`, `price_currency`, `height_mm` and `width_mm` are read from
  the price and size text on every save (see `JanPaintings.Catalog.Measures`)
  and are used only for sorting; they are nil when the text has no number.

  Image fields hold site paths such as
  "/images/catalogue/abel-josef-portrait-of-melchior-lg.jpg" or
  "/uploads/prints/<file>".
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias JanPaintings.Catalog.Measures

  @statuses ~w(available sold reserved)

  @nationalities [
    {"dutch_flemish", "Dutch/Flemish"},
    {"italian", "Italian"},
    {"german", "German"},
    {"french", "French"},
    {"british", "British"},
    {"canadian", "Canadian"},
    {"other", "Other"}
  ]

  @text_fields ~w(dates medium details provenance watermark condition dimensions price
                  thumb large_image catalogue_references state sheet_size nationality)a

  schema "prints" do
    field :slug, :string
    field :category, :string
    field :artist, :string
    field :dates, :string, default: ""
    field :title, :string
    field :medium, :string, default: ""
    field :details, :string, default: ""
    field :provenance, :string, default: ""
    field :watermark, :string, default: ""
    field :condition, :string, default: ""
    field :dimensions, :string, default: ""
    field :sheet_size, :string, default: ""
    field :catalogue_references, :string, default: ""
    field :state, :string, default: ""
    field :status, :string, default: "available"
    field :nationality, :string, default: ""
    field :price, :string, default: ""
    field :thumb, :string, default: ""
    field :image, :string, default: ""
    field :large_image, :string, default: ""
    field :gallery, {:array, :string}, default: []
    field :price_amount, :integer
    field :price_currency, :string
    field :height_mm, :integer
    field :width_mm, :integer

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc "Nationalities a print's artist can have, as `{key, label}` pairs in display order."
  def nationalities, do: @nationalities

  @doc ~S(The label for a nationality key, such as "Dutch/Flemish"; "" when not set.)
  def nationality_label(key), do: List.keyfind(@nationalities, key, 0, {key, ""}) |> elem(1)

  @doc false
  def changeset(print, attrs, category_slugs) do
    print
    |> cast(attrs, [:slug, :category, :artist, :title, :status, :image, :gallery | @text_fields],
      empty_values: []
    )
    |> update_change(:artist, &String.trim/1)
    |> update_change(:title, &String.trim/1)
    |> update_change(:slug, &String.trim/1)
    |> nil_to_empty()
    |> update_change(:dimensions, &Measures.normalize_size/1)
    |> put_measures()
    |> put_slug()
    |> validate_not_blank([:slug, :category, :artist, :title, :status])
    |> validate_not_blank([:image], "add an image")
    |> validate_inclusion(:category, category_slugs)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:nationality, ["" | Enum.map(@nationalities, &elem(&1, 0))])
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "use lower-case letters, numbers and dashes"
    )
    |> validate_length(:slug, max: 120)
    |> unique_constraint(:slug)
  end

  # Sort fields always follow the text, so they can never disagree with it.
  defp put_measures(changeset) do
    {amount, currency} = Measures.parse_price(get_field(changeset, :price))
    {height, width} = Measures.parse_size(get_field(changeset, :dimensions))

    change(changeset,
      price_amount: amount,
      price_currency: currency,
      height_mm: height,
      width_mm: width
    )
  end

  # validate_required/2 would accept "" because blanks are kept as "" here.
  defp validate_not_blank(changeset, fields, message \\ "can't be blank") do
    Enum.reduce(fields, changeset, fn field, changeset ->
      if get_field(changeset, field) in [nil, ""],
        do: add_error(changeset, field, message, validation: :required),
        else: changeset
    end)
  end

  # Form fields left blank arrive as nil after trimming; store them as "".
  defp nil_to_empty(changeset) do
    Enum.reduce(@text_fields, changeset, fn field, changeset ->
      if Map.has_key?(changeset.changes, field) and is_nil(get_change(changeset, field)),
        do: put_change(changeset, field, ""),
        else: changeset
    end)
  end

  defp put_slug(changeset) do
    if get_field(changeset, :slug) in [nil, ""] do
      surname = (get_field(changeset, :artist) || "") |> String.split(",") |> hd()
      put_change(changeset, :slug, slugify("#{surname} #{get_field(changeset, :title)}"))
    else
      changeset
    end
  end

  @doc """
  Builds a URL slug from text. New prints get one from the artist's surname
  and the title, as in "neilson-dredging-the-st-charles-river".
  """
  def slugify(text) do
    text
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> String.slice(0, 80)
    |> String.trim("-")
  end
end
