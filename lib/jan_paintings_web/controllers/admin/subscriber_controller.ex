defmodule JanPaintingsWeb.Admin.SubscriberController do
  @moduledoc "The mailing list signups, for the admin pages: list, download and remove."
  use JanPaintingsWeb, :controller

  alias JanPaintings.Inquiries

  def index(conn, _params) do
    render(conn, :index,
      page_title: "Admin · Mailing list",
      subscribers: Inquiries.list_subscribers()
    )
  end

  def export(conn, _params) do
    filename = "jan-johnson-mailing-list-#{Date.utc_today()}.csv"

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, Inquiries.subscribers_csv(Inquiries.list_subscribers()))
  end

  def delete(conn, %{"id" => id}) do
    subscriber = Inquiries.get_subscriber!(id)
    {:ok, _} = Inquiries.delete_subscriber(subscriber)

    conn
    |> put_flash(:info, "#{subscriber.email} is off the mailing list.")
    |> redirect(to: ~p"/admin/mailing-list")
  end
end
