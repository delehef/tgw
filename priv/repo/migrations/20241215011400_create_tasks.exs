defmodule Tgw.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :integer, null: false, default: 0
      add :class, :string, null: false
      add :user_task_id, :string, null: false
      add :price_requested, :uint256, null: false
      add :task, :binary, null: false
      add :time_to_live, :integer, null: false
      add :acked_by_client, :boolean, default: false, null: false
      add :ready_proof, references(:proofs, on_delete: :nothing, type: :id)

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:ready_proof])
  end
end
