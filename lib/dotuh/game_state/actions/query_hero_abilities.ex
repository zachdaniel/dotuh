defmodule Dotuh.GameState.Actions.QueryHeroAbilities do
  def run(input, _opts, _context) do
    hero_name = input.arguments.hero_name

    # First, try to load the hero-specific file
    hero_abilities = load_hero_specific_abilities(hero_name)
    
    # Also get basic hero info to include Aghanim's upgrade flags
    hero_info = get_hero_basic_info(hero_name)

    if Enum.any?(hero_abilities) do
      {:ok, %{
        hero_name: hero_name,
        abilities: hero_abilities,
        hero_info: hero_info,
        total_abilities: length(hero_abilities),
        description: "All abilities for #{hero_name} including Aghanim's upgrade information"
      }}
    else
      {:error, Ash.Error.Action.InvalidArgument.exception(
        field: :hero_name,
        message: "Hero '#{hero_name}' not found or has no ability data. Use list_heroes to see available heroes.",
        value: hero_name
      )}
    end
  end

  defp load_hero_specific_abilities(hero_name) do
    # Clean hero name if it starts with npc_dota_hero_
    clean_hero_name = String.replace_prefix(hero_name, "npc_dota_hero_", "")
    hero_file = "heroes/npc_dota_hero_#{clean_hero_name}.txt"
    
    case Dotuh.SimpleVdfParser.load_vdf_file(hero_file) do
      %{"DOTAAbilities" => abilities} when is_map(abilities) ->
        abilities
        |> Enum.filter(fn {ability_name, ability_data} ->
          # Filter for actual abilities (not Version or other metadata)
          is_map(ability_data) and 
          not String.starts_with?(ability_name, "Version") and
          not String.starts_with?(ability_name, "item_") and
          ability_name != ""
        end)
        |> Enum.map(fn {ability_name, ability_data} ->
          %{
            ability_name: ability_name,
            ability_behavior: get_in(ability_data, ["AbilityBehavior"]),
            ability_type: get_in(ability_data, ["AbilityType"]),
            max_level: get_in(ability_data, ["MaxLevel"]),
            cooldown: get_in(ability_data, ["AbilityCooldown"]),
            mana_cost: get_in(ability_data, ["AbilityManaCost"]),
            cast_point: get_in(ability_data, ["AbilityCastPoint"]),
            cast_range: get_in(ability_data, ["AbilityCastRange"]),
            damage_type: get_in(ability_data, ["AbilityUnitDamageType"]),
            has_scepter_upgrade: get_in(ability_data, ["HasScepterUpgrade"]) == "1",
            has_shard_upgrade: get_in(ability_data, ["HasShardUpgrade"]) == "1",
            ability_values: extract_ability_values(ability_data),
            scepter_upgrades: extract_scepter_upgrades(ability_data),
            shard_upgrades: extract_shard_upgrades(ability_data)
          }
        end)

      _ -> []
    end
  end

  defp get_hero_basic_info(hero_name) do
    # Clean hero name if it starts with npc_dota_hero_
    clean_hero_name = String.replace_prefix(hero_name, "npc_dota_hero_", "")
    full_hero_name = "npc_dota_hero_#{clean_hero_name}"
    
    case Dotuh.SimpleVdfParser.load_vdf_file("npc_heroes.txt") do
      %{"DOTAHeroes" => heroes} when is_map(heroes) ->
        case heroes[full_hero_name] do
          hero_data when is_map(hero_data) ->
            %{
              localized_name: get_in(hero_data, ["workshop_guide_name"]) || full_hero_name,
              primary_attribute: get_in(hero_data, ["AttributePrimary"]),
              attack_type: get_in(hero_data, ["AttackCapabilities"]),
              complexity: get_in(hero_data, ["Complexity"]),
              role_levels: get_in(hero_data, ["RoleLevels"])
            }
          _ -> %{}
        end
      _ -> %{}
    end
  end

  defp extract_ability_values(ability_data) do
    case get_in(ability_data, ["AbilityValues"]) do
      values when is_map(values) ->
        values
        |> Enum.take(5) # Limit to first 5 to avoid overwhelming output
        |> Enum.into(%{})
      _ -> %{}
    end
  end

  defp extract_scepter_upgrades(ability_data) do
    ability_values = get_in(ability_data, ["AbilityValues"]) || %{}
    
    scepter_upgrades = ability_values
    |> Enum.filter(fn {_key, value} ->
      case value do
        %{"special_bonus_scepter" => _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {key, value} ->
      {key, value["special_bonus_scepter"]}
    end)
    |> Enum.into(%{})

    # Also check for scepter_bonus_levels
    scepter_levels = get_in(ability_data, ["AbilityValues", "scepter_bonus_levels"])
    
    if map_size(scepter_upgrades) > 0 or scepter_levels do
      Map.put(scepter_upgrades, "scepter_bonus_levels", scepter_levels)
    else
      %{}
    end
  end

  defp extract_shard_upgrades(ability_data) do
    ability_values = get_in(ability_data, ["AbilityValues"]) || %{}
    
    ability_values
    |> Enum.filter(fn {_key, value} ->
      case value do
        %{"special_bonus_shard" => _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {key, value} ->
      {key, value["special_bonus_shard"]}
    end)
    |> Enum.into(%{})
  end
end