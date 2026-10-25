defmodule JanPaintings.Catalog.Seed do
  @moduledoc """
  Loads catalogue details (references, states, sheet sizes, missing media)
  and corrections from `priv/repo/seeds/print_catalogue_details.json` into
  the prints table. The corrections take the catalogue references out of the
  descriptions, now that they have their own field, and fix four records
  whose condition was stored as the description.

  Safe to run repeatedly, locally or in production:

    * a field is only filled while it is blank, so edits made in the admin
      pages are never overwritten;
    * a correction only applies while the field still holds the exact value
      it corrects.

  `load_nationalities/1` fills in each artist's nationality,
  `load_additional_notes/1` each print's additional notes,
  `load_catalogue_entries/1` each print's catalogue details and provenance,
  `load_mediums/1` each print's medium, `load_catalogue_references/1`
  the catalogue references still missing, `load_sizes/1` the sizes left at
  the end of the details text, and `load_title_italics/1` the book and series
  titles shown in italics, the same way.

  Run them all with `mix run priv/repo/seeds.exs` locally, or
  `bin/jan_paintings eval "JanPaintings.Release.seed()"` in a release.
  """
  import Ecto.Changeset
  import Ecto.Query

  alias JanPaintings.Catalog.Print
  alias JanPaintings.Repo

  @fill_fields ~w(catalogue_references state sheet_size medium)

  def default_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_catalogue_details.json")

  def nationalities_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_nationalities.json")

  def mediums_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_mediums.json")

  def catalogue_references_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_catalogue_references.json")

  def title_italics_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_title_italics.json")

  def sizes_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_sizes.json")

  def catalogue_entries_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_catalogue_entries.json")

  @doc """
  Sets each print's catalogue details and provenance from
  `priv/repo/seeds/print_catalogue_entries.json`: the catalogue block of each
  print page on the original site, and the provenance named in it. Each field
  is only filled while it is blank, so edits made in the admin pages are kept
  and it is safe to run again.

  Returns how many prints were updated and the slugs not found.
  """
  def load_catalogue_entries(path \\ catalogue_entries_path()) do
    %{"prints" => entries} = path |> File.read!() |> Jason.decode!()

    Enum.reduce(entries, %{updated: 0, missing: []}, fn entry, summary ->
      case Repo.get_by(Print, slug: entry["slug"]) do
        nil ->
          Map.update!(summary, :missing, &[entry["slug"] | &1])

        print ->
          changes =
            for field <- [:catalogue_details, :provenance],
                value = entry[Atom.to_string(field)],
                value not in [nil, ""],
                Map.fetch!(print, field) == "",
                into: %{},
                do: {field, value}

          if changes == %{} do
            summary
          else
            print |> change(changes) |> Repo.update!()
            Map.update!(summary, :updated, &(&1 + 1))
          end
      end
    end)
    |> Map.update!(:missing, &Enum.reverse/1)
  end

  def additional_notes_path,
    do: Path.join(:code.priv_dir(:jan_paintings), "repo/seeds/print_additional_notes.json")

  @doc """
  Sets each print's additional notes from
  `priv/repo/seeds/print_additional_notes.json`: the notes set in italics on
  the original site's print pages. Only fills notes that are still blank, so
  notes edited in the admin pages are kept and it is safe to run again.

  Returns how many prints were updated and the slugs not found.
  """
  def load_additional_notes(path \\ additional_notes_path()) do
    %{"prints" => entries} = path |> File.read!() |> Jason.decode!()

    Enum.reduce(entries, %{updated: 0, missing: []}, fn %{"slug" => slug} = entry, summary ->
      notes = Map.fetch!(entry, "additional_notes")

      if Repo.exists?(from p in Print, where: p.slug == ^slug) do
        {count, _} =
          from(p in Print, where: p.slug == ^slug and p.additional_notes == "")
          |> Repo.update_all(
            set: [additional_notes: notes, updated_at: DateTime.utc_now(:second)]
          )

        Map.update!(summary, :updated, &(&1 + count))
      else
        Map.update!(summary, :missing, &[slug | &1])
      end
    end)
    |> Map.update!(:missing, &Enum.reverse/1)
  end

  @doc """
  Sets each artist's nationality from `priv/repo/seeds/print_nationalities.json`
  on their prints, matching the artist exactly as stored. Like the catalogue
  details, it only fills prints whose nationality is still blank, so choices
  made in the admin pages are kept and it is safe to run again.

  Returns how many prints were updated and the artists in the file that no
  print matched.
  """
  def load_nationalities(path \\ nationalities_path()) do
    %{"artists" => entries} = path |> File.read!() |> Jason.decode!()

    Enum.reduce(entries, %{updated: 0, missing: []}, fn %{"artist" => artist} = entry, summary ->
      nationality = Map.fetch!(entry, "nationality")

      unless List.keymember?(Print.nationalities(), nationality, 0),
        do: raise(ArgumentError, "unknown nationality #{inspect(nationality)} for #{artist}")

      if Repo.exists?(from p in Print, where: p.artist == ^artist) do
        {count, _} =
          from(p in Print, where: p.artist == ^artist and p.nationality == "")
          |> Repo.update_all(
            set: [nationality: nationality, updated_at: DateTime.utc_now(:second)]
          )

        Map.update!(summary, :updated, &(&1 + count))
      else
        Map.update!(summary, :missing, &[artist | &1])
      end
    end)
    |> Map.update!(:missing, &Enum.reverse/1)
  end

  @doc """
  Fills in each print's medium from `priv/repo/seeds/print_mediums.json`
  (the opening of its catalogue block on the original site), and corrects
  any that were wrong. Same file format, rules and summary as
  `load_catalogue_details/1`: blanks are filled, and a correction applies
  only while the medium still holds the value it corrects.
  """
  def load_mediums(path \\ mediums_path()), do: load_catalogue_details(path)

  @doc """
  Fills in blank catalogue references from
  `priv/repo/seeds/print_catalogue_references.json`, taken from each print's
  full catalogue entry. Same file format, rules and summary as
  `load_catalogue_details/1`; a reference typed in the admin pages is kept.
  """
  def load_catalogue_references(path \\ catalogue_references_path()),
    do: load_catalogue_details(path)

  @doc """
  Moves sizes that were left at the end of a print's details text into its
  size field, from `priv/repo/seeds/print_sizes.json`: each entry has two
  corrections, the blank size to the size and the details to the details
  without it. Same rules and summary as `load_catalogue_details/1`, so a
  print whose size or details were edited in the admin pages is left alone.
  """
  def load_sizes(path \\ sizes_path()), do: load_catalogue_details(path)

  @doc """
  Marks the book and series titles that the original site set in italics,
  from `priv/repo/seeds/print_title_italics.json`, with asterisks (see
  `JanPaintings.Catalog.title_parts/1`). Each title is a correction, applied
  only while the title still reads exactly as before.
  """
  def load_title_italics(path \\ title_italics_path()), do: load_catalogue_details(path)

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
