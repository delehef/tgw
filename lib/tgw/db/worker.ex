defmodule Tgw.Db.Worker do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @unavailable 0
  @ready 1
  @working 2
  @timedout 3


  schema "workers" do
    field :name, :string
    field :status, :integer, default: 0
    field :score, :float, default: 0.0
    field :average_speed, :float, default: 0.0
    field :samples_size, :integer, default: 0
    field :operator_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(worker, attrs) do
    worker
    |> cast(attrs, [:name, :score, :average_speed, :samples_size, :operator_id, :status])
    |> validate_required([:name, :score, :average_speed, :samples_size, :operator_id, :status])
    |> unique_constraint(:unique_name, name: :unique_name)
  end

  def workers_ready(), do: Tgw.Repo.all(from(w in Tgw.Db.Worker, where: w.status == ^@ready))

  def has_timedout(worker), do: worker.status == @timedout

  def mark_ready(worker), do: Tgw.Repo.update(changeset(worker, %{status: @ready}))
  def mark_unavailable(worker), do: Tgw.Repo.update(changeset(worker, %{status: @unavailable}))
  def mark_working(worker), do: Tgw.Repo.update(changeset(worker, %{status: @working}))
  def mark_timedout(worker), do: Tgw.Repo.update(
        changeset(worker, %{status: @timedout, score: worker.score - 1}))

  def un_timeout(worker) do
    if worker.score > -5 do
      Logger.info("un-timingout worker #{worker.name}")
      mark_ready(worker)
    else
      Logger.warning("worker #{worker.name} has score #{worker.score}")
    end
  end

  def get_or_insert(worker) do
    Tgw.Repo.insert(
      worker,
      on_conflict: [set: [name: worker.name]],
      conflict_target: [:operator_id, :name]
    )
  end
end
