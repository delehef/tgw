defmodule Tgw.Repo do
  use Ecto.Repo,
    otp_app: :tgw,
    adapter: Ecto.Adapters.Postgres
end
