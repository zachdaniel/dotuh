defmodule DotuhWeb.GameController do
  use DotuhWeb, :controller
  require Ash.Query
  require Logger

  alias Dotuh.GameState.{
    Game,
    Hero,
    Ability,
    Item,
    Building,
    Player,
    Event,
    HeroLocationHistory,
    LocationMapper
  }

  def event(conn, params) do
    if params["league"]["match_id"] do
      case process_game_state(params) do
        {:ok, _result} ->
          send_resp(conn, 200, "ok")

        {:error, reason} ->
          IO.inspect(reason, label: "Error processing game state")
          send_resp(conn, 500, "error")
      end
    else
      # No match_id but still process game state updates
      case process_game_state(params) do
        {:ok, _result} ->
          send_resp(conn, 200, "ok")

        {:error, reason} ->
          IO.inspect(reason, label: "Error processing game state")
          send_resp(conn, 500, "error")
      end
    end
  end

  defp process_game_state(params) do
    with {:ok, game} <- find_or_create_game(params),
         :ok <- update_hero_data(game, params),
         :ok <- update_minimap_heroes(game, params),
         :ok <- update_abilities_data(game, params),
         :ok <- update_items_data(game, params),
         :ok <- update_buildings_data(game, params),
         :ok <- update_player_data(game, params),
         :ok <- update_events_data(game, params) do
      {:ok, :processed}
    end
  end

  defp find_or_create_game(params) do
    match_id = get_in(params, ["league", "match_id"]) || "0"
    map_data = params["map"] || %{}

    game_attrs = %{
      match_id: match_id,
      game_time: map_data["game_time"],
      clock_time: map_data["clock_time"],
      game_state: map_data["game_state"],
      radiant_score: map_data["radiant_score"],
      dire_score: map_data["dire_score"],
      paused: map_data["paused"] || false,
      daytime: map_data["daytime"] || true
    }

    # Try to find existing game by match_id, or create new one
    case Game |> Ash.Query.filter(match_id == ^match_id) |> Ash.read_one() do
      {:ok, nil} ->
        Game |> Ash.Changeset.for_create(:create, game_attrs) |> Ash.create()

      {:ok, game} ->
        game |> Ash.Changeset.for_update(:update, game_attrs) |> Ash.update()

      error ->
        error
    end
  end

  defp update_hero_data(_game, %{"hero" => nil}), do: :ok

  defp update_hero_data(game, %{"hero" => hero_data}) do
    hero_name = hero_data["name"]

    hero_attrs = %{
      game_id: game.id,
      name: hero_name,
      internal_name: hero_name,
      level: hero_data["level"],
      health: hero_data["health"],
      max_health: hero_data["max_health"],
      mana: hero_data["mana"],
      max_mana: hero_data["max_mana"],
      xpos: hero_data["xpos"],
      ypos: hero_data["ypos"],
      alive: hero_data["alive"] || true,
      respawn_seconds: hero_data["respawn_seconds"] || 0,
      gold: hero_data["gold"] || 0,
      xp: hero_data["xp"] || 0,
      is_current_player: true
    }

    # Find or create the current player's hero by name
    case Hero |> Ash.Query.filter(game_id == ^game.id and name == ^hero_name) |> Ash.read_one() do
      {:ok, nil} ->
        case Hero |> Ash.Changeset.for_create(:create, hero_attrs) |> Ash.create() do
          {:ok, new_hero} ->
            # Track initial location for the new hero
            track_hero_location_change(game, new_hero, hero_attrs.xpos, hero_attrs.ypos)
            {:ok, new_hero}

          error ->
            error
        end

      {:ok, hero} ->
        case hero |> Ash.Changeset.for_update(:update, hero_attrs) |> Ash.update() do
          {:ok, updated_hero} ->
            # Track location change for the updated hero
            track_hero_location_change(game, updated_hero, hero_attrs.xpos, hero_attrs.ypos)
            {:ok, updated_hero}

          error ->
            error
        end

      error ->
        error
    end

    :ok
  end

  defp update_hero_data(_game, _params), do: :ok

  defp update_minimap_heroes(_game, %{"minimap" => nil}), do: :ok

  defp update_minimap_heroes(game, %{"minimap" => minimap}) when is_map(minimap) do
    minimap
    |> Enum.each(fn {_object_id, object_data} ->
      # Only process hero units (those with "name" field containing hero names)
      if is_hero_unit?(object_data) do
        hero_name = object_data["name"] || object_data["unitname"]
        team = determine_team_from_minimap(object_data["team"])

        hero_attrs = %{
          game_id: game.id,
          name: hero_name,
          internal_name: hero_name,
          team: team,
          xpos: object_data["xpos"],
          ypos: object_data["ypos"],
          # Default values for minimap heroes since we don't have detailed stats
          level: 1,
          health: 1,
          max_health: 1,
          mana: 1,
          max_mana: 1,
          alive: true,
          respawn_seconds: 0,
          gold: 0,
          xp: 0,
          is_current_player: false
        }

        # Upsert hero by game_id and name
        case Hero
             |> Ash.Query.filter(game_id == ^game.id and name == ^hero_name)
             |> Ash.read_one() do
          {:ok, nil} ->
            case Hero |> Ash.Changeset.for_create(:create, hero_attrs) |> Ash.create() do
              {:ok, new_hero} ->
                # Track initial location for the new minimap hero
                track_hero_location_change(game, new_hero, hero_attrs.xpos, hero_attrs.ypos)
                {:ok, new_hero}

              error ->
                error
            end

          {:ok, hero} ->
            # Only update position and team for minimap heroes, preserve detailed stats and is_current_player
            # Don't overwrite is_current_player if it's already true (set by update_hero_data)
            update_attrs = %{
              team: team,
              xpos: object_data["xpos"],
              ypos: object_data["ypos"]
            }

            # Only add is_current_player: false if it's not already true
            update_attrs =
              if hero.is_current_player do
                # Don't include is_current_player to preserve true value
                update_attrs
              else
                Map.put(update_attrs, :is_current_player, false)
              end

            case hero |> Ash.Changeset.for_update(:update, update_attrs) |> Ash.update() do
              {:ok, updated_hero} ->
                # Track location change for the minimap hero
                track_hero_location_change(
                  game,
                  updated_hero,
                  object_data["xpos"],
                  object_data["ypos"]
                )

                {:ok, updated_hero}

              error ->
                error
            end

          _error ->
            :ok
        end
      end
    end)

    :ok
  end

  defp update_minimap_heroes(_game, _params), do: :ok

  defp is_hero_unit?(%{"unitname" => unitname}) when is_binary(unitname) do
    String.starts_with?(unitname, "npc_dota_hero_")
  end

  defp is_hero_unit?(_), do: false

  defp determine_team_from_minimap(team_id) when is_integer(team_id) do
    case team_id do
      2 -> "radiant"
      3 -> "dire"
      _ -> "unknown"
    end
  end

  defp determine_team_from_minimap(_), do: "unknown"

  defp update_abilities_data(_game, %{"abilities" => nil}), do: :ok

  defp update_abilities_data(game, %{"abilities" => abilities}) when is_map(abilities) do
    # Find the hero for this game
    case Hero |> Ash.Query.filter(game_id == ^game.id) |> Ash.read_one() do
      {:ok, hero} when not is_nil(hero) ->
        abilities
        |> Enum.each(fn {slot, ability_data} ->
          ability_attrs = %{
            game_id: game.id,
            hero_id: hero.id,
            slot: slot,
            name: ability_data["name"],
            ability_active: ability_data["ability_active"] || false,
            can_cast: ability_data["can_cast"] || false,
            cooldown: ability_data["cooldown"] || 0,
            level: ability_data["level"] || 0,
            passive: ability_data["passive"] || false,
            ultimate: ability_data["ultimate"] || false
          }

          # Upsert ability by game_id, hero_id, and slot
          case Ability
               |> Ash.Query.filter(game_id == ^game.id and hero_id == ^hero.id and slot == ^slot)
               |> Ash.read_one() do
            {:ok, nil} ->
              Ability |> Ash.Changeset.for_create(:create, ability_attrs) |> Ash.create()

            {:ok, ability} ->
              ability |> Ash.Changeset.for_update(:update, ability_attrs) |> Ash.update()

            _error ->
              :ok
          end
        end)

      _ ->
        :ok
    end

    :ok
  end

  defp update_abilities_data(_game, _params), do: :ok

  defp update_items_data(_game, %{"items" => nil}), do: :ok

  defp update_items_data(game, %{"items" => items}) when is_map(items) do
    # Find the hero for this game
    case Hero |> Ash.Query.filter(game_id == ^game.id) |> Ash.read_one() do
      {:ok, hero} when not is_nil(hero) ->
        items
        |> Enum.each(fn {slot, item_data} ->
          # Skip empty items
          if item_data["name"] != "empty" do
            item_attrs = %{
              game_id: game.id,
              hero_id: hero.id,
              slot: slot,
              name: item_data["name"],
              can_cast: item_data["can_cast"] || false,
              charges: item_data["charges"] || 0,
              cooldown: item_data["cooldown"] || 0,
              item_level: item_data["item_level"] || 1,
              passive: item_data["passive"] || false,
              purchaser: item_data["purchaser"] || 0
            }

            # Upsert item by game_id, hero_id, and slot
            case Item
                 |> Ash.Query.filter(
                   game_id == ^game.id and hero_id == ^hero.id and slot == ^slot
                 )
                 |> Ash.read_one() do
              {:ok, nil} ->
                Item |> Ash.Changeset.for_create(:create, item_attrs) |> Ash.create()

              {:ok, item} ->
                item |> Ash.Changeset.for_update(:update, item_attrs) |> Ash.update()

              _error ->
                :ok
            end
          end
        end)

      _ ->
        :ok
    end

    :ok
  end

  defp update_items_data(_game, _params), do: :ok

  defp update_buildings_data(_game, %{"buildings" => nil}), do: :ok

  defp update_buildings_data(game, %{"buildings" => buildings}) when is_map(buildings) do
    buildings
    |> Enum.each(fn {team, team_buildings} ->
      team_buildings
      |> Enum.each(fn {building_name, building_data} ->
        building_attrs = %{
          game_id: game.id,
          name: building_name,
          team: team,
          health: building_data["health"],
          max_health: building_data["max_health"],
          type: determine_building_type(building_name)
        }

        # Upsert building by game_id, name, and team
        case Building
             |> Ash.Query.filter(game_id == ^game.id and name == ^building_name and team == ^team)
             |> Ash.read_one() do
          {:ok, nil} ->
            Building |> Ash.Changeset.for_create(:create, building_attrs) |> Ash.create()

          {:ok, building} ->
            building |> Ash.Changeset.for_update(:update, building_attrs) |> Ash.update()

          _error ->
            :ok
        end
      end)
    end)

    :ok
  end

  defp update_buildings_data(_game, _params), do: :ok

  defp update_player_data(_game, %{"player" => nil}), do: :ok

  defp update_player_data(game, %{"player" => player_data}) do
    player_attrs = %{
      game_id: game.id,
      accountid: player_data["accountid"],
      steamid: player_data["steamid"],
      name: player_data["name"],
      activity: player_data["activity"],
      kills: player_data["kills"] || 0,
      deaths: player_data["deaths"] || 0,
      assists: player_data["assists"] || 0,
      gold: player_data["gold"] || 0,
      gpm: player_data["gpm"] || 0,
      xpm: player_data["xpm"] || 0,
      last_hits: player_data["last_hits"] || 0,
      denies: player_data["denies"] || 0
    }

    # Skip if accountid is nil
    if is_nil(player_attrs.accountid) do
      :ok
    else
      # Upsert player by game_id and accountid
      case Player
           |> Ash.Query.filter(game_id == ^game.id and accountid == ^player_attrs.accountid)
           |> Ash.read_one() do
        {:ok, nil} ->
          Player |> Ash.Changeset.for_create(:create, player_attrs) |> Ash.create()

        {:ok, player} ->
          player |> Ash.Changeset.for_update(:update, player_attrs) |> Ash.update()

        _error ->
          :ok
      end
    end

    :ok
  end

  defp update_player_data(_game, _params), do: :ok

  defp determine_building_type(building_name) do
    cond do
      String.contains?(building_name, "tower") -> "tower"
      String.contains?(building_name, "rax") -> "barracks"
      String.contains?(building_name, "fort") -> "ancient"
      true -> "other"
    end
  end

  defp update_events_data(_game, %{"events" => nil}), do: :ok
  defp update_events_data(_game, %{"events" => []}), do: :ok

  defp update_events_data(game, %{"events" => events}) when is_list(events) do
    events
    |> Enum.each(fn event ->
      event_attrs = %{
        game_id: game.id,
        event_type: event["event_type"],
        game_time: event["game_time"],
        team: normalize_team(event["team"]),
        player_id: event["player_id"],
        raw_data: event
      }

      # Upsert event using the unique_event identity
      Event
      |> Ash.Changeset.for_create(:create, event_attrs)
      |> Ash.create(upsert?: true, upsert_identity: :unique_event)
    end)

    :ok
  end

  defp update_events_data(_game, _params), do: :ok

  defp normalize_team(nil), do: "both"
  defp normalize_team(""), do: "both"
  defp normalize_team(team) when is_binary(team), do: team
  defp normalize_team(_), do: "both"

  defp track_hero_location_change(game, hero, new_xpos, new_ypos)
       when is_number(new_xpos) and is_number(new_ypos) do
    # Calculate new location
    new_location = LocationMapper.coordinates_to_location(new_xpos, new_ypos)

    # Get the hero's most recent location history
    case HeroLocationHistory
         |> Ash.Query.filter(hero_id == ^hero.id)
         |> Ash.Query.sort(entered_at: :desc)
         |> Ash.Query.limit(1)
         |> Ash.read_one() do
      {:ok, nil} ->
        # No previous location history, create first entry
        create_location_history_entry(game, hero, new_location, new_xpos, new_ypos)

      {:ok, last_location} ->
        # Check if location has changed
        if last_location.location_name != new_location do
          # Check if this is a significant change worth tracking
          if LocationMapper.significant_location_change?(
               last_location.location_name,
               new_location
             ) do
            create_location_history_entry(game, hero, new_location, new_xpos, new_ypos)
          else
            # Still create entry but for any location change to maintain history
            create_location_history_entry(game, hero, new_location, new_xpos, new_ypos)
          end
        else
        end

      # If location hasn't changed, don't create a new entry

      _error ->
        # On error, still try to create entry
        create_location_history_entry(game, hero, new_location, new_xpos, new_ypos)
    end
  end

  defp track_hero_location_change(_game, _hero, _xpos, _ypos), do: :ok

  defp create_location_history_entry(game, hero, location_name, xpos, ypos) do
    location_attrs = %{
      game_id: game.id,
      hero_id: hero.id,
      hero_name: hero.name,
      location_name: location_name,
      xpos: xpos,
      ypos: ypos,
      entered_at: DateTime.utc_now()
    }

    HeroLocationHistory
    |> Ash.Changeset.for_create(:track_movement, location_attrs)
    |> Ash.create()
    |> case do
      {:ok, _entry} ->
        :ok

      {:error, _reason} ->
        # Don't fail the whole process if location tracking fails
        :ok
    end
  end
end
