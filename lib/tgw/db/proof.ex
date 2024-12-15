defmodule Tgw.Db.Proof do
  use Ecto.Schema
  import Ecto.Changeset

  schema "proofs" do
    field :proof, :binary

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(proof, attrs) do
    proof
    |> cast(attrs, [:proof])
    |> validate_required([:proof])
  end
end
