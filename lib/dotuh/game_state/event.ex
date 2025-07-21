defmodule Dotuh.GameState.Event do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "events"
    repo Dotuh.Repo

    references do
      reference :game, on_delete: :delete
    end
  end

  actions do
    defaults [
      :read,
      create: [
        :event_type,
        :game_time,
        :team,
        :player_id,
        :raw_data,
        :game_id
      ],
      update: [
        :event_type,
        :game_time,
        :team,
        :player_id,
        :raw_data,
        :game_id
      ]
    ]
  end

  attributes do
    uuid_primary_key :id

    attribute :event_type, :string do
      allow_nil? false
      public? true
    end

    attribute :game_time, :integer do
      public? true
    end

    attribute :team, :string do
      public? true
      default "both"
    end

    attribute :player_id, :integer do
      public? true
    end

    attribute :raw_data, :map do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
  end

  identities do
    identity :unique_event, [:game_id, :game_time, :player_id]
  end
end
