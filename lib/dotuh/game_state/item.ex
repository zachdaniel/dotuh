defmodule Dotuh.GameState.Item do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "items"
    repo Dotuh.Repo

    references do
      reference :game, on_delete: :delete
      reference :hero, on_delete: :delete
    end
  end

  actions do
    defaults [
      :read,
      create: [
        :name,
        :slot,
        :can_cast,
        :charges,
        :cooldown,
        :item_level,
        :passive,
        :purchaser,
        :hero_id,
        :game_id
      ],
      update: [
        :name,
        :slot,
        :can_cast,
        :charges,
        :cooldown,
        :item_level,
        :passive,
        :purchaser,
        :hero_id,
        :game_id
      ]
    ]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
    end

    attribute :slot, :string do
      public? true
    end

    attribute :can_cast, :boolean do
      public? true
    end

    attribute :charges, :integer do
      public? true
    end

    attribute :cooldown, :integer do
      public? true
    end

    attribute :item_level, :integer do
      public? true
    end

    attribute :passive, :boolean do
      public? true
    end

    attribute :purchaser, :integer do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
    belongs_to :hero, Dotuh.GameState.Hero
  end

  calculations do
    calculate :item_data,
              :map,
              {Dotuh.GameState.Calculations.VdfDataExtractor,
               vdf_file: "items.txt", vdf_path: ["DOTAAbilities", :name]} do
      public? true
    end

    calculate :cost,
              :integer,
              {Dotuh.GameState.Calculations.VdfDataExtractor,
               vdf_file: "items.txt", vdf_path: ["DOTAAbilities", :name, "ItemCost"]} do
      public? true
    end
  end
end
