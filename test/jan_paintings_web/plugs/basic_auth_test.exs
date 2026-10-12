defmodule JanPaintingsWeb.Plugs.BasicAuthTest do
  # Not async: these tests change application config.
  use JanPaintingsWeb.ConnCase, async: false

  setup do
    previous = Application.get_env(:jan_paintings, :basic_auth)
    Application.put_env(:jan_paintings, :basic_auth, username: "jan", password: "secret")
    on_exit(fn -> Application.put_env(:jan_paintings, :basic_auth, previous) end)
  end

  test "asks for a password without credentials", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert conn.status == 401
    assert get_resp_header(conn, "www-authenticate") == [~s(Basic realm="Jan Johnson Prints")]
  end

  test "rejects the wrong password", %{conn: conn} do
    conn = conn |> put_auth("jan", "wrong") |> get(~p"/prints")
    assert conn.status == 401
  end

  test "lets the right username and password in", %{conn: conn} do
    conn = conn |> put_auth("jan", "secret") |> get(~p"/prints")
    assert html_response(conn, 200) =~ "All Prints"
  end

  test "is off when no password is configured", %{conn: conn} do
    Application.put_env(:jan_paintings, :basic_auth, username: "jan", password: nil)
    assert conn |> get(~p"/") |> html_response(200)
  end

  defp put_auth(conn, user, pass),
    do: put_req_header(conn, "authorization", Plug.BasicAuth.encode_basic_auth(user, pass))
end
