defmodule JanPaintings.Repo.Migrations.AddCustomerContact do
  use Ecto.Migration

  def up, do: CustomerContact.Migrations.up(version: 1)
  def down, do: CustomerContact.Migrations.down(version: 1)
end
