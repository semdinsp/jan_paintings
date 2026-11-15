defmodule JanPaintingsWeb.Plugs.ContentSecurityPolicyTest do
  use JanPaintingsWeb.ConnCase, async: true

  alias JanPaintingsWeb.Plugs.ContentSecurityPolicy

  defp csp(conn), do: conn |> get_resp_header("content-security-policy") |> List.first()

  defp nonce_in_header(header) do
    [nonce] = Regex.run(~r/script-src 'self' 'nonce-([^']+)'/, header, capture: :all_but_first)
    nonce
  end

  test "browser pages send the policy, and the inline theme script carries its nonce", %{
    conn: conn
  } do
    conn = get(conn, ~p"/about")
    header = csp(conn)

    assert header =~ "default-src 'self'"
    assert header =~ "object-src 'none'"
    assert header =~ "frame-ancestors 'self'"
    assert header =~ "https://fonts.googleapis.com"
    assert header =~ "https://fonts.gstatic.com"
    refute header =~ "'unsafe-eval'"
    refute header =~ ~r/script-src[^;]*'unsafe-inline'/

    nonce = nonce_in_header(header)
    assert html_response(conn, 200) =~ ~s(<script nonce="#{nonce}">)
  end

  test "each request gets a fresh nonce", %{conn: conn} do
    first = conn |> get(~p"/") |> csp() |> nonce_in_header()
    second = build_conn() |> get(~p"/") |> csp() |> nonce_in_header()
    assert first != second
  end

  test "an error page raised after the policy is set still gets a matching nonce", %{conn: conn} do
    {404, headers, body} =
      assert_error_sent(404, fn -> get(conn, "/prints/old-masters/no-such-print") end)

    {_, header} = List.keyfind(headers, "content-security-policy", 0)
    assert body =~ ~s(<script nonce="#{nonce_in_header(header)}">)
  end

  test "the /dev tools are left without a policy" do
    conn = Plug.Test.conn(:get, "/dev/mailbox") |> ContentSecurityPolicy.call([])
    assert get_resp_header(conn, "content-security-policy") == []
    refute Map.has_key?(conn.assigns, :csp_nonce)
  end
end
