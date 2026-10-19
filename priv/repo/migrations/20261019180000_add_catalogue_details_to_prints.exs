defmodule JanPaintings.Repo.Migrations.AddCatalogueDetailsToPrints do
  use Ecto.Migration

  # The print's full catalogue entry as written on the original site (medium,
  # date, references, watermark, provenance...); "" when there is none.
  def change do
    alter table(:prints) do
      add :catalogue_details, :text, null: false, default: ""
    end
  end
end
