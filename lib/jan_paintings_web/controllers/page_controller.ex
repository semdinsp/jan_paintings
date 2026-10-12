defmodule JanPaintingsWeb.PageController do
  use JanPaintingsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
