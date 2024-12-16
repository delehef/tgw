defmodule Tgw.Repo.Migrations.CreateWorkers do
  use Ecto.Migration

  def change do
    create table(:workers) do
      add :name, :string
      add :status, :integer
      add :score, :float
      add :average_speed, :float
      add :samples_size, :integer
      add :operator_id, references(:operators, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:workers, [:operator_id])
    create unique_index(:workers, [:operator_id, :name], name: :unique_name)
  end
end
