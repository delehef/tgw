defmodule TgwWeb.Lagrange.ClientServer do
  require Logger
  use GRPC.Server, service: Lagrange.ClientsService.Service
  alias Tgw.Repo

  @spec submit_task(Lagrange.SubmitTaskRequest.t, GRPC.Server.Stream.t):: Lagrange.SubmitTaskResponse.t
  def submit_task(request, _stream) do
    Logger.info("new proof request: #{request.user_task_id}")

    task = %Tgw.Tgw.Task{
      user_task_id: request.user_task_id,
      price_requested: 1500, # FIXME:
      class: request.class,
      task: request.task_bytes,
    }

    case Repo.insert(task) do
      {:ok, task} -> %Lagrange.SubmitTaskResponse{task_uuid: %Lagrange.UUID{id: task.id}}
      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        Logger.error("failed to insert task #{request.user_task_id}: #{errors}")
    end
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
  require Logger
  use GenServer

  def start_link(_) do
    Logger.debug("DARA start-link")
    GenServer.start_link(__MODULE__, %{}, name: :DARA)
  end

  def start(_) do
    GenServer.start(__MODULE__, %{}, name: :DARA)
  end

  @impl GenServer
  def init(state) do
    Logger.debug("DARA Init")
    state =
      state
      |> Map.put_new(:interval, 5_000)
      |> Map.put_new(:schedule, schedule_work(5_000))

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    Logger.debug("DARA called")
    # TODO: actually run DARA/ProofPHI
    {:noreply, Map.put(state, :schedule, schedule_work(state.interval))}
  end

  # We may receive some runtime-emitted messages we don't want to crah on.
  def handle_info(_, state), do: {:noreply, state}

  defp schedule_work(interval) when is_integer(interval) and interval > 0 do
    Process.send_after(self(), :work, interval)
  end
end
