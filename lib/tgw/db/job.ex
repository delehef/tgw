defmodule Tgw.Db.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :status, :integer
    field :task_id, :binary_id
    field :worker_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
