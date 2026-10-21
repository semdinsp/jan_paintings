defmodule JanPaintingsWeb.MailingListControllerTest do
  use JanPaintingsWeb.ConnCase

  alias JanPaintings.Inquiries

  @valid %{"email" => "collector@example.com", "name" => "A Collector", "interests" => "Dürer"}

  test "the Contact section has the mailing list form", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ ~s(id="mailing-list")

    assert html =~
             ~r/<form[^>]*action="\/mailing-list"[^>]*method="post"|<form[^>]*method="post"[^>]*action="\/mailing-list"/

    assert html =~ ~s(name="subscriber[email]")
    assert html =~ ~s(href="/about#mailing-list")
  end

  test "signing up saves the subscriber and thanks them", %{conn: conn} do
    conn = post(conn, ~p"/mailing-list", subscriber: @valid)

    assert redirected_to(conn) == "/about#mailing-list"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "mailing list"

    assert [subscriber] = Inquiries.list_subscribers()
    assert subscriber.email == "collector@example.com"
    assert subscriber.name == "A Collector"
    assert subscriber.interests == "Dürer"
  end

  test "signing up again with the same email, in any case, keeps one entry", %{conn: conn} do
    post(conn, ~p"/mailing-list", subscriber: @valid)
    conn = post(conn, ~p"/mailing-list", subscriber: %{"email" => " Collector@Example.com "})

    assert redirected_to(conn) == "/about#mailing-list"
    assert [%{name: "A Collector"}] = Inquiries.list_subscribers()
  end

  test "an invalid email shows the error and saves nothing", %{conn: conn} do
    conn = post(conn, ~p"/mailing-list", subscriber: %{"email" => "nope"})

    html = html_response(conn, 422)
    assert html =~ "must be a valid email"
    # The contact form is still there, empty.
    assert html =~ ~s(id="contact-form")
    assert Inquiries.list_subscribers() == []
  end

  test "a filled-in spam trap pretends to work but saves nothing", %{conn: conn} do
    conn = post(conn, ~p"/mailing-list", subscriber: Map.put(@valid, "website", "http://spam"))

    assert redirected_to(conn) == "/about#mailing-list"
    assert Inquiries.list_subscribers() == []
  end

  test "a contact form error still shows the mailing list form", %{conn: conn} do
    conn = post(conn, ~p"/about", contact_message: %{"email" => "nope"})
    assert html_response(conn, 422) =~ ~s(id="mailing-list-form")
  end
end
