defmodule JanPaintingsWeb.Plugs.CanonicalHost do
  @moduledoc """
  Redirects requests for any other host to the canonical host with a 301, so
  search engines index one address (for example jan-prints.fly.dev ->
  janjohnsonprints.com).

  Off unless configured:

      config :jan_paintings, :canonical_host, "janjohnsonprints.com"

  In production this comes from the CANONICAL_HOST environment variable.
  Set PHX_HOST to the same host so canonical URLs and redirects agree.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Application.get_env(:jan_paintings, :canonical_host) do
      host when is_binary(host) and host != "" and host != conn.host -> redirect(conn, host)
      _ -> conn
    end
  end

  defp redirect(conn, host) do
    query = if conn.query_string == "", do: "", else: "?" <> conn.query_string

    conn
    |> put_resp_header("location", "https://#{host}#{conn.request_path}#{query}")
    |> send_resp(:moved_permanently, "")
    |> halt()
  end
end
