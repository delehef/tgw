defmodule Tgw.Lagrange.Client do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :client)
  end

  def new_client(client_id, stream), do: GenServer.call(:client, {:set_stream, client_id, stream})

  def send_ready(client_id), do: GenServer.cast(:client, {:send_ready, client_id})

  @impl GenServer
  def init(_) do
    Phoenix.PubSub.subscribe(Tgw.PubSub, "proofs")
    {:ok, %{streams: %{}}}
  end

  @impl GenServer
  def handle_call({:set_stream, client_id, stream}, _, state) do
    {_, state} = get_and_update_in(state, [:streams], &{&1, Map.put(&1, client_id, stream)})
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_cast({:send_ready, client_id}, state) do
    new_state =
      Tgw.Db.Task.ready_for(client_id)
      |> Enum.reduce(state, fn task, curr_state ->
        proof = Tgw.Repo.get_by!(Tgw.Db.Proof, task_id: task.id)
        Logger.info("sending pre-existing proof for #{inspect(task.id)} to #{client_id}")
        send_proof(curr_state, proof)
      end)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:new_proof, proof_id}, state) do
    proof = Tgw.Repo.get_by!(Tgw.Db.Proof, id: proof_id)
    new_state = send_proof(state, proof)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp send_proof(state, proof) do
    task = Tgw.Repo.get_by!(Tgw.Db.Task, id: proof.task_id)
    client_id = task.client_id

    proof_ready = %Lagrange.ProofReady{
      task_id: %Lagrange.UUID{id: task.id},
      task_output: proof.proof
    }

    response = %Lagrange.ProofChannelResponse{response: {:proof, proof_ready}}

    new_state =
      with stream when not is_nil(stream) <- Map.get(state.streams, client_id),
           :ok <- send_to_stream(stream, response) do
        Logger.info("new proof for user #{client_id} sent for proof #{inspect(task.id)}")
        state
      else
        nil ->
          Logger.warning("client #{client_id} unknown")
          state

        {:error, err} ->
          Logger.warning("client #{client_id} disconnected: #{err}")
          {_, new_state} = get_and_update_in(state, [:streams], &{&1, Map.delete(&1, client_id)})
          new_state
      end

    new_state
  end

  defp send_to_stream(stream, proof) do
    try do
      GRPC.Server.send_reply(stream, proof)
      :ok
    rescue
      _ -> {:error, "failed to send to stream"}
    end
  end
end
