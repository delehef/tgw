# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Tgw.Repo.insert!(%Tgw.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
Tgw.Repo.insert!(%Tgw.Db.Operator{
      address: "7a62a56e7a62a56e7a62a56e7a62a56e7a62a56e",
      name: "Lagrange Labs Workers",
      public_key: "a90b7d1953d7462fa8e9d510dbb7aeb081606ef9d7f3fb0c2dd3666f84c9917e61a6c4bfa0483050be0bb6d650530c02263b6fcd092e0536a909cbb222d7c4c7",
      enabled: true,
      eth_staked: 150_000_000
})
