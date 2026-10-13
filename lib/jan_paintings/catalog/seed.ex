defmodule JanPaintings.Catalog.Seed do
  @moduledoc """
  Loads catalogue details (references, states, sheet sizes and a few
  corrections) from `priv/repo/seeds/print_catalogue_details.json` into the
  prints table.

  Safe to run repeatedly, locally or in production:

    * a field is only filled while it is blank, so edits made in the admin
      pages are never overwritten;
    * a correction only applies while the field still holds the exact value
      it corrects.

  Run it with `mix run priv/repo/seeds.exs` locally, or
  `bin/jan_paintings eval "JanPaintings.Release.seed()"` in a release.
  """
  import Ecto.Changeset

  alias JanPaintings.Catalog.Print
  alias JanPaintings.Repo

  @fill_fields ~w(catalogue_references state sheet_size)

  def default_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_catalogue_details.json")

  @doc """
  Applies the seed file. Returns a summary map: how many prints were updated,
  left unchanged, and the slugs not found in the database.
  """
  def load_catalogue_details(path \\ default_path()) do
    %{"prints" => entries} = path |> File.read!() |> Jason.decode!()

    Enum.reduce(entries, %{updated: 0, unchanged: 0, missing: []}, fn entry, summary ->
      case Repo.get_by(Print, slug: entry["slug"]) do
        nil ->
          Map.update!(summary, :missing, &[entry["slug"] | &1])

        print ->
          changes = Map.merge(fills(print, entry), corrections(print, entry))

          if changes == %{} do
            Map.update!(summary, :unchanged, &(&1 + 1))
          else
            print |> change(changes) |> Repo.update!()
            Map.update!(summary, :updated, &(&1 + 1))
          end
      end
    end)
    |> Map.update!(:missing, &Enum.reverse/1)
  end

  defp fills(print, entry) do
    for field <- @fill_fields,
        value = entry[field],
        value not in [nil, ""],
        Map.fetch!(print, String.to_existing_atom(field)) == "",
        into: %{},
        do: {String.to_existing_atom(field), value}
  end

  defp corrections(print, entry) do
    for %{"field" => field, "from" => from, "to" => to} <- entry["corrections"] || [],
        Map.fetch!(print, String.to_existing_atom(field)) == from,
        into: %{},
        do: {String.to_existing_atom(field), to}
  end
end
