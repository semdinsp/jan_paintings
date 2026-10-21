defmodule JanPaintings.Repo.Migrations.CreateMailingListSubscribers do
  use Ecto.Migration

  def change do
    create table(:mailing_list_subscribers) do
      add :email, :string, null: false
      add :name, :string
      add :interests, :text

      timestamps(type: :utc_datetime)
    end

    # Emails are stored lowercased, so this keeps one row per address.
    create unique_index(:mailing_list_subscribers, [:email])
  end
end
