defmodule Tgw.Lagrange.Client do
  require Logger
  use GenServer

  import Ecto.Query

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :client)
  end

  def set_stream(stream), do: GenServer.call(:client, {:set_stream, stream})

  @impl GenServer
  def init(stream) do
    Phoenix.PubSub.subscribe(Tgw.PubSub, "proofs")
    {:ok, %{stream: stream}}
  end

  @impl GenServer
  def handle_call({:set_stream, stream}, _, state), do: {:reply, :ok, Map.put(state, :client, stream)}

  @impl GenServer
  def handle_info({:notification, {:new_proof, %Lagrange.UUID{id: uuid}}}, state) do
    Logger.info("new proof for user is ready: #{inspect(uuid)}")

    payload = Tgw.Repo.query!(from p in Tgw.Db.Proof, where: p.id == ^uuid, select: p.proof)

    GRPC.Server.send_reply(state.stream, %Lagrange.ProofChannelResponse{
          response: %Lagrange.ProofReady{
            task_id: %Lagrange.UUID{id: uuid},
            task_output: payload }})

    {:noreply, state}
  end
end
