defmodule JanPaintings.Repo.Migrations.CreateContactMessages do
  use Ecto.Migration

  def change do
    create table(:contact_messages) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :subject, :string
      add :message, :text, null: false
      add :print_slug, :string
      add :followed_up_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:contact_messages, [:inserted_at])
  end
end
