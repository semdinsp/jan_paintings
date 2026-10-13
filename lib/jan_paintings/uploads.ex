defmodule JanPaintings.Uploads do
  @moduledoc """
  Stores images uploaded from the admin pages.

  Files live in the directory configured as `:uploads_dir` (outside git, and
  outside the release in production so they survive deploys) and are served
  at /uploads by `JanPaintingsWeb.Plugs.Uploads`.
  """

  @doc "Directory uploaded files are stored in."
  def dir, do: Application.fetch_env!(:jan_paintings, :uploads_dir)

  @doc """
  Copies an uploaded temp file into the uploads directory under a unique,
  readable name and returns its site path, such as
  "/uploads/prints/neige-doree-k3j9x2.jpg".
  """
  def store_print_image(tmp_path, client_name) do
    ext = client_name |> Path.extname() |> String.downcase()

    base =
      client_name
      |> Path.rootname()
      |> JanPaintings.Catalog.Print.slugify()
      |> String.slice(0, 60)

    name = "#{if base == "", do: "image", else: base}-#{random_suffix()}#{ext}"
    dest = Path.join([dir(), "prints", name])

    File.mkdir_p!(Path.dirname(dest))
    File.cp!(tmp_path, dest)
    "/uploads/prints/" <> name
  end

  defp random_suffix,
    do: :crypto.strong_rand_bytes(4) |> Base.encode32(case: :lower, padding: false)
end
