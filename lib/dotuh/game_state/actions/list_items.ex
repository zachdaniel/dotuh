defmodule Dotuh.GameState.Actions.ListItems do
  def run(input, _opts, _context) do
    category_filter = Map.get(input.arguments || %{}, :category, nil)

    case Dotuh.SimpleVdfParser.load_vdf_file("items.txt") do
      %{"DOTAAbilities" => items} when is_map(items) ->
        item_list = items
          |> Enum.filter(fn {item_name, item_data} ->
            # Filter out non-item entries and basic items if category specified
            String.starts_with?(item_name, "item_") and
            is_purchasable_item?(item_data) and
            matches_category?(item_data, category_filter)
          end)
          |> Enum.map(fn {item_name, item_data} ->
            %{
              item_name: item_name,
              display_name: clean_item_name(item_name),
              cost: get_in(item_data, ["ItemCost"]) || "0",
              quality: get_in(item_data, ["ItemQuality"]) || "component",
              purchasable: get_in(item_data, ["ItemPurchasable"]) != "0",
              recipe: get_in(item_data, ["ItemRecipe"]) == "1"
            }
          end)
          |> Enum.sort_by(& &1.display_name)

        {:ok, %{
          items: item_list,
          count: length(item_list),
          description: "List of Dota 2 items with their internal and display names",
          category: category_filter
        }}

      _ ->
        {:error, "Failed to load item data from VDF files"}
    end
  end

  defp is_purchasable_item?(item_data) do
    # Filter out items that are clearly not purchasable game items
    cost = get_in(item_data, ["ItemCost"])
    purchasable = get_in(item_data, ["ItemPurchasable"])
    
    # Include items with cost or explicitly marked as purchasable
    (cost && cost != "0") or purchasable == "1"
  end

  defp matches_category?(_item_data, nil), do: true
  defp matches_category?(item_data, category) do
    quality = get_in(item_data, ["ItemQuality"]) || "component"
    
    case category do
      "consumable" -> quality == "consumable"
      "component" -> quality == "component" 
      "artifact" -> quality == "artifact"
      "epic" -> quality == "epic"
      "legendary" -> quality == "legendary"
      "recipe" -> get_in(item_data, ["ItemRecipe"]) == "1"
      _ -> true
    end
  end

  defp clean_item_name("item_" <> name) do
    name
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
  defp clean_item_name(name), do: name
end