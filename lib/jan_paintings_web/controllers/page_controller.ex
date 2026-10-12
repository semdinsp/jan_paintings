defmodule JanPaintingsWeb.PageController do
  use JanPaintingsWeb, :controller

  import Phoenix.Component, only: [to_form: 1]

  alias JanPaintings.{Catalog, Inquiries}
  alias JanPaintings.Inquiries.ContactMessage

  def home(conn, _params) do
    categories = Enum.map(Catalog.categories(), &{&1, Catalog.cover_print(&1.slug)})

    render(conn, :home,
      categories: categories,
      hero: Catalog.get_print("pether-a-farriers-shop-after-joseph-wright-of-derby"),
      featured: Catalog.featured_prints()
    )
  end

  def about(conn, _params), do: render(conn, :about, page_title: "About")

  def contact(conn, params) do
    print = params["print"] && Catalog.get_print(params["print"])

    attrs =
      if print,
        do: %{"subject" => "#{print.artist}, #{print.title}", "print_slug" => print.slug},
        else: %{}

    form = %ContactMessage{} |> Inquiries.change_contact_message(attrs) |> to_form()
    render(conn, :contact, page_title: "Contact", form: form)
  end

  # Bots tend to fill every field, so a filled-in hidden "website" field
  # is treated as spam: pretend it worked and store nothing.
  def create_message(conn, %{"contact_message" => %{"website" => trap}})
      when trap != "" do
    message_sent(conn)
  end

  def create_message(conn, %{"contact_message" => params}) do
    case Inquiries.create_contact_message(params) do
      {:ok, _message} ->
        message_sent(conn)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:contact, page_title: "Contact", form: to_form(changeset))
    end
  end

  defp message_sent(conn) do
    conn
    |> put_flash(:info, "Thank you, your message has been sent. We'll be in touch soon.")
    |> redirect(to: ~p"/contact")
  end
end
