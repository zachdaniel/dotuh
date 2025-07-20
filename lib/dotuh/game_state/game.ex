defmodule Dotuh.GameState.Game do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "games"
    repo Dotuh.Repo
  end

  actions do
    defaults [
      :read,
      create: [
        :match_id,
        :game_time,
        :clock_time,
        :game_state,
        :radiant_score,
        :dire_score,
        :paused,
        :daytime
      ],
      update: [
        :match_id,
        :game_time,
        :clock_time,
        :game_state,
        :radiant_score,
        :dire_score,
        :paused,
        :daytime
      ]
    ]

    read :get_current_game_state do
      description "Get the most recent active game and all related data (heroes, items, abilities, players, buildings)"

      filter expr(active == true)
      
      prepare build(
                sort: [inserted_at: :desc],
                limit: 1,
                load: [
                  :active,
                  :players,
                  :buildings,
                  :game_notes,
                  heroes: [:hero_data, :localized_name],
                  items: [:item_data, :cost],
                  abilities: [:ability_data, :ability_description]
                ]
              )
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :match_id, :string do
      public? true
    end

    attribute :game_time, :integer do
      public? true
    end

    attribute :clock_time, :integer do
      public? true
    end

    attribute :game_state, :string do
      public? true
    end

    attribute :radiant_score, :integer do
      public? true
    end

    attribute :dire_score, :integer do
      public? true
    end

    attribute :paused, :boolean do
      public? true
    end

    attribute :daytime, :boolean do
      public? true
    end

    timestamps()
  end

  calculations do
    calculate :active, :boolean, expr(game_state == "DOTA_GAMERULES_STATE_GAME_IN_PROGRESS")
  end

  relationships do
    has_many :heroes, Dotuh.GameState.Hero
    has_many :abilities, Dotuh.GameState.Ability
    has_many :items, Dotuh.GameState.Item
    has_many :buildings, Dotuh.GameState.Building
    has_many :players, Dotuh.GameState.Player
    has_many :game_notes, Dotuh.GameState.GameNote
  end
end
