defmodule Tgw.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :status, :integer, null: false, default: 1
      add :operator_id, references(:operators, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:jobs, [:operator_id])
  end
end
