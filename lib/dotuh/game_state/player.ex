defmodule Dotuh.GameState.Player do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "players"
    repo Dotuh.Repo

    references do
      reference :game, on_delete: :delete
    end
  end

  actions do
    defaults [
      :read,
      create: [
        :accountid,
        :steamid,
        :name,
        :activity,
        :kills,
        :deaths,
        :assists,
        :gold,
        :gpm,
        :xpm,
        :last_hits,
        :denies
      ],
      update: [
        :accountid,
        :steamid,
        :name,
        :activity,
        :kills,
        :deaths,
        :assists,
        :gold,
        :gpm,
        :xpm,
        :last_hits,
        :denies
      ]
    ]
  end

  attributes do
    uuid_primary_key :id

    attribute :accountid, :string do
      public? true
    end

    attribute :steamid, :string do
      public? true
    end

    attribute :name, :string do
      public? true
    end

    attribute :activity, :string do
      public? true
    end

    attribute :kills, :integer do
      public? true
    end

    attribute :deaths, :integer do
      public? true
    end

    attribute :assists, :integer do
      public? true
    end

    attribute :gold, :integer do
      public? true
    end

    attribute :gpm, :integer do
      public? true
    end

    attribute :xpm, :integer do
      public? true
    end

    attribute :last_hits, :integer do
      public? true
    end

    attribute :denies, :integer do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
  end
end
