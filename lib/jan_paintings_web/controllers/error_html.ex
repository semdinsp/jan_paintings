defmodule JanPaintingsWeb.ErrorHTML do
  @moduledoc """
  Error pages for HTML requests (see `render_errors` in config/config.exs).

  404 and 500 have branded pages in error_html/, inside the site layout;
  any other status falls back to its plain status message.
  """
  use JanPaintingsWeb, :html

  embed_templates "error_html/*"

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
