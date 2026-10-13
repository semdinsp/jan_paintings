defmodule JanPaintings.Repo.Migrations.AddCatalogueFieldsToPrints do
  use Ecto.Migration

  def change do
    alter table(:prints) do
      add :catalogue_references, :text, null: false, default: ""
      add :state, :text, null: false, default: ""
      add :sheet_size, :string, null: false, default: ""
    end
  end
end
