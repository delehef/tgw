defmodule Tgw.Db.Worker do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workers" do
    field :average_speed, :float, default: 0.0
    field :name, :string
    field :samples_size, :integer, default: 0
    field :score, :float, default: 0.0
    field :operator_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(worker, attrs) do
    worker
    |> cast(attrs, [:name, :score, :average_speed, :samples_size])
    |> validate_required([:name, :score, :average_speed, :samples_size])
  end
end
