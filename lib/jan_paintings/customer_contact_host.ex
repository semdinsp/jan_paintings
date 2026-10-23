defmodule JanPaintings.CustomerContactHost do
  @moduledoc """
  Tells CustomerContact (campaign email, at /admin/contact) who can be
  emailed and how the emails look.

  Recipients are everyone on the mailing list. There are no tags in this app,
  so campaigns use CustomerContact's built-in tags from its Audience page.
  """

  @behaviour CustomerContact.Host

  import Ecto.Query

  alias CustomerContact.Recipient
  alias JanPaintings.Inquiries.Subscriber
  alias JanPaintings.Repo

  # The same colours as JanPaintingsWeb.EmailHTML.
  @impl true
  def brand do
    base = JanPaintingsWeb.Endpoint.url()

    %{
      name: "Jan Johnson Prints",
      from: Application.fetch_env!(:jan_paintings, :campaign_from),
      reply_to: "jan@janjohnsonprints.com",
      postal_address: "189 rue Saint-Pierre, Chambly, QC, Canada J3L 1L8",
      website_url: base,
      logo_url: base <> "/images/jan-johnson-logo-ink.png",
      primary_color: "#a8436a",
      accent_color: "#1f1d1a",
      background_color: "#f1ede6"
    }
  end

  @impl true
  def list_recipients do
    from(s in Subscriber,
      order_by: s.id,
      select: %Recipient{ref: type(s.id, :string), email: s.email, name: s.name}
    )
    |> Repo.all()
  end
end
