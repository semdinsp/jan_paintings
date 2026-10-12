defmodule JanPaintings.Inquiries.Notifier do
  import Swoosh.Email

  require Logger

  alias JanPaintings.Mailer
  alias JanPaintings.Inquiries.ContactMessage

  @doc "Emails the gallery about a new contact form message."
  def deliver_new_message(%ContactMessage{} = message) do
    email =
      new()
      |> to(config(:to))
      |> from(config(:from))
      |> reply_to({message.name, message.email})
      |> subject("Website enquiry: #{message.subject || message.name}")
      |> text_body("""
      New message from the website contact form.

      Name:    #{message.name}
      Email:   #{message.email}
      Phone:   #{message.phone || "-"}
      Subject: #{message.subject || "-"}

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

  defp config(key) do
    :jan_paintings |> Application.fetch_env!(__MODULE__) |> Keyword.fetch!(key)
  end
end
