defmodule Tgw.Repo.Migrations.CreateOperators do
  use Ecto.Migration

  def change do
    create table(:operators) do
      add :address, :hex160, null: false
      add :name, :string, size: 100, null: false
      add :public_key, :hex512
      add :enabled, :boolean, default: false, null: false
      add :eth_staked, :uint256, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:operators, [:public_key])
    create unique_index(:operators, [:address])
  end
end
