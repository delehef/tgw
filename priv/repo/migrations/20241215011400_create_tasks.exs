defmodule Tgw.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, :string, null: false
      add :user_task_id, :string, null: false
      add :price_requested, :uint256, null: false
      add :class, :string, null: false
      add :task, :binary, null: false
      add :time_to_live, :integer, null: false
      add :status, :string, null: false, default: "created"

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:status])
  end
end
