defmodule JanPaintings.Inquiries.Notifier do
  import Swoosh.Email

  require Logger

  alias JanPaintings.Mailer
  alias JanPaintings.Catalog
  alias JanPaintings.Inquiries.ContactMessage
  alias JanPaintingsWeb.EmailHTML

  @doc """
  Emails the gallery about a new contact form message, as HTML styled like
  the website (`JanPaintingsWeb.EmailHTML`) with a plain-text alternative.
  Replying goes straight to the sender.
  """
  def deliver_new_message(%ContactMessage{} = message) do
    print = message.print_slug && Catalog.get_print(message.print_slug)

    print_link =
      print && {"#{print.artist}, #{Catalog.plain_title(print.title)}", print_url(print)}

    email =
      new()
      |> to(config(:to))
      |> from(config(:from))
      |> reply_to({message.name, message.email})
      |> subject("Website enquiry: #{message.subject || message.name}")
      |> html_body(
        EmailHTML.message_email(%{
          heading: "New enquiry from #{message.name}",
          intro: "A message came in through the contact form on the website.",
          details: [
            {"Name", message.name},
            {"Email", {message.email, "mailto:" <> message.email}},
            {"Phone", message.phone && {message.phone, tel_url(message.phone)}},
            {"Subject", message.subject},
            {"Print", print_link}
          ],
          message: message.message,
          button: {"Reply to #{message.name}", reply_url(message)}
        })
      )
      |> text_body("""
      New message from the website contact form.

      Name:    #{message.name}
      Email:   #{message.email}
      Phone:   #{message.phone || "-"}
      Subject: #{message.subject || "-"}
      #{if print, do: "Print:   #{print.artist}, #{Catalog.plain_title(print.title)}\n         #{print_url(print)}\n", else: ""}
      #{message.message}
      """)

    case Mailer.deliver(email) do
      {:ok, _} = ok ->
        ok

      {:error, reason} = error ->
        Logger.error("Contact message #{message.id} notification failed: #{inspect(reason)}")
        error
    end
  end

  defp print_url(print) do
    JanPaintingsWeb.Endpoint.url() <> "/prints/#{print.category}/#{print.slug}"
  end

  defp tel_url(phone), do: "tel:" <> String.replace(phone, ~r/[^\d+]/, "")

  defp reply_url(message) do
    subject = "Re: " <> (message.subject || "Your enquiry to Jan Johnson Prints")
    "mailto:#{message.email}?" <> URI.encode_query(%{"subject" => subject}, :rfc3986)
  end

  defp config(key) do
    :jan_paintings |> Application.fetch_env!(__MODULE__) |> Keyword.fetch!(key)
  end
end
