defmodule JanPaintings.Catalog.Print do
  @moduledoc """
  A print in the gallery's stock.

  Text fields are never nil: an empty field is stored as "" so templates can
  test `field != ""`. `dimensions` is the plate or image size as catalogued;
  `sheet_size` is recorded only when the sheet size is stated separately. Image fields hold site paths such as
  "/images/catalogue/abel-josef-portrait-of-melchior-lg.jpg" or
  "/uploads/prints/<file>".
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(available sold reserved)

  @text_fields ~w(dates medium details provenance watermark condition dimensions price
                  thumb large_image catalogue_references state sheet_size)a

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
    field :price, :string, default: ""
    field :thumb, :string, default: ""
    field :image, :string, default: ""
    field :large_image, :string, default: ""
    field :gallery, {:array, :string}, default: []

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

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
    |> put_slug()
    |> validate_not_blank([:slug, :category, :artist, :title, :status])
    |> validate_not_blank([:image], "add an image")
    |> validate_inclusion(:category, category_slugs)
    |> validate_inclusion(:status, @statuses)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "use lower-case letters, numbers and dashes"
    )
    |> validate_length(:slug, max: 120)
    |> unique_constraint(:slug)
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
