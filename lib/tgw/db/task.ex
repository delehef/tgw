defmodule Tgw.Db.Task do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @task_timeout 60

  @ready 0
  @inflight 1
  @successful 2
  @failed 3

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do
    field :status, :integer
    field :user_task_id, :string
    field :price_requested, :decimal
    field :class, :string
    field :task, :binary
    field :ready_proof, :integer
    field :time_to_live, :integer
    field :acked_by_client, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:status, :class, :user_task_id, :price_requested, :class, :task, :ready_proof, :acked_by_client, :time_to_live])
    |> validate_required([:status, :class, :user_task_id, :price_requested, :class, :task, :acked_by_client, :time_to_live])
  end

  def mark_ready(task), do: Tgw.Repo.update(changeset(task, %{status: @ready}))
  def mark_successful(task, proof_id), do: Tgw.Repo.update(changeset(task, %{status: @successful, ready_proof: proof_id}))
  def mark_failed(task), do: Tgw.Repo.update(changeset(task, %{status: @failed}))

  def non_acked do
    q = from t in Tgw.Db.Task,
      where: t.status == ^@successful and t.acked_by_client == false
    Tgw.Repo.all(q)
  end

  def query_to_process() do
    from t in Tgw.Db.Task,
      where: t.status == ^@ready,
      order_by: [desc: t.price_requested]
  end

  def check_timeout(task, worker_id, penalize) do
    ttl_secs = task.time_to_live*1000
    Process.sleep(ttl_secs)

    task = Tgw.Repo.get!(Tgw.Db.Task, task.id)
    if task.status == @inflight do
      Logger.warning("task #{task.id} timed out")
      mark_ready(task)
      worker = Tgw.Repo.get!(Tgw.Db.Worker, worker_id)
      if penalize, do: Tgw.Db.Worker.mark_timedout(worker)
    end
  end
end
