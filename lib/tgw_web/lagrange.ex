defmodule TgwWeb.Lagrange.ClientServer do
  require Logger
  use GRPC.Server, service: Lagrange.ClientsService.Service
  alias Tgw.Repo
  import Ecto.Query

  def submit_task(request, stream) do
    headers = GRPC.Stream.get_headers(stream)
    client_id = Map.get(headers, "client_id")
    if is_nil(client_id) do
      Logger.error("`client_id` not found in headers")
      raise GRPC.RPCError, :unauthenticated
    end

    Logger.info("new proof request from #{client_id} for #{request.user_task_id}")

    task = %Tgw.Db.Task{
      client_id: client_id,
      user_task_id: String.slice(request.user_task_id, 0, 200),
      price_requested: 1500, # FIXME: need to parse int from bytes
      class: request.class,
      task: request.task_bytes,
      time_to_live: request.timeout.seconds,
      status: :created
    }

    case Repo.insert(task) do
      {:ok, task} -> %Lagrange.SubmitTaskResponse{task_uuid: %Lagrange.UUID{id: task.id}}
      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            Keyword.get(opts, String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        Logger.error("failed to insert task #{request.user_task_id}: #{errors}")
        raise GRPC.RPCError, status: :internal
    end
  end

  def proof_channel(request, stream) do
    headers = GRPC.Stream.get_headers(stream)
    client_id = Map.get(headers, "client_id")
    if is_nil(client_id) do
      Logger.error("`client_id` not found in headers")
      raise GRPC.RPCError, :unauthenticated
    end
    # HACK
    GRPC.Server.send_headers(stream, headers)
    # HACK

    # Re-send ready but non-acked proof on connection opening
    Tgw.Lagrange.Client.new_client(client_id, stream)
    Tgw.Lagrange.Client.send_ready(client_id)


    Enum.each(request, fn req ->
      case req do
        %Lagrange.ProofChannelRequest{
          request: {
            :acked_messages,
            %Lagrange.AckedMessages{
              acked_messages: uuids}}} ->
          ids = Enum.map(uuids, fn uuid -> uuid.id end)

          Logger.info("updating acked proofs: #{inspect(ids)}")
          Tgw.Repo.update_all(
            from(t in Tgw.Db.Task, where: t.id in ^ids),
            set: [status: :returned]
          )

        _ ->
          Logger.warning("unexpected proof channel request: #{inspect(req)}") end
    end)
  end
end

defmodule TgwWeb.Lagrange.WorkerServer do
  require Logger
  use GRPC.Server, service: Lagrange.WorkersService.Service

  def worker_to_gw(req_enum, stream) do
    # HACK
    headers = GRPC.Stream.get_headers(stream)
    GRPC.Server.send_headers(stream, headers)
    # HACK

    headers = GRPC.Stream.get_headers(stream)
    # NOTE: This cannot fail, as it would have failed at authentication.
    {:ok, _token} = Tgw.Rpc.Authenticator.decode_token(headers)
    {ip, port} = stream.adapter.get_peer(stream.payload)
    worker_name = inspect(ip) <> ":" <> inspect(port)
    Logger.info("worker #{worker_name} connected (#{inspect(headers)})")

    worker = %Tgw.Db.Worker{
      operator_id: 1,
      name: worker_name,
      status: :ready,
    }
    worker_id =
      case Tgw.Lagrange.DARA.insert_worker(worker, stream) do
        {:ok, worker} ->
          Logger.info("worker #{inspect(worker)} successfully inserted")
          worker.id
        err ->
          Logger.error("failed to save worker: #{inspect(err)}")
          raise GRPC.RPCError, status: :internal
      end

    Enum.each(req_enum, fn req ->
      case req do
        %Lagrange.WorkerToGwRequest {
          request: {
            :worker_ready,
            %Lagrange.WorkerReady {
              version: _version, worker_class: _worker_class
            }}} ->
          with worker <- Tgw.Repo.get(Tgw.Db.Worker, worker_id),
          {:ok, _} <- Tgw.Db.Worker.mark_ready(worker) do
            Logger.info("worker #{worker.name} ready to work")
          else
            err ->
              Logger.error("failed to mark worker as ready: #{inspect(err)}")
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

          Logger.info("task #{inspect(uuid)} completed")

          # Save the proof payload to the DB and broadcast its readiness
          with worker when not is_nil(worker) <- Tgw.Repo.get(Tgw.Db.Worker, worker_id),
          {:job, job} when not is_nil(job) <- {:job, Tgw.Db.Job.latest_for(uuid, worker.id)},
          {:task, task} when not is_nil(task) <- {:task, Tgw.Repo.get(Tgw.Db.Task, uuid)},
          {:ok, proof} <- Tgw.Repo.insert(%Tgw.Db.Proof{proof: payload, task_id: task.id}) do
            if Tgw.Db.Worker.has_timedout(worker) do
              Logger.warning("ignoring proof for task #{task.id} from timed-out worker #{worker.name}")
              Tgw.Db.Worker.un_timeout(worker)
            else
              # Mark the task and its associated job as ssuccesful
              with {:ok, _} <- Tgw.Db.Task.mark_successful(task, proof.id),
              {:ok, _} <- Tgw.Db.Job.mark_successful(job) do
                Phoenix.PubSub.broadcast(Tgw.PubSub, "proofs", {:new_proof, proof.id})
                # Mark the worker as ready again
                with worker <- Tgw.Repo.get(Tgw.Db.Worker, worker.id),
                {:ok, worker} <- Tgw.Db.Worker.mark_ready(worker) do
                  Logger.info("worker #{worker.name} ready to work again")
                else
                  err ->
                    Logger.error("failed to mark worker as ready: #{inspect(err)}")
                end
              else
                msg -> Logger.error("failed to mark task #{task.id} as successful: #{inspect(msg)}")
              end
            end
          else
            {:job, nil} ->
              Logger.error("failed to find an in-flight job for task #{uuid} and worker #{worker.name}")
            {:task, nil} ->
              Logger.error("unknown task #{uuid}; ignoring proof")
            {:error, changeset} ->
              Logger.error("failed to update task with proof: #{inspect(changeset)}")
            msg -> Logger.error("unexpected error: #{inspect(msg)}")
          end
        _ ->
          Logger.error("unexpected worker message: #{Kernel.inspect(req)}")
      end

    end)
    Logger.warning("Worker left")
  end
end
