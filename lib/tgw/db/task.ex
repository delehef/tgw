defmodule Tgw.Db.Task do
  use Ecto.Schema
  import Ecto.Changeset

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
    field :acked_by_client, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:status, :class, :user_task_id, :price_requested, :class, :task, :ready_proof, :acked_by_client])
    |> validate_required([:status, :class, :user_task_id, :price_requested, :class, :task, :acked_by_client])
  end

  def mark_successful(task, proof_id), do: changeset(task, %{status: @successful, ready_proof: proof_id})
  def mark_failed(task), do: changeset(task, %{status: @failed})
end
