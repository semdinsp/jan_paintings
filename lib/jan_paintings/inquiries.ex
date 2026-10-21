defmodule JanPaintings.Inquiries do
  @moduledoc """
  Messages submitted through the website's contact form, and mailing list
  signups.

  Each message is stored so it can be followed up, and a notification
  email is sent to the gallery. Signups are stored, one per email address.
  """

  import Ecto.Query, warn: false

  alias JanPaintings.Repo
  alias JanPaintings.Inquiries.{ContactMessage, Notifier, Subscriber}

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

  def change_subscriber(%Subscriber{} = subscriber, attrs \\ %{}) do
    Subscriber.changeset(subscriber, attrs)
  end

  @doc """
  Adds an email address to the mailing list. Signing up again with an
  address already on the list succeeds and keeps the existing entry.
  """
  def subscribe(attrs) do
    %Subscriber{}
    |> Subscriber.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing, conflict_target: :email)
  end

  def list_subscribers do
    Repo.all(from s in Subscriber, order_by: [desc: s.inserted_at, desc: s.id])
  end

  def get_subscriber!(id), do: Repo.get!(Subscriber, id)

  @doc "Takes someone off the mailing list, e.g. when they ask to unsubscribe."
  def delete_subscriber(%Subscriber{} = subscriber), do: Repo.delete(subscriber)

  @doc """
  The subscribers as CSV text (iodata), with a header row.

  The values were typed in by the public, so any that a spreadsheet would
  run as a formula (starting with =, +, -, @, tab or return) get a leading
  apostrophe.
  """
  def subscribers_csv(subscribers) do
    rows =
      Enum.map(subscribers, fn s ->
        [s.email, s.name || "", s.interests || "", Calendar.strftime(s.inserted_at, "%Y-%m-%d")]
        |> Enum.map(&csv_safe/1)
      end)

    NimbleCSV.RFC4180.dump_to_iodata([["email", "name", "interests", "signed_up"] | rows])
  end

  defp csv_safe(<<first, _::binary>> = value) when first in ~c"=+-@\t\r", do: "'" <> value
  defp csv_safe(value), do: value
end
