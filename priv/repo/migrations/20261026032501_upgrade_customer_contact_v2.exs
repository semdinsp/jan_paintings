defmodule JanPaintings.Repo.Migrations.UpgradeCustomerContactV2 do
  use Ecto.Migration

  def up, do: CustomerContact.Migrations.up(version: 2)
  def down, do: CustomerContact.Migrations.down(version: 2)
end
