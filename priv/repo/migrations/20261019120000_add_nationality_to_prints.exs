defmodule JanPaintings.Repo.Migrations.AddNationalityToPrints do
  use Ecto.Migration

  # The artist's nationality, one of JanPaintings.Catalog.Print.nationalities/0;
  # "" until someone sets it.
  def change do
    alter table(:prints) do
      add :nationality, :string, null: false, default: ""
    end
  end
end
