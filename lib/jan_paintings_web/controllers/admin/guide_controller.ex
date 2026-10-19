defmodule JanPaintingsWeb.Admin.GuideController do
  @moduledoc "How-to guides for the admin pages: adding prints and editing them."
  use JanPaintingsWeb, :controller

  def index(conn, _params), do: render(conn, :index, page_title: "Admin · Guides")

  def adding(conn, _params),
    do: render(conn, :adding, page_title: "Admin · Guide to adding prints")

  def editing(conn, _params),
    do: render(conn, :editing, page_title: "Admin · Guide to editing prints")
end
