defmodule Dotuh.GameState.Hero do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "heroes"
    repo Dotuh.Repo

    references do
      reference :game, on_delete: :delete
    end
  end

  actions do
    defaults [
      :read,
      create: [
        :name,
        :internal_name,
        :level,
        :health,
        :max_health,
        :mana,
        :max_mana,
        :xpos,
        :ypos,
        :alive,
        :respawn_seconds,
        :gold,
        :xp,
        :team,
        :is_current_player,
        :game_id
      ],
      update: [
        :name,
        :internal_name,
        :level,
        :health,
        :max_health,
        :mana,
        :max_mana,
        :xpos,
        :ypos,
        :alive,
        :respawn_seconds,
        :gold,
        :xp,
        :team,
        :is_current_player,
        :game_id
      ]
    ]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
    end

    attribute :internal_name, :string do
      public? true
    end

    attribute :level, :integer do
      public? true
    end

    attribute :health, :integer do
      public? true
    end

    attribute :max_health, :integer do
      public? true
    end

    attribute :mana, :integer do
      public? true
    end

    attribute :max_mana, :integer do
      public? true
    end

    attribute :xpos, :integer do
      public? true
    end

    attribute :ypos, :integer do
      public? true
    end

    attribute :alive, :boolean do
      public? true
    end

    attribute :respawn_seconds, :integer do
      public? true
    end

    attribute :gold, :integer do
      public? true
    end

    attribute :xp, :integer do
      public? true
    end

    attribute :team, :string do
      public? true
    end

    attribute :is_current_player, :boolean do
      public? true
      default false
    end

    timestamps()
  end

  calculations do
    calculate :hero_data, :map, {Dotuh.GameState.Calculations.VdfDataExtractor, 
      vdf_file: "npc_heroes.txt", 
      vdf_path: ["DOTAHeroes", :internal_name]
    } do
      public? true
    end
    
    calculate :localized_name, :string, {Dotuh.GameState.Calculations.VdfDataExtractor,
      vdf_file: "npc_heroes.txt",
      vdf_path: ["DOTAHeroes", :internal_name, "workshop_guide_name"]
    } do
      public? true
    end
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
    has_many :abilities, Dotuh.GameState.Ability
    has_many :items, Dotuh.GameState.Item
  end
end
