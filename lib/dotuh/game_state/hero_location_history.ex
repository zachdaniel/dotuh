defmodule Dotuh.GameState.HeroLocationHistory do
  use Ash.Resource, otp_app: :dotuh, domain: Dotuh.GameState, data_layer: AshPostgres.DataLayer
  require Ash.Query

  postgres do
    table "hero_location_history"
    repo Dotuh.Repo

    references do
      reference :game, on_delete: :delete
      reference :hero, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :track_movement do
      accept [:game_id, :hero_id, :hero_name, :location_name, :xpos, :ypos, :entered_at]
      primary? true
    end

    read :recent_movements do
      argument :minutes_ago, :integer, allow_nil?: true, default: 5

      prepare fn query, _context ->
        # Get the current active game and filter by it
        case Dotuh.GameState.Game
             |> Ash.Query.filter(active == true)
             |> Ash.Query.sort(inserted_at: :desc)
             |> Ash.Query.limit(1)
             |> Ash.read_one() do
          {:ok, nil} ->
            # No active game, filter to return nothing
            query |> Ash.Query.filter(false)

          {:ok, game} ->
            # Filter by the active game
            query
            |> Ash.Query.filter(game_id == ^game.id)
            |> Ash.Query.filter(entered_at >= ago(^query.arguments.minutes_ago, :minute))
            |> Ash.Query.sort(entered_at: :desc)

          {:error, _error} ->
            # On error, filter to return nothing
            query |> Ash.Query.filter(false)
        end
      end
    end

    read :for_hero do
      argument :hero_id, :uuid, allow_nil?: false
      argument :limit, :integer, allow_nil?: true, default: 10

      filter expr(hero_id == ^arg(:hero_id))
      prepare build(sort: [entered_at: :desc], limit: arg(:limit))
    end

    read :recent_by_location do
      argument :location_name, :string, allow_nil?: false
      argument :game_id, :uuid, allow_nil?: true
      argument :minutes_ago, :integer, allow_nil?: true, default: 2

      prepare fn query, _context ->
        # Use provided game_id or get the current active game
        game_id =
          case query.arguments.game_id do
            nil ->
              case Dotuh.GameState.Game
                   |> Ash.Query.filter(active == true)
                   |> Ash.Query.sort(inserted_at: :desc)
                   |> Ash.Query.limit(1)
                   |> Ash.read_one() do
                {:ok, game} when not is_nil(game) -> game.id
                _ -> nil
              end

            id ->
              id
          end

        case game_id do
          nil ->
            # No active game, filter to return nothing
            query |> Ash.Query.filter(false)

          id ->
            # Filter by game and location
            query
            |> Ash.Query.filter(game_id == ^id)
            |> Ash.Query.filter(location_name == ^query.arguments.location_name)
            |> Ash.Query.filter(entered_at >= ago(^query.arguments.minutes_ago, :minute))
            |> Ash.Query.sort(entered_at: :desc)
        end
      end
    end

    read :significant_movements do
      argument :game_id, :uuid, allow_nil?: true
      argument :minutes_ago, :integer, allow_nil?: true, default: 3

      prepare fn query, _context ->
        # Use provided game_id or get the current active game
        game_id =
          case query.arguments.game_id do
            nil ->
              case Dotuh.GameState.Game
                   |> Ash.Query.filter(active == true)
                   |> Ash.Query.sort(inserted_at: :desc)
                   |> Ash.Query.limit(1)
                   |> Ash.read_one() do
                {:ok, game} when not is_nil(game) -> game.id
                _ -> nil
              end

            id ->
              id
          end

        case game_id do
          nil ->
            # No active game, filter to return nothing
            query |> Ash.Query.filter(false)

          id ->
            # Filter by game and time - significance filtering will be done in application code
            query
            |> Ash.Query.filter(game_id == ^id)
            |> Ash.Query.filter(entered_at >= ago(^arg(:minutes_ago), :minute))
            |> Ash.Query.sort(entered_at: :desc)
        end
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :hero_name, :string do
      public? true
      allow_nil? false
      description "Name of the hero for easy identification"
    end

    attribute :location_name, :string do
      public? true
      allow_nil? false
      description "The location name (from LocationMapper)"
    end

    attribute :xpos, :integer do
      public? true
      description "Exact X coordinate when entering this location"
    end

    attribute :ypos, :integer do
      public? true
      description "Exact Y coordinate when entering this location"
    end

    attribute :entered_at, :utc_datetime_usec do
      public? true
      allow_nil? false
      default &DateTime.utc_now/0
      description "When the hero entered this location"
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Dotuh.GameState.Game
    belongs_to :hero, Dotuh.GameState.Hero
  end

  identities do
    # Prevent duplicate entries for same hero entering same location at same time
    identity :unique_movement, [:game_id, :hero_id, :location_name, :entered_at]
  end
end

