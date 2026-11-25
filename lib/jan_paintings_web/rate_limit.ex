defmodule JanPaintingsWeb.RateLimit do
  @moduledoc """
  Counts public form submissions per IP address in a fixed time window, in an
  ETS table owned by this process. Counts live in memory only, so they reset
  on a deploy, which is fine for spam control.

  Configured with `config :jan_paintings, JanPaintingsWeb.RateLimit,
  limit: 10, window_seconds: 600`.
  """
  use GenServer

  @table __MODULE__

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc "Records a submission from `ip` and says whether it is within the limit."
  def allow?(ip) do
    {limit, window} = settings()
    key = {ip, div(System.system_time(:second), window)}
    :ets.update_counter(@table, key, 1, {key, 0}) <= limit
  end

  defp settings do
    config = Application.get_env(:jan_paintings, __MODULE__, [])
    {Keyword.get(config, :limit, 10), Keyword.get(config, :window_seconds, 600)}
  end

  @impl true
  def init(nil) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    :timer.send_interval(:timer.minutes(10), :sweep)
    {:ok, nil}
  end

  # Drop counts from past windows.
  @impl true
  def handle_info(:sweep, state) do
    {_, window} = settings()
    current = div(System.system_time(:second), window)
    :ets.select_delete(@table, [{{{:_, :"$1"}, :_}, [{:<, :"$1", current}], [true]}])
    {:noreply, state}
  end
end
