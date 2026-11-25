defmodule JanPaintingsWeb.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Sends a Content-Security-Policy header on browser pages.

  Scripts run only from this site, plus inline scripts carrying the
  per-request nonce in `conn.assigns.csp_nonce` (the theme script in the root
  layout). Inline styles stay allowed: LiveView and the campaign email preview
  (an iframe that inherits this policy) rely on them. Images may also come from
  any https URL (campaign emails can link outside images) and from blob: URLs
  (upload previews in the admin pages). Cloudflare Turnstile's script and
  frame (the spam check on the public forms) come from challenges.cloudflare.com.

  The /dev tools (LiveDashboard, the Swoosh mailbox) inline their own scripts,
  so they are left without a policy; they exist only in development.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{request_path: "/dev/" <> _} = conn, _opts), do: conn

  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64()

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header("content-security-policy", policy(nonce))
  end

  @doc "The policy, for a given script nonce."
  def policy(nonce) do
    Enum.join(
      [
        "default-src 'self'",
        "script-src 'self' 'nonce-#{nonce}' https://challenges.cloudflare.com",
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
        "font-src 'self' https://fonts.gstatic.com",
        "img-src 'self' data: blob: https:",
        "connect-src 'self'",
        "frame-src https://challenges.cloudflare.com",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "frame-ancestors 'self'"
      ],
      "; "
    )
  end
end
