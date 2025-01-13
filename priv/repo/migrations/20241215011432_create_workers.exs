defmodule Tgw.Repo.Migrations.CreateWorkers do
  use Ecto.Migration

  def change do
    create table(:workers) do
      add :operator_id, references(:operators, on_delete: :nothing)
      add :name, :string
      add :status, :string
      add :score, :float
      add :average_speed, :float
      add :samples_size, :integer
      add :timeouts, {:array, :utc_datetime}

      timestamps(type: :utc_datetime)
    end

    create index(:workers, [:operator_id])
    create unique_index(:workers, [:operator_id, :name], name: :unique_name)
  end
end
