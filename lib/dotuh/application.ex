defmodule Dotuh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ensure_config_file!()
    ensure_dota_data!()

    children = [
      DotuhWeb.Telemetry,
      Dotuh.Repo,
      {DNSCluster, query: Application.get_env(:dotuh, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:dotuh, :ash_domains),
         Application.fetch_env!(:dotuh, Oban)
       )},
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

  defp ensure_config_file!() do
    # parameterize this at some point
    contents = """
    "Dotuh Integration Configuration"
    {
        "uri"          "http://localhost:4321/live_game"
        "timeout"      "5.0"
        "buffer"       "0.1"
        "throttle"     "0.1"
        "heartbeat"    "10.0"
        "data"
        {
            "auth"            "1"
            "provider"        "1"
            "map"             "1"
            "player"          "1"
            "hero"            "1"
            "abilities"       "1"
            "items"           "1"
            "events"          "1"
            "buildings"       "1"
            "league"          "1"
            "draft"           "1"
            "wearables"       "1"
            "minimap"         "1"
            "roshan"          "1"
            "couriers"        "1"
            "neutralitems"    "1"
        }
    }
    """

    File.mkdir_p!(
      "/Users/zachdaniel/Library/Application\ Support/Steam/steamapps/common/dota\ 2\ beta/game/dota/cfg/gamestate_integration"
    )

    File.write!(
      "/Users/zachdaniel/Library/Application\ Support/Steam/steamapps/common/dota\ 2\ beta/game/dota/cfg/gamestate_integration/gamestate_integration_dotuh.cfg",
      contents
    )
  end

  defp ensure_dota_data!() do
    data_dir = Path.join(File.cwd!(), "dota_data")

    if File.exists?(data_dir) do
      # Update existing repository
      {_output, 0} = System.cmd("git", ["pull"], cd: data_dir)
    else
      # Clone the repository
      {_output, 0} =
        System.cmd("git", [
          "clone",
          "--depth",
          "1",
          "https://github.com/dotabuff/d2vpkr.git",
          data_dir
        ])
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DotuhWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
