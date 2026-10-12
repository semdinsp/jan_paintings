defmodule JanPaintings.Inquiries do
  @moduledoc """
  Messages submitted through the website's contact form.

  Each message is stored so it can be followed up, and a notification
  email is sent to the gallery.
  """

  import Ecto.Query, warn: false

  alias JanPaintings.Repo
  alias JanPaintings.Inquiries.{ContactMessage, Notifier}

  def change_contact_message(%ContactMessage{} = message, attrs \\ %{}) do
    ContactMessage.changeset(message, attrs)
  end

  @doc """
  Saves a contact message and emails the gallery about it.

  The notification is best-effort: a mail failure is logged but does not
  lose the stored message.
  """
  def create_contact_message(attrs) do
    with {:ok, message} <- %ContactMessage{} |> ContactMessage.changeset(attrs) |> Repo.insert() do
      Notifier.deliver_new_message(message)
      {:ok, message}
    end
  end

  def list_contact_messages do
    Repo.all(from m in ContactMessage, order_by: [desc: m.inserted_at])
  end
end
