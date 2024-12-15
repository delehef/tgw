defmodule Tgw.Repo.Migrations.CreateWorkers do
  use Ecto.Migration

  def change do
    create table(:workers) do
      add :name, :string
      add :score, :float
      add :average_speed, :float
      add :samples_size, :integer
      add :operator_id, references(:operators, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:workers, [:operator_id])
  end
end
