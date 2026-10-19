defmodule JanPaintingsWeb.Admin.PrintCSVController do
  @moduledoc "Downloads the whole print catalogue as CSV, for the admin pages."
  use JanPaintingsWeb, :controller

  alias JanPaintings.Catalog

  def export(conn, _params) do
    filename = "jan-johnson-prints-#{Date.utc_today()}.csv"

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, Catalog.CSV.export(Catalog.list_prints()))
  end
end
