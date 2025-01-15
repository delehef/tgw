defmodule Tgw.Db.Job do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "jobs" do
    field :status, Ecto.Enum, values: [:pending, :failed, :successful]
    field :task_id, :binary_id
    field :worker_id, :id
    field :error, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:status, :task_id, :worker_id, :status, :error])
    |> validate_required([:status, :task_id, :worker_id, :status])
  end

  def mark_successful(job), do: Tgw.Repo.update(changeset(job, %{status: :successful}))
  def mark_failed(job), do: Tgw.Repo.update(changeset(job, %{status: :failed}))
  def mark_timedout(job), do: Tgw.Repo.update(changeset(job, %{status: :failed, error: "Job timed out"}))

  def in_flight do
    q = from j in Tgw.Db.Job,
      left_join: w in Tgw.Db.Worker, on: j.worker_id == w.id,
      left_join: t in Tgw.Db.Task, on: j.task_id == t.id,
      select: %{task_id: t.id, user_task_id: t.user_task_id, worker: w.name},
      where: j.status == :pending,
      order_by: [asc: j.inserted_at]

    Tgw.Repo.all(q)
  end

  def failed do
    q = from j in Tgw.Db.Job,
      left_join: w in Tgw.Db.Worker, on: j.worker_id == w.id,
      left_join: t in Tgw.Db.Task, on: j.task_id == t.id,
      where: j.status == :failed,
      select: %{task_id: t.id, user_task_id: t.user_task_id, worker: w.name, error: j.error},
      order_by: [asc: w.inserted_at]

    Tgw.Repo.all(q)
  end
end
