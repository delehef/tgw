defmodule TgwWeb.Lagrange.ClientServer do
  require Logger
  use GRPC.Server, service: Lagrange.ClientsService.Service
  alias Tgw.Repo

  @spec submit_task(Lagrange.SubmitTaskRequest.t, GRPC.Server.Stream.t):: Lagrange.SubmitTaskResponse.t
  def submit_task(request, _stream) do
    Logger.info("new proof request: #{request.user_task_id}")

    task = %Tgw.Db.Task{
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
    Tgw.Lagrange.Client.set_stream(stream)
    Enum.each(request, fn req -> IO.puts("Proof channel request was: #{inspect(req)}") end)
  end
end

defmodule TgwWeb.Lagrange.WorkerServer do
  require Logger
  use GRPC.Server, service: Lagrange.WorkersService.Service

  def worker_to_gw(req_enum, stream) do
    Enum.each(req_enum, fn req ->
      case req do
        %Lagrange.WorkerToGwRequest {
          request: {
            :worker_ready,
            %Lagrange.WorkerReady {
              version: _version, worker_class: _worker_class
            }}} ->
          {ip, port} = stream.adapter.get_peer(stream.payload)
          worker_name = inspect(ip) <> ":" <> inspect(port)
          headers = GRPC.Stream.get_headers(stream)
          Logger.info("worker #{worker_name} connected (#{inspect(headers)})")
          worker = %Tgw.Db.Worker{
            operator_id: 1,
            name: worker_name
          }
          case Tgw.Lagrange.DARA.insert_worker(worker, stream) do
           :ok ->
              Logger.info("worker successfully inserted")
            err ->
              Logger.info("failed to save worker: #{inspect(err)}")
          end


          %Lagrange.WorkerToGwRequest{
            request: {
              :worker_done,
              %Lagrange.WorkerDone {
                task_id: %Lagrange.UUID {id: uuid},
                reply: {:task_output, payload
                }
              }
            }
          } ->

          Logger.info("task #{Kernel.inspect(uuid)} completed")

          # Save the proof payload to the DB and broadcast its readiness
          with task <- Tgw.Repo.get(Tgw.Db.Task, uuid),
          {:ok, _} <- Tgw.Repo.update(Ecto.Changeset.change(task, proof: payload)) do
            Phoenix.PubSub.broadcast(Tgw.PubSub, "proofs", {:new_proof, task.id})
          else
            nil ->
              Logger.error("unknown task #{uuid}; ignoring proof")
            {:error, changeset} ->
              Logger.error("failed to update task with proof: #{inspect(changeset)}")
          end

        _ ->
          Logger.error("unexpected worker message: #{Kernel.inspect(req)}")
      end

    end)
    Logger.warning("Worker left")
  end
end
