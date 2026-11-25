defmodule JanPaintingsWeb.SpamGuard do
  @moduledoc """
  Spam checks for the public contact and mailing list forms.

  A submission must pass, in order:

    1. the hidden "website" trap field is empty (bots tend to fill every field);
    2. the signed "started" token shows the form was loaded at least
       `min_seconds` ago and not more than a day ago (bots post instantly, or
       replay an old form);
    3. the sender's IP is under the submission limit (`JanPaintingsWeb.RateLimit`);
    4. Cloudflare Turnstile accepts the widget's token, when Turnstile is set up
       (`JanPaintingsWeb.Turnstile`).

  Failing 1 or 2 is treated as a bot: the controller pretends it worked.
  Failing 3 or 4 tells the person what to do.
  """

  alias JanPaintingsWeb.{Endpoint, RateLimit, Turnstile}

  @salt "form started"
  @max_age 86_400

  @doc "A signed token recording when a form was shown. `now` is in seconds."
  def form_token(now \\ System.system_time(:second)),
    do: Phoenix.Token.sign(Endpoint, @salt, now, signed_at: now)

  @doc """
  Checks a submission. `action` is the form's Turnstile action ("contact" or
  "mailing-list"). `params` are the form's params (with "website",
  "started" and Cloudflare's "cf-turnstile-response" in the top-level params).
  """
  def check(conn, form_params, action) do
    cond do
      form_params["website"] not in [nil, ""] ->
        {:error, :bot}

      not old_enough?(form_params["started"]) ->
        {:error, :bot}

      not RateLimit.allow?(client_ip(conn)) ->
        {:error, :rate_limited}

      not Turnstile.valid?(conn.params["cf-turnstile-response"], action, client_ip(conn)) ->
        {:error, :turnstile}

      true ->
        :ok
    end
  end

  defp old_enough?(token) when is_binary(token) do
    case Phoenix.Token.verify(Endpoint, @salt, token, max_age: @max_age) do
      {:ok, started} -> System.system_time(:second) - started >= min_seconds()
      {:error, _} -> false
    end
  end

  defp old_enough?(_), do: false

  defp min_seconds, do: Application.get_env(:jan_paintings, __MODULE__, [])[:min_seconds] || 3

  @doc """
  The visitor's IP as a string. On Fly the proxy passes it in the
  Fly-Client-IP header (and overwrites any value the client sent).
  """
  def client_ip(conn) do
    case Plug.Conn.get_req_header(conn, "fly-client-ip") do
      [ip | _] -> ip
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end
