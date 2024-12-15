defmodule TgwWeb.Lagrange.ClientServer do
  require Logger
  use GRPC.Server, service: Lagrange.ClientsService.Service

  @spec submit_task(Lagrange.SubmitTaskRequest.t, GRPC.Server.Stream.t):: Lagrange.SubmitTaskResponse.t
  def submit_task(request, _stream) do
    Logger.info("new proof request: #{request.user_task_id}")

    # x = %Lagrange.UUID{id: <<104, 101, 197, 130, 197, 130, 111>>}
    %Lagrange.SubmitTaskResponse{
      task_uuid: %Lagrange.UUID{id: "smh my head"}
    }
  end

  def proof_channel(request, stream) do
    IO.puts("Proof channel request was:")
    IO.inspect(request)

    proof_loop(stream)
  end

  defp proof_loop(stream) do
    receive do
      msg ->
        IO.puts("Received unexpected message:")
        IO.inspect(msg)
        GRPC.Server.send_reply(stream, Lagrange.SubmitTaskResponse.encode(%{}))
        proof_loop(stream)
    end
  end
end


defmodule TgwWeb.Lagrange.WorkerServer do
  require Logger
  use GRPC.Server, service: Lagrange.WorkersService.Service

  def worker_to_gw() do
  end
end

defmodule Tgw.Lagrange.DARA do
  use GenServer

  def start(_) do
    GenServer.start(__MODULE__, {}, name: :DARA)
  end

  @impl GenServer
  def init(state) do
    state =
      state
      |> Map.put_new(:interval, 15_000)
      |> Map.put_new(:schedule, nil)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    # TODO: actually run DARA/ProofPHI
    {:noreply, Map.put(state, :schedule, schedule_work(state.interval))}
  end

  # We may receive some runtime-emitted messages we don't want to crah on.
  def handle_info(_, state), do: {:noreply, state}

  defp schedule_work(interval) when is_integer(interval) and interval > 0 do
    Process.send_after(self(), :work, interval)
  end
end

defmodule Tgw.Lagrange.PhoneyTaskHandler do
  use GenServer

  def start(_) do
    GenServer.start(__MODULE__, {}, name: :DARA)
  end

  @impl GenServer
  def init(state) do
    state =
      state
      |> Map.put_new(:received_tasks, [])
      |> Map.put_new(:inflight_tasks, [])
      |> Map.put_new(:interval, 1_000)
      |> Map.put_new(:schedule, nil)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    if length(state.tasks) > 0 do
      task = List.pop_at(state.tasks, 0)
      Postgrex.query!()
    end

    {:noreply, Map.put(state, :schedule, schedule_work(state.interval))}
  end

  # We may receive some runtime-emitted messages we don't want to crah on.
  def handle_info(_, state), do: {:noreply, state}

  defp schedule_work(interval) when is_integer(interval) and interval > 0 do
    Process.send_after(self(), :work, interval)
  end
end
