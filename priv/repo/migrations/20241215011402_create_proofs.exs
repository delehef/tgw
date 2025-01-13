defmodule Tgw.Repo.Migrations.CreateProofs do
  use Ecto.Migration

  def change do
    create table(:proofs) do
      add :proof, :binary, null: false
      add :task_id, references(:tasks, type: :binary_id, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
