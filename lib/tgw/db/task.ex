defmodule Tgw.Db.Task do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do
    field :client_id, :string
    field :user_task_id, :string
    field :price_requested, :decimal
    field :class, :string
    field :task, :binary
    field :time_to_live, :integer
    field :status, Ecto.Enum, values: [:created, :sent, :completed, :faulted, :errored, :returned]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:client_id,  :user_task_id, :price_requested, :class, :task, :status,  :time_to_live])
    |> validate_required([:client_id,  :user_task_id, :price_requested, :class, :task, :status,  :time_to_live])
  end

  def mark_ready(task), do: Tgw.Repo.update(changeset(task, %{status: :created}))
  def mark_successful(task, proof_id), do: Tgw.Repo.update(changeset(task, %{status: :completed, ready_proof: proof_id}))
  def mark_faulted(task), do: Tgw.Repo.update(changeset(task, %{status: :faulted}))

  def ready_for(client_id) do
    q = from t in Tgw.Db.Task,
      where: t.status == :completed and t.client_id == ^client_id
    Tgw.Repo.all(q)
  end

  def query_to_process() do
    from t in Tgw.Db.Task,
      where: t.status == :created,
      order_by: [desc: t.price_requested]
  end

  def check_timeout(task, worker_id, penalize) do
    ttl_secs = task.time_to_live*1000
    Process.sleep(ttl_secs)

    task = Tgw.Repo.get!(Tgw.Db.Task, task.id)
    if task.status == :sent do
      Logger.warning("task #{task.id} timed out")
      mark_ready(task)
      worker = Tgw.Repo.get!(Tgw.Db.Worker, worker_id)
      if penalize do
        Tgw.Db.Worker.mark_timedout(worker)
      end
    end
  end

  def in_flight do
    q = from t in Tgw.Db.Task,
      where: t.status == :created,
      select: %{id: t.id, user_id: t.user_task_id, status: t.status, class: t.class, created: t.inserted_at, updated: t.updated_at},
      order_by: [asc: t.class, asc: t.inserted_at]

    Tgw.Repo.all(q)
  end
end
