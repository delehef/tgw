defmodule Tgw.Tgw.Operator do
  use Ecto.Schema
  import Ecto.Changeset

  schema "operators" do
    field :address, :decimal
    field :name, :string
    field :public_key, :string
    field :enabled, :boolean, default: false
    field :eth_staked, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(operator, attrs) do
    operator
    |> cast(attrs, [:address, :name, :public_key, :enabled, :eth_staked])
    |> validate_required([:address, :name, :public_key, :enabled, :eth_staked])
    |> unique_constraint(:public_key)
    |> unique_constraint(:address)
  end
end
