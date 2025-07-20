defmodule Dotuh.GameState.Actions.QueryAbilityData do
  def run(input, _opts, _context) do
    ability_name = input.arguments.ability_name

    # First try the main abilities file
    case try_main_abilities_file(ability_name) do
      {:ok, result} -> {:ok, result}
      {:error, _} -> try_hero_specific_files(ability_name)
    end
  end

  defp try_main_abilities_file(ability_name) do
    case Dotuh.SimpleVdfParser.load_vdf_file("npc_abilities.txt") do
      %{"DOTAAbilities" => abilities} when is_map(abilities) ->
        ability_data = abilities[ability_name]
        
        if ability_data do
          {:ok, %{
            ability_name: ability_name,
            data: ability_data,
            description: get_in(ability_data, ["AbilitySpecial", "01", "description"]) || "Ability data from Dota 2 game files",
            cooldown: get_in(ability_data, ["AbilityCooldown"]),
            mana_cost: get_in(ability_data, ["AbilityManaCost"]),
            ability_type: get_in(ability_data, ["AbilityType"])
          }}
        else
          {:error, Ash.Error.Action.InvalidArgument.exception(
          field: :ability_name,
          message: "Ability not found in main file",
          value: ability_name
        )}
        end

      _ ->
        {:error, Ash.Error.Action.InvalidArgument.exception(
          field: :ability_name,
          message: "Failed to load main abilities file",
          value: ability_name
        )}
    end
  end

  defp try_hero_specific_files(ability_name) do
    # Extract hero name from ability name (e.g., "muerta_dead_shot" -> "muerta")
    case extract_hero_name(ability_name) do
      nil -> 
        {:error, Ash.Error.Action.InvalidArgument.exception(
          field: :ability_name,
          message: "Ability '#{ability_name}' not found in any files",
          value: ability_name
        )}
      
      hero_name ->
        hero_file = "heroes/npc_dota_hero_#{hero_name}.txt"
        
        case Dotuh.SimpleVdfParser.load_vdf_file(hero_file) do
          %{"DOTAAbilities" => abilities} when is_map(abilities) ->
            ability_data = abilities[ability_name]
            
            if ability_data do
              {:ok, %{
                ability_name: ability_name,
                data: ability_data,
                description: get_in(ability_data, ["AbilitySpecial", "01", "description"]) || "Hero-specific ability data from Dota 2 game files",
                cooldown: get_in(ability_data, ["AbilityCooldown"]),
                mana_cost: get_in(ability_data, ["AbilityManaCost"]),
                ability_type: get_in(ability_data, ["AbilityType"]),
                hero_file: hero_file
              }}
            else
              {:error, Ash.Error.Action.InvalidArgument.exception(
                field: :ability_name,
                message: "Ability '#{ability_name}' not found in hero file #{hero_file}",
                value: ability_name
              )}
            end

          _ ->
            {:error, Ash.Error.Action.InvalidArgument.exception(
              field: :ability_name,
              message: "Failed to load hero-specific file #{hero_file}",
              value: ability_name
            )}
        end
    end
  end

  defp extract_hero_name(ability_name) do
    # Extract hero name from ability name (e.g., "muerta_dead_shot" -> "muerta")
    case String.split(ability_name, "_", parts: 2) do
      [hero_name, _ability_part] when hero_name != "" -> hero_name
      _ -> nil
    end
  end
end