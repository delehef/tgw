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
      |> Map.put_new(:schedule, schedule_work(3_000))
      |> Map.put_new(:workers, %{})

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    tasks = Tgw.Repo.all(from(t in Tgw.Db.Task,
          where: t.status == 0,
          order_by: [desc: t.price_requested]
        ))
    workers = Tgw.Repo.all(from(w in Tgw.Db.Worker, where: w.busy == false))

    new_state = Enum.zip(tasks, workers) |> Enum.reduce(state, fn {task, worker}, state ->
      Logger.info("assigning #{inspect(task.id)} to #{worker.name}")

      assign_to_worker = Ecto.Multi.new()
      |> Ecto.Multi.update(:update_task, Ecto.Changeset.change(task, %{status: 1}))
      |> Ecto.Multi.update(:update_worker, Ecto.Changeset.change(worker, %{busy: true}))
      |> Ecto.Multi.insert(:create_job, %Tgw.Db.Job{status: 1, task_id: task.id, worker_id: worker.id})
      |> Ecto.Multi.run(:send_to_grpc, fn _, _ ->
        stream = Map.get(state.workers, worker.name)
        try do
          GRPC.Server.send_reply(stream, %Lagrange.WorkerToGwResponse{
                task_id: %Lagrange.UUID{id: task.id},
                task: task.task})
          {:ok, {}}
        rescue
          _ -> {:error, "failed to send to stream"}
        end
      end)
      |> Tgw.Repo.transaction()

      case assign_to_worker do
        {:error, stage, value, _} ->
          Logger.error("failed to create job at stage #{stage}: #{value}")
          if stage == :send_to_grpc do
            Logger.warning("sending to gRPC failed; removing worker")
            get_and_update_in(state, [:workers], &{&1, Map.delete(&1, worker.name)})
          else
            state
          end
        _ ->
          Logger.debug("job successfully created")
          state
      end
    end)

    {:noreply, Map.put(new_state, :schedule, schedule_work(state.interval))}
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
      {:ok, worker} ->
        {_, state} = get_and_update_in(state, [:workers], &{&1, Map.put(&1, worker.name, stream)})
        {:reply, {:ok, worker}, state}

      {:error, _} ->
        Logger.error("failed to insert worker #{worker.name}")
    end

  end

  # ========== Private Implementation ==========

  defp schedule_work(interval) when is_integer(interval) and interval > 0 do
    Process.send_after(self(), :work, interval)
  end
end
