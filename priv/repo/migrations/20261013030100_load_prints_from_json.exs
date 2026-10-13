defmodule JanPaintings.Repo.Migrations.LoadPrintsFromJson do
  @moduledoc """
  Loads the catalogue scraped from janjohnsonprints.com into the prints table.

  Runs once per database. Prints that already exist (matched by slug) are
  left alone, so edits made in the admin pages are never overwritten.
  Self-contained on purpose: it does not use the Print schema, which may
  change later.
  """
  use Ecto.Migration

  @fields ~w(slug category artist dates title medium details provenance watermark
             condition dimensions status price thumb image large_image gallery)

  def up do
    now = DateTime.utc_now(:second)

    rows =
      Path.join(:code.priv_dir(:jan_paintings), "data/prints.json")
      |> File.read!()
      |> Jason.decode!()
      |> Enum.map(fn print ->
        print
        |> Map.take(@fields)
        |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)
        |> Map.merge(%{inserted_at: now, updated_at: now})
      end)

    repo().insert_all("prints", rows, on_conflict: :nothing, conflict_target: :slug)
  end

  def down, do: :ok
end
