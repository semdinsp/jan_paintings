defmodule JanPaintings.Inquiries.ContactMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_messages" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :subject, :string
    field :message, :string
    field :print_slug, :string
    field :followed_up_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact_message, attrs) do
    contact_message
    |> cast(attrs, [:name, :email, :phone, :subject, :message, :print_slug])
    |> update_change(:email, &String.trim/1)
    |> validate_required([:name, :email, :message])
    |> validate_length(:name, max: 120)
    |> validate_length(:email, max: 160)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must be a valid email")
    |> validate_length(:phone, max: 40)
    |> validate_length(:subject, max: 200)
    |> validate_length(:message, min: 5, max: 5000)
  end
end
