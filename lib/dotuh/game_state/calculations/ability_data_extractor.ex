defmodule Dotuh.GameState.Calculations.AbilityDataExtractor do
  use Ash.Resource.Calculation

  @impl true
  def init(opts) do
    if opts[:vdf_path] do
      {:ok, opts}
    else
      {:error, "AbilityDataExtractor requires :vdf_path option"}
    end
  end

  @impl true
  def calculate(records, opts, _context) do
    vdf_path = opts[:vdf_path]

    Enum.map(records, fn record ->
      # Try to find the ability in multiple locations
      find_ability_data(record, vdf_path)
    end)
  end

  defp find_ability_data(record, vdf_path) do
    ability_name = record.name

    # First, try the main abilities file
    case try_main_abilities_file(ability_name, vdf_path) do
      nil ->
        # If not found, try to infer the hero and look in the hero-specific file
        try_hero_specific_file(ability_name, vdf_path)

      data ->
        data
    end
  end

  defp try_main_abilities_file(ability_name, vdf_path) do
    case load_vdf_file("npc_abilities.txt") do
      %{"DOTAAbilities" => abilities} when is_map(abilities) ->
        actual_path = build_path_with_name(vdf_path, ability_name)
        get_nested_value(abilities, actual_path)

      _ ->
        nil
    end
  end

  defp try_hero_specific_file(ability_name, vdf_path) do
    # Extract hero name from ability name (e.g., "muerta_dead_shot" -> "muerta")
    case extract_hero_name(ability_name) do
      nil ->
        nil

      hero_name ->
        hero_file = "heroes/npc_dota_hero_#{hero_name}.txt"

        case load_vdf_file(hero_file) do
          %{"DOTAAbilities" => abilities} when is_map(abilities) ->
            actual_path = build_path_with_name(vdf_path, ability_name)
            get_nested_value(abilities, actual_path)

          _ ->
            nil
        end
    end
  end

  defp extract_hero_name(ability_name) do
    # Most hero abilities follow the pattern "heroname_abilityname"
    case String.split(ability_name, "_", parts: 2) do
      [hero_name, _ability_part] when hero_name != "" -> hero_name
      _ -> nil
    end
  end

  defp load_vdf_file(vdf_file) do
    data_path = Path.join([File.cwd!(), "dota_data", "dota", "scripts", "npc", vdf_file])

    case Dotuh.SimpleVdfParser.parse_file(data_path) do
      {:ok, data} -> data
      {:error, _error} -> %{}
    end
  end

  defp build_path_with_name(vdf_path, ability_name) do
    Enum.map(vdf_path, fn
      segment when is_binary(segment) -> segment
      :name -> ability_name
      segment -> segment
    end)
  end

  defp get_nested_value(data, []) do
    data
  end

  defp get_nested_value(data, [key | rest]) when is_map(data) and not is_nil(key) do
    case Map.get(data, to_string(key)) do
      nil -> nil
      value -> get_nested_value(value, rest)
    end
  end

  defp get_nested_value(_data, _path) do
    nil
  end
end
