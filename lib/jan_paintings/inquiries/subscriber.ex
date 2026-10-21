defmodule JanPaintings.Inquiries.Subscriber do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mailing_list_subscribers" do
    field :email, :string
    field :name, :string
    field :interests, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscriber, attrs) do
    subscriber
    |> cast(attrs, [:email, :name, :interests])
    |> update_change(:email, &(&1 |> String.trim() |> String.downcase()))
    |> validate_required([:email])
    |> validate_length(:email, max: 160)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must be a valid email")
    |> validate_length(:name, max: 120)
    |> validate_length(:interests, max: 1000)
    |> unique_constraint(:email)
  end
end
