defmodule JanPaintingsWeb.Admin.GuideControllerTest do
  use JanPaintingsWeb.ConnCase, async: true

  import JanPaintings.AccountsFixtures

  alias JanPaintings.Accounts

  @guides ["/admin/guides", "/admin/guides/adding-prints", "/admin/guides/editing-prints"]

  test "only admins can read the guides", %{conn: conn} do
    for path <- @guides do
      assert conn |> get(path) |> redirected_to() == ~p"/users/log-in"
      assert conn |> log_in_user(user_fixture()) |> get(path) |> redirected_to() == ~p"/"
    end
  end

  describe "as an admin" do
    setup %{conn: conn} do
      {:ok, admin} = Accounts.set_admin(user_fixture(), true)
      %{conn: log_in_user(conn, admin)}
    end

    test "the guides page links to both guides, each with its icon", %{conn: conn} do
      html = conn |> get(~p"/admin/guides") |> html_response(200)

      assert html =~ ~r/<a(?=[^>]*id="guide-adding")[^>]*href="\/admin\/guides\/adding-prints"/
      assert html =~ ~r/<a(?=[^>]*id="guide-editing")[^>]*href="\/admin\/guides\/editing-prints"/
      assert length(Regex.scan(~r/<svg[^>]*viewBox="0 0 64 64"/, html)) == 2
    end

    test "the adding guide explains drafts", %{conn: conn} do
      html = conn |> get(~p"/admin/guides/adding-prints") |> html_response(200)

      assert html =~ "Add one print"
      assert html =~ "Add many from a CSV"
      assert html =~ ~s(id="drafts")
      assert html =~ ~r/id="drafts-automatic".*automatically saved as a draft/s
      assert html =~ ~r/id="drafts-publish".*only appears on the site once it is out of draft/s
    end

    test "the editing guide covers status, details, photos and deleting", %{conn: conn} do
      html = conn |> get(~p"/admin/guides/editing-prints") |> html_response(200)

      for section <- ~w(find status details photos delete) do
        assert html =~ ~s(id="#{section}")
      end
    end
  end
end
