defmodule Dotuh.GameState.Actions.SearchItems do
  def run(input, _opts, _context) do
    search_term = String.downcase(input.arguments.search_term)

    case Dotuh.SimpleVdfParser.load_vdf_file("items.txt") do
      %{"DOTAAbilities" => items} when is_map(items) ->
        matching_items = items
          |> Enum.filter(fn {item_name, _item_data} ->
            item_name_lower = String.downcase(item_name)
            String.contains?(item_name_lower, search_term)
          end)
          |> Enum.take(15)
          |> Enum.map(fn {item_name, item_data} ->
            %{
              item_name: item_name,
              cost: get_in(item_data, ["ItemCost"]),
              item_tier: get_in(item_data, ["ItemQuality"]),
              purchasable: get_in(item_data, ["ItemPurchasable"])
            }
          end)

        {:ok, %{
          search_term: search_term,
          results: matching_items,
          count: length(matching_items)
        }}

      _ ->
        {:error, Ash.Error.Action.InvalidArgument.exception(
          field: :search_term,
          message: "Failed to load item data from VDF files",
          value: input.arguments.search_term
        )}
    end
  end
end