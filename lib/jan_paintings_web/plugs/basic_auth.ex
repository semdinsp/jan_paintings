defmodule JanPaintingsWeb.Plugs.BasicAuth do
  @moduledoc """
  Optional site-wide password, for keeping the site private before launch.

  Enabled only when a password is configured:

      config :jan_paintings, :basic_auth, username: "jan", password: "..."

  In production this comes from the BASIC_AUTH_USERNAME and BASIC_AUTH_PASSWORD
  environment variables (see config/runtime.exs). To remove the password,
  unset BASIC_AUTH_PASSWORD, or delete this plug from the router's :browser
  pipeline.
  """
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Application.get_env(:jan_paintings, :basic_auth, []) do
      config when is_list(config) ->
        case {config[:username], config[:password]} do
          {username, password}
          when is_binary(username) and is_binary(password) and password != "" ->
            Plug.BasicAuth.basic_auth(conn,
              username: username,
              password: password,
              realm: "Jan Johnson Prints"
            )

          _ ->
            conn
        end

      _ ->
        conn
    end
  end
end
