defmodule JanPaintings.Repo do
  use Ecto.Repo,
    otp_app: :jan_paintings,
    adapter: Ecto.Adapters.Postgres
end
