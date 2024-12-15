defmodule Tgw.Repo.Migrations.CreateProofs do
  use Ecto.Migration

  def change do
    create table(:proofs) do
      add :proof, :binary

      timestamps(type: :utc_datetime)
    end
  end
end
