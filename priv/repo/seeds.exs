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

# Each artist's nationality (Dutch/Flemish, Italian, German, French, British,
# Canadian or Other), drafted from research. Also fills blanks only.
JanPaintings.Catalog.Seed.load_nationalities() |> IO.inspect(label: "Nationalities")

# Each print's additional notes: the commentary set in italics on the original
# site's print pages. Also fills blanks only.
JanPaintings.Catalog.Seed.load_additional_notes() |> IO.inspect(label: "Additional notes")
