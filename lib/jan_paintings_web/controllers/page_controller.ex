defmodule JanPaintingsWeb.PageController do
  use JanPaintingsWeb, :controller

  import Phoenix.Component, only: [to_form: 1]

  alias JanPaintings.{Catalog, Inquiries}
  alias JanPaintings.Inquiries.ContactMessage
  alias JanPaintingsWeb.SEO

  def home(conn, _params) do
    render(conn, :home,
      canonical_path: "/",
      json_ld: SEO.gallery_json_ld(),
      tiles: home_tiles(),
      hero: Catalog.get_print("pether-a-farriers-shop-after-joseph-wright-of-derby"),
      featured: Catalog.featured_prints()
    )
  end

  # Large image links on the homepage, one per section of the site.
  defp home_tiles do
    [
      %{
        label: "All Prints",
        path: ~p"/prints",
        image: "/images/catalogue/lepere-650.jpg",
        position: "object-right-top"
      },
      %{
        label: "Old Master Prints",
        path: ~p"/prints/old-masters",
        image: "/images/catalogue/durer-st-george-day-650.jpg",
        position: "object-center"
      },
      %{
        label: "Modern Prints",
        path: ~p"/prints/modern",
        image: "/images/catalogue/chahine-edgar-invitation-lg.jpg",
        position: "object-top"
      },
      %{
        label: "Canadian Prints",
        path: ~p"/prints/canadian",
        image: "/images/catalogue/hornyansky-anxiety-650.jpg",
        position: "object-left"
      },
      %{
        label: "About the Gallery",
        path: ~p"/about",
        image: "/images/catalogue/jan-green-jacket.jpg",
        position: "object-top"
      }
    ]
  end

  def about(conn, params) do
    print = params["print"] && Catalog.get_print(params["print"])

    attrs =
      if print,
        do: %{"subject" => "#{print.artist}, #{print.title}", "print_slug" => print.slug},
        else: %{}

    form = %ContactMessage{} |> Inquiries.change_contact_message(attrs) |> to_form()
    render(conn, :about, [form: form] ++ about_meta())
  end

  defp about_meta do
    [
      page_title: "About the gallery",
      meta_description:
        "Jan Johnson has dealt in fine prints since 1979, first in London and from 1982 in Montreal. Visit by appointment in Chambly, Quebec, or send an enquiry.",
      canonical_path: "/about",
      json_ld: SEO.gallery_json_ld()
    ]
  end

  # The old contact page now lives on the about page; keep links working.
  def contact_redirect(conn, params) do
    query = Map.take(params, ["print"])
    redirect(conn, to: ~p"/about?#{query}" <> "#contact")
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
        |> render(:about, [form: to_form(changeset)] ++ about_meta())
    end
  end

  defp message_sent(conn) do
    conn
    |> put_flash(:info, "Thank you, your message has been sent. We'll be in touch soon.")
    |> redirect(to: ~p"/about" <> "#contact")
  end
end
