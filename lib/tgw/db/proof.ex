defmodule Tgw.Db.Proof do
  use Ecto.Schema
  import Ecto.Changeset

  schema "proofs" do
    field :proof, :binary
    field :task_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(proof, attrs) do
    proof
    |> cast(attrs, [:proof, :task_id])
    |> validate_required([:proof, :task_id])
  end
end
