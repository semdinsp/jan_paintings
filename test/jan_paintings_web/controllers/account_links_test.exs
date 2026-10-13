defmodule JanPaintingsWeb.AccountLinksTest do
  use JanPaintingsWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "logged out" do
    test "pages link to the log in page", %{conn: conn} do
      html = conn |> get(~p"/") |> html_response(200)

      assert html =~ ~s(href="/users/log-in")
      refute html =~ "Log out"
    end
  end

  describe "logged in" do
    setup :register_and_log_in_user

    test "controller pages show the account and log out links", %{conn: conn, user: user} do
      for path <- [
            ~p"/",
            ~p"/about",
            ~p"/prints/old-masters/#{hd(JanPaintings.Catalog.list_prints("old-masters")).slug}"
          ] do
        html = conn |> get(path) |> html_response(200)

        assert html =~ user.email
        assert html =~ ~s(href="/users/settings")
        assert html =~ "Log out"
        refute html =~ ~s(href="/users/log-in")
      end
    end

    test "the print list LiveView knows who is logged in", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/prints")

      assert html =~ user.email
      assert html =~ "Log out"
    end
  end
end
