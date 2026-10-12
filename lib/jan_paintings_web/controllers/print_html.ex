defmodule JanPaintingsWeb.PrintHTML do
  use JanPaintingsWeb, :html

  import JanPaintingsWeb.PageHTML, only: [print_card: 1]

  embed_templates "print_html/*"
end
