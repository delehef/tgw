defmodule Tgw.Pglistener do
  require Logger
  use GenServer

  @pg_channel "status_updates"
  @pubsub_channel "status_updates"

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def init(_) do
    {:ok, pid} = Postgrex.Notifications.start_link(Tgw.Repo.config())
    {:ok, ref} = Postgrex.Notifications.listen(pid, @pg_channel)
    {:ok, {pid, ref}}
  end

  def handle_info({:notification, _pid, _ref, channel, payload}, state) do
    Logger.debug("Received a PgSQL notification: #{channel}/#{payload}")
    Phoenix.PubSub.broadcast!(Tgw.PubSub, @pubsub_channel, {:notification, payload})
    {:noreply, state}
  end
end
