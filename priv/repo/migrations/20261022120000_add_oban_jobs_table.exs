defmodule JanPaintings.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up, do: Oban.Migrations.up()

  # Drops the Oban tables entirely.
  def down, do: Oban.Migrations.down(version: 1)
end
