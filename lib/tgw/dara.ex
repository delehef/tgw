defmodule Tgw.Lagrange.DARA do
  require Logger
  use GenServer
  import Ecto.Query

  @dara_period 3_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :DARA)
  end

  def debug() do
    GenServer.cast(:DARA, :debug)
  end

  def set_interval(interval) do
    GenServer.cast(:DARA, {:set_interval, interval})
  end

  def insert_worker(name, stream), do: GenServer.call(:DARA, {:new_worker, name, stream})

  @impl GenServer
  def init(state) do
    # Re-start a watcher for all the in-flight tasks
    inflight_jobs = Tgw.Repo.all(from(j in Tgw.Db.Job, where: j.status == :pending))
    Enum.each(inflight_jobs, fn job ->
      with task when not is_nil(task) <- Tgw.Repo.get_by(Tgw.Db.Task, [id: job.task_id]) do
        Logger.info("re-starting a monitor for task #{task.id} (#{task.time_to_live}s)")
        spawn(fn -> Tgw.Db.Task.check_timeout(task, job.worker_id, false) end)
      else
        err ->
          Logger.warning(err)
      end
    end)

    state =
      state
      |> Map.put_new(:interval, @dara_period)
      |> Map.put_new(:schedule, schedule_work(@dara_period))
      |> Map.put_new(:workers, %{})

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    tasks = Tgw.Repo.all(Tgw.Db.Task.query_to_process())
    workers = Tgw.Db.Worker.workers_ready()
    match_count = min(length(tasks), length(workers))

    new_state = Enum.zip(tasks, workers)
    |> Enum.drop(if match_count > 1, do: -1, else: 0)
    |> Enum.reduce(state, fn {task, worker}, state ->
      # Create a transaction encoding:
      #   1. marking the task as in-flight
      #   2. marking the worker as busy
      #   3. creating a new job linking the task and the worker
      #   4. sending the task over gRPC to the worker.
      #
      # Then start a process monitoring that the tasks is done before its TTL.
      assign_to_worker = Ecto.Multi.new()
      |> Ecto.Multi.update(:update_task, Ecto.Changeset.change(task, %{status: :sent}))
      |> Ecto.Multi.update(:update_worker, Ecto.Changeset.change(worker, %{status: :working}))
      |> Ecto.Multi.insert(:create_job, %Tgw.Db.Job{status: :pending, task_id: task.id, worker_id: worker.id})
      |> Ecto.Multi.run(:send_to_grpc, fn _, _ongoing ->
        stream = Map.get(state.workers, worker.name)
        try do
          GRPC.Server.send_reply(stream, %Lagrange.WorkerToGwResponse{
                task_id: %Lagrange.UUID{id: task.id},
                task: task.task})
          spawn(fn -> Tgw.Db.Task.check_timeout(task, worker.id, true) end)
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
            Tgw.Db.Worker.mark_unavailable(worker)
            {_, new_state} = get_and_update_in(state, [:workers], &{&1, Map.delete(&1, worker.name)})
            new_state
          else
            state
          end
        _ ->
          Logger.info("assigning #{inspect(task.id)} to #{worker.name}")
          state
      end
    end)

    {:noreply, Map.put(new_state, :schedule, schedule_work(state.interval))}
  end

  # We may receive some runtime-emitted messages we don't want to crah on.
  @impl GenServer
  def handle_info(_, state), do: {:noreply, state}

  @impl GenServer
  def handle_call({:new_worker, worker, stream}, _, state) do
    case Tgw.Db.Worker.get_or_insert(worker) do
      {:ok, worker} ->
        {_, state} = get_and_update_in(state, [:workers], &{&1, Map.put(&1, worker.name, stream)})
        {:reply, {:ok, worker}, state}

      {:error, _} ->
        Logger.error("failed to insert worker #{worker.name}")
    end
  end


  @impl GenServer
  def handle_cast({:set_interval, interval}, state), do: {:noreply, Map.put(state, :interval, interval)}

  @impl GenServer
  def handle_cast(:debug, state) do
    Logger.debug("===== DARA debugging =====")
    IO.inspect(state)
    {:noreply, state}
  end

  # ========== Private Implementation ==========

  defp schedule_work(interval) when is_integer(interval) and interval > 0 do
    Process.send_after(self(), :work, interval)
  end
end
