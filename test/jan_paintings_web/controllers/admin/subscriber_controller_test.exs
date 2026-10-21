defmodule JanPaintingsWeb.Admin.SubscriberControllerTest do
  use JanPaintingsWeb.ConnCase

  import JanPaintings.AccountsFixtures

  alias JanPaintings.{Accounts, Inquiries}

  defp log_in_admin(%{conn: conn}) do
    {:ok, admin} = Accounts.set_admin(user_fixture(), true)
    %{conn: log_in_user(conn, admin)}
  end

  defp subscribe(attrs) do
    {:ok, subscriber} = Inquiries.subscribe(attrs)
    subscriber
  end

  test "only admins can see, download or change the list", %{conn: conn} do
    %{id: id} = subscribe(%{"email" => "a@example.com"})

    for {method, path} <- [
          get: ~p"/admin/mailing-list",
          get: ~p"/admin/mailing-list/export.csv",
          delete: ~p"/admin/mailing-list/#{id}"
        ] do
      assert dispatch(conn, @endpoint, method, path) |> redirected_to() == ~p"/users/log-in"

      user_conn = log_in_user(build_conn(), user_fixture())
      assert dispatch(user_conn, @endpoint, method, path) |> redirected_to() == ~p"/"
    end

    assert [_] = Inquiries.list_subscribers()
  end

  describe "as an admin" do
    setup :log_in_admin

    test "lists the subscribers, newest first", %{conn: conn} do
      subscribe(%{"email" => "first@example.com", "name" => "First", "interests" => "Dürer"})
      subscribe(%{"email" => "second@example.com"})

      html = conn |> get(~p"/admin/mailing-list") |> html_response(200)
      assert html =~ "2 people signed up"
      assert html =~ ~s(href="mailto:first@example.com")
      assert html =~ "Dürer"
      assert html =~ ~s(href="/admin/mailing-list/export.csv")

      {second, _} = :binary.match(html, "second@example.com")
      {first, _} = :binary.match(html, "first@example.com")
      assert second < first
    end

    test "says when no one has signed up", %{conn: conn} do
      html = conn |> get(~p"/admin/mailing-list") |> html_response(200)
      assert html =~ "No one has signed up yet."
      refute html =~ "Download CSV"
    end

    test "the prints page links to the mailing list", %{conn: conn} do
      html = conn |> get(~p"/admin/prints") |> html_response(200)
      assert html =~ ~s(href="/admin/mailing-list")
    end

    test "downloads the list as CSV, with formulas made harmless", %{conn: conn} do
      subscribe(%{
        "email" => "a@example.com",
        "name" => "=HYPERLINK(\"x\")",
        "interests" => "Etchings, mostly"
      })

      conn = get(conn, ~p"/admin/mailing-list/export.csv")
      assert response_content_type(conn, :csv) =~ "text/csv"
      assert get_resp_header(conn, "content-disposition") |> hd() =~ "jan-johnson-mailing-list-"

      [header, row] = conn |> response(200) |> NimbleCSV.RFC4180.parse_string(skip_headers: false)
      assert header == ["email", "name", "interests", "signed_up"]
      assert ["a@example.com", "'=HYPERLINK(\"x\")", "Etchings, mostly", date] = row
      assert date == Date.to_iso8601(Date.utc_today())
    end

    test "removes a subscriber", %{conn: conn} do
      %{id: id} = subscribe(%{"email" => "leaving@example.com"})
      subscribe(%{"email" => "staying@example.com"})

      conn = delete(conn, ~p"/admin/mailing-list/#{id}")
      assert redirected_to(conn) == ~p"/admin/mailing-list"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "leaving@example.com"
      assert [%{email: "staying@example.com"}] = Inquiries.list_subscribers()
    end
  end
end
