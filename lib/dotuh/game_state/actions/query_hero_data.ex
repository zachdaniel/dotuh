defmodule Dotuh.GameState.Actions.QueryHeroData do
  def run(input, _opts, _context) do
    hero_name = input.arguments.hero_name

    case Dotuh.SimpleVdfParser.load_vdf_file("npc_heroes.txt") do
      %{"DOTAHeroes" => heroes} when is_map(heroes) ->
        hero_data = heroes[hero_name]

        if hero_data do
          {:ok,
           %{
             hero_name: hero_name,
             data: hero_data,
             localized_name: get_in(hero_data, ["workshop_guide_name"]) || hero_name,
             description: "Hero data from Dota 2 game files"
           }}
        else
          available_heroes = Map.keys(heroes)

          {:error,
           Ash.Error.Action.InvalidArgument.exception(
             field: :hero_name,
             message:
               "Hero '#{hero_name}' not found. Available heroes: #{Enum.join(available_heroes, ", ")}",
             value: hero_name
           )}
        end

      _ ->
        {:error,
         Ash.Error.Action.InvalidArgument.exception(
           field: :hero_name,
           message: "Failed to load hero data from VDF files",
           value: hero_name
         )}
    end
  end
end
