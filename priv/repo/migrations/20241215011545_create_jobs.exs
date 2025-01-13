defmodule Tgw.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :status, :string
      add :task_id, references(:tasks, type: :binary_id, on_delete: :nothing), null: false
      add :worker_id, references(:workers, on_delete: :nothing), null: false
      add :error, :string, default: ""

      timestamps(type: :utc_datetime)
    end

    create index(:jobs, [:worker_id])
  end
end
