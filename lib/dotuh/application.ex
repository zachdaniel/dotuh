defmodule Dotuh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DotuhWeb.Telemetry,
      Dotuh.Repo,
      {DNSCluster, query: Application.get_env(:dotuh, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dotuh.PubSub},
      # Start a worker by calling: Dotuh.Worker.start_link(arg)
      # {Dotuh.Worker, arg},
      # Start to serve requests, typically the last entry
      DotuhWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dotuh.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DotuhWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
