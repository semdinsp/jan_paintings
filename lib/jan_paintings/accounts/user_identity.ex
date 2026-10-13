defmodule JanPaintings.Accounts.UserIdentity do
  @moduledoc """
  A login from an external identity provider, such as Google, linked to a user.

  `provider_uid` is the provider's stable account id (Google's `sub` claim),
  so a user who changes their Google email still matches the same account.
  A user can have at most one identity per provider.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @providers ~w(google)

  schema "user_identities" do
    field :provider, :string
    field :provider_uid, :string
    field :email, :string

    belongs_to :user, JanPaintings.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc "Providers that identities can be linked from."
  def providers, do: @providers

  @doc false
  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :provider_uid, :email])
    |> validate_required([:provider, :provider_uid])
    |> validate_inclusion(:provider, @providers)
    |> unique_constraint([:provider, :provider_uid])
    |> unique_constraint([:user_id, :provider])
  end
end
