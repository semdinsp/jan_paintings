defmodule JanPaintings.Repo.Migrations.ChangePrintsMediumToText do
  use Ecto.Migration

  # The admin form edits the medium in a text block, like the other long fields.
  def change do
    alter table(:prints) do
      modify :medium, :text, null: false, default: "", from: {:string, null: false, default: ""}
    end
  end
end
