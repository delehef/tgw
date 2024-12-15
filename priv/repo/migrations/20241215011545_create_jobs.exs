defmodule Tgw.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :status, :integer, null: false, default: 1
      add :task_id, references(:tasks, type: :binary_id, on_delete: :nothing)
      add :worker_id, references(:workers, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:jobs, [:worker_id])
  end
end
