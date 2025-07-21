defmodule Dotuh.GameState.GameNote do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "game_notes"
    repo Dotuh.Repo

    references do
      reference :game, on_delete: :delete
    end
  end

  actions do
    defaults [
      :read,
      :destroy,
      create: [
        :note,
        :game_time,
        :game_id
      ],
      update: [
        :note,
        :game_time
      ]
    ]

    read :for_game do
      argument :game_id, :uuid, allow_nil?: false
      filter expr(game_id == ^arg(:game_id))
    end

    read :recent_notes do
      argument :game_id, :uuid, allow_nil?: false
      argument :since_time, :integer, allow_nil?: true

      filter expr(game_id == ^arg(:game_id))
      filter expr(if(is_nil(^arg(:since_time)), true, game_time >= ^arg(:since_time)))
      prepare build(sort: [game_time: :desc])
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :note, :string do
      allow_nil? false
      public? true
    end

    attribute :game_time, :integer do
      public? true
      description "Game time in seconds when the note was created"
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
  end
end
