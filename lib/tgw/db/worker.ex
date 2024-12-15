defmodule Tgw.Db.Worker do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workers" do
    field :name, :string
    field :score, :float, default: 0.0
    field :average_speed, :float, default: 0.0
    field :samples_size, :integer, default: 0
    field :operator_id, :id
    field :busy, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(worker, attrs) do
    worker
    |> cast(attrs, [:name, :score, :average_speed, :samples_size, :operator_id, :busy])
    |> validate_required([:name, :score, :average_speed, :samples_size, :operator_id, :busy])
    |> unique_constraint(:unique_name, name: :unique_name)
  end

  def mark_ready(worker), do: changeset(worker, %{busy: false})
end
