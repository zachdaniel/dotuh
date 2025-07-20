defmodule Dotuh.GameState.Building do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "buildings"
    repo Dotuh.Repo

    references do
      reference :game, on_delete: :delete
    end
  end

  actions do
    defaults [
      :read,
      create: [:name, :team, :health, :max_health, :type, :game_id],
      update: [:name, :team, :health, :max_health, :type, :game_id]
    ]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
    end

    attribute :team, :string do
      public? true
    end

    attribute :health, :integer do
      public? true
    end

    attribute :max_health, :integer do
      public? true
    end

    attribute :type, :string do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
  end
end
