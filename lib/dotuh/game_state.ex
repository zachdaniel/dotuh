defmodule Dotuh.GameState do
  use Ash.Domain,
    otp_app: :dotuh,
    extensions: [AshAi]

  tools do
    tool :get_current_game_state, Dotuh.GameState.Game, :get_current_game_state do
      load [
        :players,
        :buildings,
        :game_notes,
        heroes: [:hero_data, :localized_name],
        items: [:item_data, :cost],
        abilities: [:ability_data, :ability_description]
      ]

      description "Get the most recent Dota 2 game state including all heroes, items, abilities, players, buildings, and game notes with their enhanced data from the game files"
    end

    tool :add_game_note, Dotuh.GameState.GameNote, :create do
      description "Add a note from the player about the current game situation. Use this when the player provides context, feedback, or observations that should be remembered for coaching advice."
    end

    tool :get_game_notes, Dotuh.GameState.GameNote, :for_game do
      description "Get all notes for the current game to understand player context and concerns"
    end

    tool :get_recent_game_notes, Dotuh.GameState.GameNote, :recent_notes do
      description "Get recent game notes, optionally since a specific game time"
    end

    tool :query_hero_data, Dotuh.GameState.DotaQuery, :query_hero do
      description "Get detailed information about a specific Dota 2 hero from game files. Provide the internal hero name (e.g., 'npc_dota_hero_pudge')."
    end

    tool :query_item_data, Dotuh.GameState.DotaQuery, :query_item do
      description "Get detailed information about a specific Dota 2 item from game files. Provide the item name (e.g., 'item_black_king_bar')."
    end

    tool :query_ability_data, Dotuh.GameState.DotaQuery, :query_ability do
      description "Get detailed information about a specific Dota 2 ability from game files. Works with both generic abilities and hero-specific abilities."
    end

    tool :search_heroes, Dotuh.GameState.DotaQuery, :search_heroes do
      description "Search for Dota 2 heroes by name or partial name. Returns a list of matching heroes with basic information."
    end

    tool :search_items, Dotuh.GameState.DotaQuery, :search_items do
      description "Search for Dota 2 items by name or partial name. Returns a list of matching items with basic information."
    end

    tool :list_heroes, Dotuh.GameState.DotaQuery, :list_heroes do
      description "Get a complete list of all Dota 2 heroes with their internal and display names. Use this for disambiguation when the user mentions a hero name incorrectly."
    end

    tool :list_items, Dotuh.GameState.DotaQuery, :list_items do
      description "Get a complete list of all Dota 2 items with their names. Optionally filter by category (consumable, component, artifact, epic, legendary, recipe). Use this for disambiguation when the user mentions an item name incorrectly."
    end

    tool :list_abilities, Dotuh.GameState.DotaQuery, :list_abilities do
      description "Get a complete list of all Dota 2 abilities. Optionally filter by type (all, ultimate, basic, hero_specific, generic). Use this for disambiguation when the user mentions an ability name incorrectly."
    end

    tool :query_hero_abilities, Dotuh.GameState.DotaQuery, :query_hero_abilities do
      description "Get all abilities for a specific hero including cooldowns, mana costs, Aghanim's Scepter/Shard upgrades, and ability values. Provide the hero name (e.g., 'pudge' or 'npc_dota_hero_pudge')."
    end

    tool :add_player_note, Dotuh.GameState.PlayerNote, :create do
      description "Add a note about a specific player's behavior, tendencies, or patterns. Use this to remember important observations about players that can help with future coaching."
    end

    tool :get_player_notes, Dotuh.GameState.PlayerNote, :by_player_name do
      description "Get all active notes for a specific player to understand their patterns and previous observations."
    end

    tool :get_all_player_notes, Dotuh.GameState.PlayerNote, :all_active do
      description "Get all active player notes to understand overall player patterns and observations."
    end

    tool :destroy_player_note, Dotuh.GameState.PlayerNote, :destroy do
      description "Remove a player note when it's no longer relevant or accurate."
    end

    tool :destroy_game_note, Dotuh.GameState.GameNote, :destroy do
      description "Remove a game note when it's no longer relevant."
    end

    tool :get_recent_hero_movements, Dotuh.GameState.HeroLocationHistory, :recent_movements do
      description "Get recent hero location changes for the current active game to spot enemy movements, rotations, and potential ganks. Shows where heroes have been spotted recently. No game_id needed - automatically uses current game."
    end

    tool :get_hero_location_history, Dotuh.GameState.HeroLocationHistory, :for_hero do
      description "Get location history for a specific hero to understand their movement patterns and current whereabouts."
    end

    tool :get_location_activity, Dotuh.GameState.HeroLocationHistory, :recent_by_location do
      description "See which heroes have been spotted in a specific location recently. Useful for checking if enemies are in key areas like Roshan pit, jungle, or lanes. Can optionally provide game_id, otherwise uses current active game."
    end
  end

  resources do
    resource Dotuh.GameState.Hero
    resource Dotuh.GameState.Ability
    resource Dotuh.GameState.Item
    resource Dotuh.GameState.Building
    resource Dotuh.GameState.Game
    resource Dotuh.GameState.Event
    resource Dotuh.GameState.Player
    resource Dotuh.GameState.GameNote
    resource Dotuh.GameState.PlayerNote
    resource Dotuh.GameState.HeroLocationHistory
    resource Dotuh.GameState.DotaQuery
  end
end
