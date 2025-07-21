defmodule Dotuh.GameState.Actions.ListHeroes do
  def run(_input, _opts, _context) do
    case Dotuh.SimpleVdfParser.load_vdf_file("npc_heroes.txt") do
      %{"DOTAHeroes" => heroes} when is_map(heroes) ->
        hero_list =
          heroes
          |> Enum.map(fn {internal_name, hero_data} ->
            %{
              internal_name: internal_name,
              localized_name: get_in(hero_data, ["workshop_guide_name"]) || internal_name,
              primary_attribute: get_in(hero_data, ["AttributePrimary"]),
              attack_type: get_in(hero_data, ["AttackCapabilities"]),
              complexity: get_in(hero_data, ["Complexity"])
            }
          end)
          |> Enum.sort_by(& &1.localized_name)

        {:ok,
         %{
           heroes: hero_list,
           count: length(hero_list),
           description: "Complete list of all Dota 2 heroes with their internal and display names"
         }}

      _ ->
        {:error, "Failed to load hero data from VDF files"}
    end
  end
end
