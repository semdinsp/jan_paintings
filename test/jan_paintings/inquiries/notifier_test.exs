defmodule JanPaintings.Inquiries.NotifierTest do
  use JanPaintings.DataCase, async: true

  alias JanPaintings.Inquiries.{ContactMessage, Notifier}

  defp message(attrs) do
    struct!(
      %ContactMessage{
        id: 1,
        name: "Ada Collector",
        email: "ada@example.com",
        phone: nil,
        subject: nil,
        print_slug: nil,
        message: "Is this still available?"
      },
      attrs
    )
  end

  test "sends Jan a site-styled HTML email with a plain-text alternative" do
    {:ok, _} =
      Notifier.deliver_new_message(
        message(%{
          phone: "514 555 0100",
          subject: "Neilson etching",
          print_slug: "neilson-dredging-the-st-charles-river",
          message: "Hello Jan,\nIs it framed?\n\nThanks, Ada"
        })
      )

    assert_received {:email, email}
    assert email.subject == "Website enquiry: Neilson etching"
    assert email.reply_to == {"Ada Collector", "ada@example.com"}
    # jan@ is the verified SES identity.
    assert email.from == {"Jan Johnson Prints website", "jan@janjohnsonprints.com"}

    html = email.html_body
    assert html =~ "New enquiry from Ada Collector"
    assert html =~ ~s(href="mailto:ada@example.com")
    assert html =~ ~s(href="tel:5145550100")
    assert html =~ "/prints/canadian/neilson-dredging-the-st-charles-river"
    assert html =~ "Dredging the St. Charles River"

    assert html =~ ~r/Hello Jan,\s*<br\/?>\s*Is it framed\?/

    assert html =~ "Thanks, Ada"
    assert html =~ "Reply to Ada Collector"
    assert html =~ "mailto:ada@example.com?subject=Re%3A%20Neilson%20etching"

    assert email.text_body =~ "Name:    Ada Collector"
    assert email.text_body =~ "Print:   NEILSON"
    assert email.text_body =~ "Is it framed?"
  end

  test "leaves out empty details and escapes what the sender typed" do
    {:ok, _} =
      Notifier.deliver_new_message(message(%{name: "<script>x</script>", message: "<b>hi</b>"}))

    assert_received {:email, email}

    refute email.html_body =~ "<script>x</script>"
    refute email.html_body =~ "<b>hi</b>"
    assert email.html_body =~ "&lt;b&gt;hi&lt;/b&gt;"
    refute email.html_body =~ ">Phone<"
    refute email.html_body =~ ">Print<"
    refute email.text_body =~ "Print:"
  end
end
