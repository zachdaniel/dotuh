defmodule Dotuh.GameState.PlayerNote do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer

  postgres do
    table "player_notes"
    repo Dotuh.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:note_text, :player_name, :priority]
      primary? true
    end

    destroy :destroy do
      primary? true
    end

    read :by_player_name do
      argument :player_name, :string, allow_nil?: false
      filter expr(player_name == ^arg(:player_name))
    end

    read :all_active do
      filter expr(is_nil(archived_at))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :note_text, :string do
      public? true
      allow_nil? false
      description "Observation or note about the player"
    end

    attribute :player_name, :string do
      public? true
      allow_nil? false
      description "The player this note refers to"
    end

    attribute :priority, :atom do
      public? true
      default :normal
      constraints one_of: [:low, :normal, :high, :critical]
      description "Priority level of this observation"
    end

    attribute :archived_at, :utc_datetime_usec do
      public? true
      description "When this note was archived/soft deleted"
    end

    timestamps()
  end
end