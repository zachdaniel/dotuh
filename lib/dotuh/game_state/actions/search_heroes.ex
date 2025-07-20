defmodule Dotuh.GameState.Actions.SearchHeroes do
  def run(input, _opts, _context) do
    search_term = String.downcase(input.arguments.search_term)

    case Dotuh.SimpleVdfParser.load_vdf_file("npc_heroes.txt") do
      %{"DOTAHeroes" => heroes} when is_map(heroes) ->
        matching_heroes = heroes
          |> Enum.filter(fn {hero_name, hero_data} ->
            # Only process map data (skip string values like "1")
            if is_map(hero_data) do
              hero_name_lower = String.downcase(hero_name)
              localized_name = get_in(hero_data, ["workshop_guide_name"]) || ""
              localized_name_lower = String.downcase(localized_name)
              
              String.contains?(hero_name_lower, search_term) or 
              String.contains?(localized_name_lower, search_term)
            else
              false
            end
          end)
          |> Enum.take(10)
          |> Enum.map(fn {hero_name, hero_data} ->
            %{
              internal_name: hero_name,
              localized_name: get_in(hero_data, ["workshop_guide_name"]) || hero_name,
              primary_attribute: get_in(hero_data, ["AttributePrimary"]),
              attack_type: get_in(hero_data, ["AttackCapabilities"])
            }
          end)

        {:ok, %{
          search_term: search_term,
          results: matching_heroes,
          count: length(matching_heroes)
        }}

      _ ->
        {:error, Ash.Error.Action.InvalidArgument.exception(
          field: :search_term,
          message: "Failed to load hero data from VDF files",
          value: input.arguments.search_term
        )}
    end
  end
end