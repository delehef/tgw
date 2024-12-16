defmodule Tgw.Db.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @running 1
  @successful 2
  @failed 3
  @timedout 4

  schema "jobs" do
    field :status, :integer
    field :task_id, :binary_id
    field :worker_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:status, :task_id, :worker_id])
    |> validate_required([:status, :task_id, :worker_id])
  end

  def mark_successful(job), do: Tgw.Repo.update(changeset(job, %{status: @successful}))
  def mark_failed(job), do: Tgw.Repo.update(changeset(job, %{status: @failed}))
  def mark_timedout(job), do: Tgw.Repo.update(changeset(job, %{status: @timedout}))
end
