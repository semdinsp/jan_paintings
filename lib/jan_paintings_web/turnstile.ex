defmodule JanPaintingsWeb.Turnstile do
  @moduledoc """
  Cloudflare Turnstile, the "are you human" check on the public forms.

  Turnstile works without the site being behind Cloudflare. It is on when both
  keys are set (TURNSTILE_SITE_KEY and TURNSTILE_SECRET_KEY in production);
  with no keys, as in development and tests, `enabled?/0` is false and every
  submission passes this check. TURNSTILE_HOSTNAMES (comma-separated) lists
  the hostnames a token may come from; it defaults to PHX_HOST.
  """

  require Logger

  @verify_url "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  @doc "The public site key for the widget, or nil when Turnstile is off."
  def site_key, do: if(enabled?(), do: config()[:site_key])

  def enabled?,
    do: config()[:site_key] not in [nil, ""] and config()[:secret_key] not in [nil, ""]

  @doc """
  Asks Cloudflare whether the widget's token is good for this form.

  It passes only when Cloudflare says `success`, the token was issued for the
  same `action` as the form's widget ("contact" or "mailing-list"), and for
  one of the site's hostnames. A missing or overlong token fails without
  asking, and so does any error reaching Cloudflare.
  """
  def valid?(token, action, remote_ip) do
    cond do
      not enabled?() -> true
      not is_binary(token) or token == "" or byte_size(token) > 2048 -> false
      hostnames() == [] -> false
      true -> verify(token, action, remote_ip)
    end
  end

  defp verify(token, action, remote_ip) do
    request =
      Req.new(
        [url: @verify_url, retry: false, receive_timeout: 10_000] ++
          (config()[:req_options] || [])
      )

    case Req.post(request,
           form: [secret: config()[:secret_key], response: token, remoteip: remote_ip]
         ) do
      {:ok, %{status: 200, body: %{"success" => true} = body}} ->
        body["action"] == action and body["hostname"] in hostnames()

      {:ok, %{status: 200, body: %{"error-codes" => codes}}} ->
        if "invalid-input-secret" in codes,
          do: Logger.error("[Turnstile] secret key rejected: check TURNSTILE_SECRET_KEY")

        false

      other ->
        Logger.warning("[Turnstile] verification failed: #{inspect(other)}")
        false
    end
  end

  defp hostnames, do: config()[:hostnames] || []

  defp config, do: Application.get_env(:jan_paintings, __MODULE__, [])
end
