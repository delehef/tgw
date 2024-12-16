defmodule Tgw.Lagrange.Client do
  require Logger
  use GenServer

  import Ecto.Query

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :client)
  end

  def set_stream(stream), do: GenServer.call(:client, {:set_stream, stream})

  def send_ready(), do: GenServer.cast(:client, :send_ready)

  @impl GenServer
  def init(stream) do
    Phoenix.PubSub.subscribe(Tgw.PubSub, "proofs")
    {:ok, %{stream: stream}}
  end

  @impl GenServer
  def handle_call({:set_stream, stream}, _, state), do: {:reply, :ok, Map.put(state, :stream, stream)}

  @impl GenServer
  def handle_cast(:send_ready, state) do
    Tgw.Db.Task.non_acked() |> Enum.each(fn task ->
      proof = Tgw.Repo.get_by!(Tgw.Db.Proof, id: task.ready_proof)
      Logger.info("sending pre-existing proof for #{inspect(task.id)}")
      send_proof(state.stream, task.id, proof.proof)
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:new_proof, proof_id}, state) do
    task = Tgw.Repo.get_by!(Tgw.Db.Task, ready_proof: proof_id)
    proof = Tgw.Repo.get_by!(Tgw.Db.Proof, id: proof_id)
    Logger.info("new proof for user is ready for proof #{inspect(task.id)}")
    send_proof(state.stream, task.id, proof.proof)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warning("Unexpected info: #{inspect(msg)}")
    {:noreply, state}
  end

  defp send_proof(stream, task_id, proof) do
    proof_ready = %Lagrange.ProofReady{
      task_id: %Lagrange.UUID{id: task_id},
      task_output: proof
    }
    response = %Lagrange.ProofChannelResponse{response: {:proof, proof_ready}}
    GRPC.Server.send_reply(stream, response)
  end
end
