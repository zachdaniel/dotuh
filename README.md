# Dotuh

Required setup:

- postgresql running on port 5432
  - user postgres
  - pass postgres
- elixir setup
- ensure gsi is enabled in dota startup flags

Create this file in your dota files:
game/dota/cfg/gamestate_integration/gamestate_integration_dotuh.cfg

but replace the host with where you are running the server

```
"Dotuh Integration Configuration"
{
    "uri"          "http://192.0.0.1:4321/live_game"
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
```





To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4321`](http://localhost:4321) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
