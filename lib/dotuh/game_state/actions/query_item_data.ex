defmodule Dotuh.GameState.Actions.QueryItemData do
  def run(input, _opts, _context) do
    item_name = input.arguments.item_name

    case Dotuh.SimpleVdfParser.load_vdf_file("items.txt") do
      %{"DOTAAbilities" => items} when is_map(items) ->
        item_data = items[item_name]
        
        if item_data do
          {:ok, %{
            item_name: item_name,
            data: item_data,
            cost: get_in(item_data, ["ItemCost"]),
            description: get_in(item_data, ["AbilitySpecial", "01", "description"]) || "Item data from Dota 2 game files"
          }}
        else
          # Try to find items with partial name match
          matching_items = items
            |> Enum.filter(fn {key, _value} -> 
              String.contains?(String.downcase(key), String.downcase(item_name))
            end)
            |> Enum.take(10)
            |> Enum.map(fn {key, _value} -> key end)

          if Enum.any?(matching_items) do
            {:error, Ash.Error.Action.InvalidArgument.exception(
              field: :item_name,
              message: "Item '#{item_name}' not found. Did you mean: #{Enum.join(matching_items, ", ")}",
              value: item_name
            )}
          else
            {:error, Ash.Error.Action.InvalidArgument.exception(
              field: :item_name,
              message: "Item '#{item_name}' not found. Please check the item name.",
              value: item_name
            )}
          end
        end

      _ ->
        {:error, Ash.Error.Action.InvalidArgument.exception(
          field: :item_name,
          message: "Failed to load item data from VDF files",
          value: item_name
        )}
    end
  end
end