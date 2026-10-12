defmodule JanPaintingsWeb.ContactControllerTest do
  use JanPaintingsWeb.ConnCase

  import Swoosh.TestAssertions

  alias JanPaintings.{Catalog, Inquiries}

  @valid %{
    "name" => "Ada Collector",
    "email" => "ada@example.com",
    "phone" => "555 0100",
    "subject" => "Durer woodcuts",
    "message" => "Do you have any Durer woodcuts in stock?",
    "website" => ""
  }

  test "about page shows contact details and links to the form", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ "189 rue Saint-Pierre"
    assert html =~ "450.658.2752"
    assert html =~ ~s(href="tel:+15146086959")
    refute html =~ ~r/fax/i
    assert html =~ ~s(href="/contact")
  end

  test "contact page renders the form", %{conn: conn} do
    html = conn |> get(~p"/contact") |> html_response(200)
    assert html =~ ~s(id="contact-form")
    assert html =~ "Send message"
  end

  test "enquiring about a print prefills the subject", %{conn: conn} do
    print = hd(Catalog.list_prints("modern"))
    html = conn |> get(~p"/contact?#{[print: print.slug]}") |> html_response(200)

    assert html =~ Phoenix.HTML.html_escape(print.title) |> Phoenix.HTML.safe_to_string()
    assert html =~ ~s(value="#{print.slug}")
  end

  test "a valid message is stored and the gallery is emailed", %{conn: conn} do
    conn = post(conn, ~p"/contact", contact_message: @valid)

    assert redirected_to(conn) == ~p"/contact"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "your message has been sent"

    assert [message] = Inquiries.list_contact_messages()
    assert message.email == "ada@example.com"

    assert_email_sent(fn email ->
      assert email.to == [{"Jan Johnson", "jan@janjohnsonprints.com"}]
      assert email.reply_to == {"Ada Collector", "ada@example.com"}
      assert email.text_body =~ "Durer woodcuts in stock"
    end)
  end

  test "an invalid message re-renders with errors", %{conn: conn} do
    conn =
      post(conn, ~p"/contact", contact_message: %{@valid | "email" => "nope", "message" => ""})

    html = html_response(conn, 422)
    assert html =~ "must be a valid email"
    assert html =~ "can&#39;t be blank"
    assert Inquiries.list_contact_messages() == []
    assert_no_email_sent()
  end

  test "the spam trap silently drops the message", %{conn: conn} do
    conn = post(conn, ~p"/contact", contact_message: %{@valid | "website" => "http://spam"})

    assert redirected_to(conn) == ~p"/contact"
    assert Inquiries.list_contact_messages() == []
    assert_no_email_sent()
  end
end
