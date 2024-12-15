defmodule Tgw.Db.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do
    field :status, :integer
    field :user_task_id, :string
    field :price_requested, :decimal
    field :class, :string
    field :task, :binary
    field :ready_proof, :binary_id
    field :acked_by_client, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:class, :user_task_id, :price_requested, :task, :acked_by_client])
    |> validate_required([:class, :user_task_id, :price_requested, :task, :acked_by_client])
  end
end
