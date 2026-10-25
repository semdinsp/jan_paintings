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

  test "the contact page shows contact details and the form", %{conn: conn} do
    html = conn |> get(~p"/contact") |> html_response(200)
    assert html =~ ~r/<h1[^>]*>Contact Us<\/h1>/
    assert html =~ ~s(id="contact")
    assert html =~ "189 rue Saint-Pierre"
    assert html =~ "450.658.2752"
    assert html =~ ~s(href="tel:+15146086959")
    refute html =~ ~r/fax/i
    assert html =~ ~s(id="contact-form")
    assert html =~ "Send message"

    assert html =~
             ~r/<form[^>]*action="\/contact"[^>]*id="contact-form"|<form[^>]*id="contact-form"[^>]*action="\/contact"/

    assert html =~ ~r{<link[^>]*rel="canonical"[^>]*href="[^"]*/contact"}
  end

  test "the contact page shows the terms of sale under the contact section", %{conn: conn} do
    html = conn |> get(~p"/contact") |> html_response(200)

    [terms] =
      Regex.run(~r{<section[^>]*id="contact-terms".*?</section>\s*</div>\s*</section>}s, html)

    assert terms =~ ~r/<h2[^>]*>Terms of sale<\/h2>/

    for heading <- ["Authenticity", "Prints on approval", "Packing and shipping", "Payment"] do
      assert terms =~ ~r/<h3[^>]*>#{heading}<\/h3>/
    end

    assert String.replace(terms, ~r/\s+/, " ") =~ "credit cards during 2027"
  end

  test "the about page no longer has the contact details or forms", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    refute html =~ ~s(id="contact-form")
    refute html =~ ~s(id="mailing-list-form")
  end

  test "old print enquiry links to the about page go to the contact page", %{conn: conn} do
    assert conn |> get(~p"/about?print=some-print") |> redirected_to() ==
             "/contact?print=some-print"
  end

  test "enquiring about a print prefills the subject", %{conn: conn} do
    print = hd(Catalog.list_prints("modern"))
    html = conn |> get(~p"/contact?#{[print: print.slug]}") |> html_response(200)

    assert html =~ Phoenix.HTML.html_escape(print.title) |> Phoenix.HTML.safe_to_string()
    assert html =~ ~s(value="#{print.slug}")
  end

  test "a form loaded before the move still posts to /about", %{conn: conn} do
    conn = post(conn, ~p"/about", contact_message: @valid)
    assert redirected_to(conn) == "/contact"
    assert [_] = Inquiries.list_contact_messages()
  end

  test "a valid message is stored and the gallery is emailed", %{conn: conn} do
    conn = post(conn, ~p"/contact", contact_message: @valid)

    assert redirected_to(conn) == "/contact"
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

    assert redirected_to(conn) == "/contact"
    assert Inquiries.list_contact_messages() == []
    assert_no_email_sent()
  end
end
