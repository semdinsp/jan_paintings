defmodule JanPaintingsWeb.Admin.CustomerContactTest do
  use JanPaintingsWeb.ConnCase

  import Phoenix.LiveViewTest
  import JanPaintings.AccountsFixtures

  alias JanPaintings.{Accounts, CustomerContactHost, Inquiries}

  @pages ["/admin/contact", "/admin/contact/audience", "/admin/contact/campaigns/new"]

  test "visitors and non-admins are sent away from the campaign pages", %{conn: conn} do
    for path <- @pages do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, path)

      user_conn = log_in_user(build_conn(), user_fixture())
      assert {:error, {:redirect, %{to: "/"}}} = live(user_conn, path)
    end
  end

  test "admins can open the campaign pages", %{conn: conn} do
    {:ok, admin} = Accounts.set_admin(user_fixture(), true)
    conn = log_in_user(conn, admin)

    for path <- @pages do
      assert {:ok, _view, html} = live(conn, path)
      # The header's home icon goes back to the admin prints page.
      assert html =~ ~s(href="/admin/prints")
    end
  end

  test "the admin prints page links to the campaign pages", %{conn: conn} do
    {:ok, admin} = Accounts.set_admin(user_fixture(), true)
    {:ok, _view, html} = conn |> log_in_user(admin) |> live(~p"/admin/prints")
    assert html =~ ~s(href="/admin/contact")
  end

  test "recipients are the mailing list subscribers, with string refs" do
    {:ok, a} = Inquiries.subscribe(%{"email" => "a@example.com", "name" => "Ann"})
    {:ok, b} = Inquiries.subscribe(%{"email" => "b@example.com"})

    assert [
             %CustomerContact.Recipient{ref: ref_a, email: "a@example.com", name: "Ann"},
             %CustomerContact.Recipient{ref: ref_b, email: "b@example.com", name: nil}
           ] = CustomerContactHost.list_recipients()

    assert ref_a == to_string(a.id)
    assert ref_b == to_string(b.id)
  end

  test "the brand uses the gallery's name, address and email colours" do
    brand = CustomerContactHost.brand()
    assert {"Jan Johnson Prints", "jan@janjohnsonprints.com"} = brand.from
    assert brand.postal_address =~ "J3L 1L8"
    assert brand.primary_color == "#c2918d"
  end

  test "the open pixel works without a session or the site password", %{conn: conn} do
    Application.put_env(:jan_paintings, :basic_auth, username: "jan", password: "secret")
    on_exit(fn -> Application.put_env(:jan_paintings, :basic_auth, []) end)

    conn = get(conn, "/cc/o/anything.gif")
    assert response(conn, 200)
    assert response_content_type(conn, :gif) =~ "image/gif"
  end
end
