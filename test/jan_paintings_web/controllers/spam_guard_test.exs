defmodule JanPaintingsWeb.SpamGuardTest do
  # Changes application config, so not async.
  use JanPaintingsWeb.ConnCase, async: false

  alias JanPaintings.Inquiries
  alias JanPaintingsWeb.{RateLimit, SpamGuard, Turnstile}

  @message %{
    "name" => "Ada Collector",
    "email" => "ada@example.com",
    "message" => "Do you have any Durer woodcuts in stock?",
    "website" => ""
  }

  defp put_config(module, config) do
    previous = Application.get_env(:jan_paintings, module)
    Application.put_env(:jan_paintings, module, config)
    on_exit(fn -> Application.put_env(:jan_paintings, module, previous) end)
  end

  defp seconds_ago(n), do: SpamGuard.form_token(System.system_time(:second) - n)

  describe "form fill time" do
    setup do
      put_config(SpamGuard, min_seconds: 3)
    end

    test "a message posted without the form's started field is dropped", %{conn: conn} do
      conn = post(conn, ~p"/contact", contact_message: @message)
      assert redirected_to(conn) == "/contact"
      assert Inquiries.list_contact_messages() == []
    end

    test "a message sent within seconds of loading the form is dropped", %{conn: conn} do
      conn =
        post(conn, ~p"/contact", contact_message: Map.put(@message, "started", seconds_ago(0)))

      assert redirected_to(conn) == "/contact"
      assert Inquiries.list_contact_messages() == []
    end

    test "a forged started field is dropped", %{conn: conn} do
      post(conn, ~p"/contact", contact_message: Map.put(@message, "started", "1700000000"))
      assert Inquiries.list_contact_messages() == []
    end

    test "a message sent after a normal pause is stored", %{conn: conn} do
      conn =
        post(conn, ~p"/contact", contact_message: Map.put(@message, "started", seconds_ago(20)))

      assert redirected_to(conn) == "/contact"
      assert [_] = Inquiries.list_contact_messages()
    end

    test "the mailing list form has the same check", %{conn: conn} do
      post(conn, ~p"/mailing-list",
        subscriber: %{"email" => "a@example.com", "started" => seconds_ago(0)}
      )

      assert Inquiries.list_subscribers() == []
    end
  end

  test "the contact page carries a started field in both forms", %{conn: conn} do
    html = conn |> get(~p"/contact") |> html_response(200)
    assert html =~ ~s(name="contact_message[started]")
    assert html =~ ~s(name="subscriber[started]")
  end

  test "too many submissions from one IP are refused", %{conn: conn} do
    put_config(RateLimit, limit: 1, window_seconds: 600)
    ip = "203.0.113.#{System.unique_integer([:positive]) |> rem(250)}"
    params = Map.put(@message, "started", seconds_ago(20))

    first =
      conn |> put_req_header("fly-client-ip", ip) |> post(~p"/contact", contact_message: params)

    assert redirected_to(first) == "/contact"

    second =
      build_conn()
      |> put_req_header("fly-client-ip", ip)
      |> post(~p"/contact", contact_message: params)

    assert html_response(second, 429) =~ "Too many messages"
    assert [_] = Inquiries.list_contact_messages()
  end

  describe "Turnstile" do
    setup do
      put_config(Turnstile,
        site_key: "site-key-123",
        secret_key: "secret",
        req_options: [plug: {Req.Test, Turnstile}]
      )
    end

    defp cloudflare_says(success) do
      Req.Test.stub(Turnstile, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        send(self(), {:verify_body, URI.decode_query(body)})
        Req.Test.json(conn, %{"success" => success})
      end)
    end

    defp post_message(conn, token) do
      post(conn, ~p"/contact",
        contact_message: Map.put(@message, "started", seconds_ago(20)),
        "cf-turnstile-response": token
      )
    end

    test "the contact page shows the widget and allows Cloudflare's script", %{conn: conn} do
      conn = get(conn, ~p"/contact")
      html = html_response(conn, 200)
      assert html =~ ~s(data-sitekey="site-key-123")
      assert html =~ "challenges.cloudflare.com/turnstile/v0/api.js"

      [csp] = get_resp_header(conn, "content-security-policy")
      assert csp =~ "script-src 'self' 'nonce-"
      assert csp =~ "https://challenges.cloudflare.com"
      assert csp =~ "frame-src https://challenges.cloudflare.com"
    end

    test "a message Cloudflare accepts is stored", %{conn: conn} do
      cloudflare_says(true)
      conn = post_message(conn, "good-token")

      assert redirected_to(conn) == "/contact"
      assert [_] = Inquiries.list_contact_messages()
      assert_received {:verify_body, %{"secret" => "secret", "response" => "good-token"}}
    end

    test "a message Cloudflare rejects is shown again with a note", %{conn: conn} do
      cloudflare_says(false)
      conn = post_message(conn, "bad-token")

      html = html_response(conn, 422)
      assert html =~ "Please complete the check"
      assert html =~ "Durer woodcuts"
      assert Inquiries.list_contact_messages() == []
    end

    test "a message without the widget's token is refused", %{conn: conn} do
      conn = post_message(conn, "")
      assert html_response(conn, 422) =~ "Please complete the check"
      assert Inquiries.list_contact_messages() == []
    end
  end
end
