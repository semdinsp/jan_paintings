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

# Each print's catalogue details (the catalogue block of its page on the
# original site) and provenance. Also fills blanks only.
JanPaintings.Catalog.Seed.load_catalogue_entries() |> IO.inspect(label: "Catalogue entries")

# Each print's medium (the opening of its catalogue block on the original
# site), with corrections for any that were wrong. Fills blanks only, and a
# correction applies only while the old value is still there.
JanPaintings.Catalog.Seed.load_mediums() |> IO.inspect(label: "Mediums")

# Catalogue references still blank, taken from each print's full catalogue
# entry. Fills blanks only.
JanPaintings.Catalog.Seed.load_catalogue_references()
|> IO.inspect(label: "Catalogue references")

# Sizes left at the end of the details text: moved into the size field.
# Each change applies only while the old value is still there.
JanPaintings.Catalog.Seed.load_sizes() |> IO.inspect(label: "Sizes")

# Book and series titles set in italics on the original site, marked with
# asterisks. Each title changes only while it still reads as before.
JanPaintings.Catalog.Seed.load_title_italics() |> IO.inspect(label: "Title italics")
