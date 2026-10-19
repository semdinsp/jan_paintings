defmodule JanPaintings.Repo.Migrations.AddAdditionalNotesToPrints do
  use Ecto.Migration

  # Commentary on a print, such as the italic notes on the original site's
  # print pages; "" when there is none.
  def change do
    alter table(:prints) do
      add :additional_notes, :text, null: false, default: ""
    end
  end
end
