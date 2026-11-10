defmodule JanPaintings.Repo.Migrations.UpgradeCustomerContactV3 do
  use Ecto.Migration

  def up, do: CustomerContact.Migrations.up(version: 3)
  def down, do: CustomerContact.Migrations.down(version: 3)
end
