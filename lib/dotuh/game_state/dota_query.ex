defmodule Dotuh.GameState.DotaQuery do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState

  actions do
    action :query_hero, :map do
      argument :hero_name, :string, allow_nil?: false
      run Dotuh.GameState.Actions.QueryHeroData
    end

    action :query_item, :map do
      argument :item_name, :string, allow_nil?: false
      run Dotuh.GameState.Actions.QueryItemData
    end

    action :query_ability, :map do
      argument :ability_name, :string, allow_nil?: false
      run Dotuh.GameState.Actions.QueryAbilityData
    end

    action :search_heroes, :map do
      argument :search_term, :string, allow_nil?: false
      run Dotuh.GameState.Actions.SearchHeroes
    end

    action :search_items, :map do
      argument :search_term, :string, allow_nil?: false
      run Dotuh.GameState.Actions.SearchItems
    end

    action :list_heroes, :map do
      run Dotuh.GameState.Actions.ListHeroes
    end

    action :list_items, :map do
      argument :category, :string, allow_nil?: true
      run Dotuh.GameState.Actions.ListItems
    end

    action :list_abilities, :map do
      argument :type, :string, allow_nil?: true
      run Dotuh.GameState.Actions.ListAbilities
    end

    action :query_hero_abilities, :map do
      argument :hero_name, :string, allow_nil?: false
      run Dotuh.GameState.Actions.QueryHeroAbilities
    end
  end
end

