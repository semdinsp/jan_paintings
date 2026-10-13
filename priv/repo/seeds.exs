# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     JanPaintings.Repo.insert!(%JanPaintings.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Catalogue details (references, states, sheet sizes and a few corrections)
# reviewed from the original janjohnsonprints.com pages. Fills blank fields
# only, so it is safe to run again and never overwrites admin edits.
# In production: bin/jan_paintings eval "JanPaintings.Release.seed()"
JanPaintings.Catalog.Seed.load_catalogue_details() |> IO.inspect(label: "Catalogue details")
