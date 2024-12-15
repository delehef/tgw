defmodule Tgw.Lagrange.DARA do
  require Logger
  use GenServer

  import Ecto.Query

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :DARA)
  end

  def debug() do
    GenServer.cast(:DARA, :debug)
  end

  def insert_worker(name, stream), do: GenServer.call(:DARA, {:new_worker, name, stream})

  @impl GenServer
  def init(state) do
    state =
      state
      |> Map.put_new(:interval, 15_000)
      |> Map.put_new(:schedule, schedule_work(15_000))
      |> Map.put_new(:workers, %{})

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    tasks = Tgw.Repo.all(from t in Tgw.Db.Task)
    # TODO: actually run DARA/ProofPHI
    {:noreply, Map.put(state, :schedule, schedule_work(state.interval))}
  end

  # We may receive some runtime-emitted messages we don't want to crah on.
  @impl GenServer
  def handle_info(_, state), do: {:noreply, state}

  @impl GenServer
  def handle_cast(:debug, state) do
    Logger.debug("===== DARA debugging =====")
    IO.inspect(state)
    {:noreply, state}
  end


  @impl GenServer
  def handle_call({:new_worker, worker, stream}, _, state) do
    case Tgw.Repo.insert(worker) do
      {:ok, _} ->
        {_, state} = get_and_update_in(state, [:workers], &{&1, Map.put(&1, worker.name, stream)})
        {:reply, :ok, state}

      {:error, _} ->
        Logger.error("failed to insert worker #{worker.name}")
    end

  end

  # ========== Private Implementation ==========

  defp schedule_work(interval) when is_integer(interval) and interval > 0 do
    Process.send_after(self(), :work, interval)
  end
end
