defmodule Dotuh.GameState.Ability do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "abilities"
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
        :ability_active,
        :can_cast,
        :cooldown,
        :level,
        :passive,
        :ultimate,
        :slot,
        :hero_id,
        :game_id
      ],
      update: [
        :name,
        :ability_active,
        :can_cast,
        :cooldown,
        :level,
        :passive,
        :ultimate,
        :slot,
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

    attribute :ability_active, :boolean do
      public? true
    end

    attribute :can_cast, :boolean do
      public? true
    end

    attribute :cooldown, :integer do
      public? true
    end

    attribute :level, :integer do
      public? true
    end

    attribute :passive, :boolean do
      public? true
    end

    attribute :ultimate, :boolean do
      public? true
    end

    attribute :slot, :string do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
    belongs_to :hero, Dotuh.GameState.Hero
  end

  calculations do
    calculate :ability_data,
              :map,
              {Dotuh.GameState.Calculations.AbilityDataExtractor, vdf_path: [:name]} do
      public? true
    end

    calculate :ability_description, :string, fn records, _context ->
      # Descriptions are in localization files, not VDF data
      # For now, return a placeholder or nil
      Enum.map(records, fn _record -> nil end)
    end do
      public? true
    end
  end
end
