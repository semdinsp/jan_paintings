defmodule JanPaintings.Catalog.CSV do
  @moduledoc """
  Exports the print catalogue as CSV from the admin pages, and creates new
  prints from a CSV in the same format.

  The columns are the editable fields of `JanPaintings.Catalog.Print`, in
  `columns/0` order. `gallery` holds the extra image paths separated by
  " | ". The sort fields (price amount, sizes in mm) are not exported: they
  are worked out from the price and size text when a print is saved.

  An import only adds prints. A row whose slug is already in the catalogue is
  skipped, so an exported file with new rows added can be uploaded as it is.
  Either every new row is created or, if any row has a problem, none is.
  """
  alias JanPaintings.Catalog
  alias JanPaintings.Catalog.Print
  alias JanPaintings.Repo

  NimbleCSV.define(__MODULE__.Parser, separator: ",", escape: "\"")
  alias __MODULE__.Parser

  @columns ~w(slug category artist dates title medium details catalogue_details
              catalogue_references state dimensions sheet_size condition provenance
              watermark additional_notes nationality status price image large_image
              thumb gallery)

  @gallery_separator " | "

  def columns, do: @columns

  @doc "The prints as CSV text (iodata), with a header row."
  def export(prints) do
    rows = Enum.map(prints, fn print -> Enum.map(@columns, &cell(print, &1)) end)
    Parser.dump_to_iodata([@columns | rows])
  end

  defp cell(print, "gallery"), do: Enum.join(print.gallery, @gallery_separator)
  defp cell(print, column), do: Map.fetch!(print, String.to_existing_atom(column))

  @doc """
  Creates the prints in a CSV. Returns `{:ok, %{created: prints, skipped: slugs}}`,
  or `{:error, problems}` with a list of `{row_number, message}` (the header
  is row 1) when nothing was created.
  """
  def import(csv) when is_binary(csv) do
    with {:ok, rows} <- parse(csv) do
      existing = MapSet.new(Catalog.list_prints(), & &1.slug)
      {skipped, new} = Enum.split_with(rows, fn {_n, attrs} -> attrs["slug"] in existing end)

      case create_all(new) do
        {:ok, created} ->
          {:ok, %{created: created, skipped: Enum.map(skipped, &elem(&1, 1)["slug"])}}

        {:error, problems} ->
          {:error, problems}
      end
    end
  end

  defp parse(csv) do
    csv = String.trim_leading(csv, "﻿")

    case Parser.parse_string(csv, skip_headers: false) do
      [] ->
        {:error, [{1, "The file is empty."}]}

      [header | rows] ->
        header = Enum.map(header, &(&1 |> String.trim() |> String.downcase()))

        case Enum.reject(header, &(&1 in @columns)) do
          [] ->
            rows =
              rows
              |> Enum.with_index(2)
              |> Enum.reject(fn {row, _n} -> Enum.all?(row, &(String.trim(&1) == "")) end)
              |> Enum.map(fn {row, n} -> {n, attrs(header, row)} end)

            {:ok, rows}

          unknown ->
            {:error, [{1, "Unknown columns: #{Enum.join(unknown, ", ")}."}]}
        end
    end
  rescue
    e in NimbleCSV.ParseError ->
      {:error, [{0, "Could not read the CSV: #{Exception.message(e)}"}]}
  end

  defp attrs(header, row) do
    header
    |> Enum.zip(row)
    |> Map.new(fn {column, value} -> {column, String.trim(value)} end)
    |> Map.update("gallery", [], &split_gallery/1)
    |> Map.update("status", "available", &if(&1 == "", do: "available", else: &1))
  end

  defp split_gallery(value),
    do: value |> String.split("|", trim: true) |> Enum.map(&String.trim/1)

  # Every row is checked before anything is inserted, including slugs taken
  # by another row of the file, so a problem never leaves a half-done import.
  defp create_all(rows) do
    {checked, _slugs} =
      Enum.map_reduce(rows, MapSet.new(Catalog.list_prints(), & &1.slug), fn {n, attrs}, slugs ->
        changeset = Catalog.change_print(%Print{}, attrs)
        slug = Ecto.Changeset.get_field(changeset, :slug)

        result =
          cond do
            not changeset.valid? -> {:error, {n, errors(changeset)}}
            slug in slugs -> {:error, {n, "slug #{slug} is used by another print or row."}}
            check_images(attrs) != :ok -> {:error, {n, elem(check_images(attrs), 1)}}
            true -> {:ok, changeset}
          end

        {result, MapSet.put(slugs, slug)}
      end)

    case for({:error, problem} <- checked, do: problem) do
      [] ->
        Repo.transaction(fn -> for {:ok, changeset} <- checked, do: Repo.insert!(changeset) end)

      problems ->
        {:error, problems}
    end
  end

  # A print needs its image already on the site: under /images (shipped with
  # the site) or /uploads (added from the admin pages).
  defp check_images(attrs) do
    missing =
      [attrs["image"], attrs["large_image"], attrs["thumb"] | attrs["gallery"]]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.reject(&image_exists?/1)

    if missing == [], do: :ok, else: {:error, "No such image: #{Enum.join(missing, ", ")}."}
  end

  defp image_exists?("/uploads/" <> path),
    do: File.regular?(Path.join(JanPaintings.Uploads.dir(), path))

  defp image_exists?("/images/" <> _ = path),
    do: File.regular?(Path.join(Application.app_dir(:jan_paintings, "priv/static"), path))

  defp image_exists?(_path), do: false

  defp errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join("; ", fn {field, messages} -> "#{field} #{Enum.join(messages, ", ")}" end)
  end
end
