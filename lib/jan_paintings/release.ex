defmodule JanPaintings.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :jan_paintings

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Loads the catalogue details seed (see `JanPaintings.Catalog.Seed`). Run on
  Fly with:

      fly ssh console -C '/app/bin/jan_paintings eval "JanPaintings.Release.seed()"'
  """
  def seed do
    load_app()

    {:ok, summary, _} =
      Ecto.Migrator.with_repo(JanPaintings.Repo, fn _repo ->
        JanPaintings.Catalog.Seed.load_catalogue_details()
      end)

    IO.inspect(summary, label: "Catalogue details")
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
