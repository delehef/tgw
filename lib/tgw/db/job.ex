defmodule Tgw.Db.Job do
  use Ecto.Schema
  import Ecto.Changeset

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
end
