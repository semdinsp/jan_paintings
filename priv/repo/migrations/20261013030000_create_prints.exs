defmodule JanPaintings.Repo.Migrations.CreatePrints do
  use Ecto.Migration

  def change do
    create table(:prints) do
      add :slug, :string, null: false
      add :category, :string, null: false
      add :artist, :string, null: false
      add :dates, :string, null: false, default: ""
      add :title, :text, null: false
      add :medium, :string, null: false, default: ""
      add :details, :text, null: false, default: ""
      add :provenance, :text, null: false, default: ""
      add :watermark, :text, null: false, default: ""
      add :condition, :text, null: false, default: ""
      add :dimensions, :string, null: false, default: ""
      add :status, :string, null: false, default: "available"
      add :price, :string, null: false, default: ""
      add :thumb, :string, null: false, default: ""
      add :image, :string, null: false, default: ""
      add :large_image, :string, null: false, default: ""
      add :gallery, {:array, :string}, null: false, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:prints, [:slug])
    create index(:prints, [:category])
  end
end
