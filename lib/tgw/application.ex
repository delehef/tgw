defmodule Tgw.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TgwWeb.Telemetry,
      Tgw.Repo,
      {DNSCluster, query: Application.get_env(:tgw, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tgw.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Tgw.Finch},
      # Start a worker by calling: Tgw.Worker.start_link(arg)
      # {Tgw.Worker, arg},
      # Start to serve requests, typically the last entry
      TgwWeb.Endpoint,
      {GRPC.Server.Supervisor, endpoint: TgwWeb.Endpoint, port: 9000, start_server: true},
      {Tgw.Lagrange.DARA, []},
      {Tgw.Lagrange.Client, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tgw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TgwWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
