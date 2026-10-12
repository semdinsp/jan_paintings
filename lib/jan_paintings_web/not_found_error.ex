defmodule JanPaintingsWeb.NotFoundError do
  @moduledoc "Raised for unknown categories or prints; rendered as a 404."
  defexception message: "not found", plug_status: 404
end
