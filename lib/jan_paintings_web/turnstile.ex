defmodule JanPaintingsWeb.Turnstile do
  @moduledoc """
  Cloudflare Turnstile, the "are you human" check on the public forms.

  Turnstile works without the site being behind Cloudflare. It is on when both
  keys are set (TURNSTILE_SITE_KEY and TURNSTILE_SECRET_KEY in production);
  with no keys, as in development and tests, `enabled?/0` is false and every
  submission passes this check.
  """

  require Logger

  @verify_url "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  @doc "The public site key for the widget, or nil when Turnstile is off."
  def site_key, do: if(enabled?(), do: config()[:site_key])

  def enabled?,
    do: config()[:site_key] not in [nil, ""] and config()[:secret_key] not in [nil, ""]

  @doc """
  Asks Cloudflare whether the widget's token is good. A missing token fails.
  If Cloudflare can't be reached the submission is let through (and logged),
  so an outage there doesn't block real enquiries.
  """
  def valid?(token, remote_ip) do
    cond do
      not enabled?() -> true
      token in [nil, ""] -> false
      true -> verify(token, remote_ip)
    end
  end

  defp verify(token, remote_ip) do
    request =
      Req.new(
        [url: @verify_url, retry: false, receive_timeout: 5_000] ++
          (config()[:req_options] || [])
      )

    case Req.post(request,
           form: [secret: config()[:secret_key], response: token, remoteip: remote_ip]
         ) do
      {:ok, %{status: 200, body: %{"success" => success}}} ->
        success == true

      other ->
        Logger.warning("[Turnstile] verification unavailable: #{inspect(other)}")
        true
    end
  end

  defp config, do: Application.get_env(:jan_paintings, __MODULE__, [])
end
