# Start each run without images uploaded by earlier runs.
File.rm_rf!(Application.fetch_env!(:jan_paintings, :uploads_dir))

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(JanPaintings.Repo, :manual)
