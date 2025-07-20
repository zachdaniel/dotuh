defmodule Dotuh.GameState.Actions.ListAbilities do
  def run(input, _opts, _context) do
    ability_type = Map.get(input.arguments || %{}, :type, "all")

    case load_all_abilities() do
      abilities when is_list(abilities) and length(abilities) > 0 ->
        filtered_abilities = abilities
          |> Enum.filter(&matches_ability_type?(&1, ability_type))
          |> Enum.sort_by(& &1.ability_name)

        {:ok, %{
          abilities: filtered_abilities,
          count: length(filtered_abilities),
          description: "List of Dota 2 abilities with their names and basic info",
          type_filter: ability_type
        }}

      _ ->
        {:error, "Failed to load ability data from VDF files"}
    end
  end

  defp load_all_abilities() do
    # Load from main abilities file
    main_abilities = load_abilities_from_file("npc_abilities.txt")
    
    # Load from hero-specific files
    hero_abilities = load_hero_specific_abilities()
    
    (main_abilities ++ hero_abilities)
    |> Enum.uniq_by(& &1.ability_name)
  end

  defp load_abilities_from_file(filename) do
    case Dotuh.SimpleVdfParser.load_vdf_file(filename) do
      %{"DOTAAbilities" => abilities} when is_map(abilities) ->
        abilities
        |> Enum.filter(fn {ability_name, ability_data} ->
          # Filter out non-ability entries
          is_map(ability_data) and 
          not String.starts_with?(ability_name, "Version") and
          not String.starts_with?(ability_name, "item_")
        end)
        |> Enum.map(fn {ability_name, ability_data} ->
          %{
            ability_name: ability_name,
            ability_type: get_in(ability_data, ["AbilityType"]) || "basic",
            behavior: get_in(ability_data, ["AbilityBehavior"]),
            ultimate: get_in(ability_data, ["AbilityType"]) == "DOTA_ABILITY_TYPE_ULTIMATE",
            hero_specific: false,
            source_file: filename
          }
        end)

      _ -> []
    end
  end

  defp load_hero_specific_abilities() do
    # Get list of hero files
    hero_files_dir = "./dota_data/dota/scripts/npc/heroes"
    
    case File.ls(hero_files_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".txt"))
        |> Enum.flat_map(fn filename ->
          hero_name = extract_hero_name_from_file(filename)
          load_hero_abilities_from_file("heroes/" <> filename, hero_name)
        end)
      
      _ -> []
    end
  end

  defp load_hero_abilities_from_file(filepath, hero_name) do
    case Dotuh.SimpleVdfParser.load_vdf_file(filepath) do
      %{"DOTAAbilities" => abilities} when is_map(abilities) ->
        abilities
        |> Enum.filter(fn {ability_name, ability_data} ->
          is_map(ability_data) and String.starts_with?(ability_name, hero_name <> "_")
        end)
        |> Enum.map(fn {ability_name, ability_data} ->
          %{
            ability_name: ability_name,
            ability_type: get_in(ability_data, ["AbilityType"]) || "basic",
            behavior: get_in(ability_data, ["AbilityBehavior"]),
            ultimate: get_in(ability_data, ["AbilityType"]) == "DOTA_ABILITY_TYPE_ULTIMATE",
            hero_specific: true,
            hero_name: hero_name,
            source_file: filepath
          }
        end)

      _ -> []
    end
  end

  defp extract_hero_name_from_file("npc_dota_hero_" <> rest) do
    String.replace_suffix(rest, ".txt", "")
  end
  defp extract_hero_name_from_file(filename), do: filename

  defp matches_ability_type?(_ability, "all"), do: true
  defp matches_ability_type?(ability, "ultimate"), do: ability.ultimate
  defp matches_ability_type?(ability, "basic"), do: not ability.ultimate
  defp matches_ability_type?(ability, "hero_specific"), do: ability.hero_specific
  defp matches_ability_type?(ability, "generic"), do: not ability.hero_specific
  defp matches_ability_type?(_ability, _type), do: true
end