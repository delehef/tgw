defmodule Tgw.Repo.Migrations.Init do
  use Ecto.Migration

  def change do
    execute(
      "CREATE DOMAIN uint256 AS NUMERIC NOT NULL
      CHECK (VALUE >= 0 AND VALUE < 2^256)
      CHECK (SCALE(VALUE) = 0);",
      "DROP DOMAIN uint256 CASCADE;"
    )

    execute(
      "CREATE DOMAIN hex512 AS CHAR(128) NOT NULL
      CHECK (VALUE ~ '^[a-f0-9]{128}$');",
      "DROP DOMAIN hex512;"
    )

    execute(
      "CREATE DOMAIN hex160 AS CHAR(40) NOT NULL
      CHECK (VALUE ~ '^[a-f0-9]{40}$');",
      "DROP DOMAIN hex160;"
    )
  end
end
