defmodule JanPaintingsWeb.Plugs.Uploads do
  @moduledoc """
  Serves admin-uploaded images from `JanPaintings.Uploads.dir/0` at /uploads.

  Plug.Static is set up per request because the directory is runtime config.
  """
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{path_info: ["uploads" | _]} = conn, _opts) do
    static = Plug.Static.init(at: "/uploads", from: JanPaintings.Uploads.dir())
    Plug.Static.call(conn, static)
  end

  def call(conn, _opts), do: conn
end
