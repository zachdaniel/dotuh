defmodule Dotuh.Repo.Migrations.CreateGameStateTables do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:players, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :accountid, :text
      add :steamid, :text
      add :name, :text
      add :activity, :text
      add :kills, :bigint
      add :deaths, :bigint
      add :assists, :bigint
      add :gold, :bigint
      add :gpm, :bigint
      add :xpm, :bigint
      add :last_hits, :bigint
      add :denies, :bigint

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :game_id, :uuid
    end

    create table(:items, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text
      add :slot, :text
      add :can_cast, :boolean
      add :charges, :bigint
      add :cooldown, :bigint
      add :item_level, :bigint
      add :passive, :boolean
      add :purchaser, :bigint

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :hero_id, :uuid
    end

    create table(:heroes, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    end

    alter table(:items) do
      modify :hero_id,
             references(:heroes,
               column: :id,
               name: "items_hero_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    alter table(:heroes) do
      add :name, :text
      add :internal_name, :text
      add :level, :bigint
      add :health, :bigint
      add :max_health, :bigint
      add :mana, :bigint
      add :max_mana, :bigint
      add :xpos, :bigint
      add :ypos, :bigint
      add :alive, :boolean
      add :respawn_seconds, :bigint
      add :gold, :bigint
      add :xp, :bigint

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create table(:games, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    end

    alter table(:players) do
      modify :game_id,
             references(:games,
               column: :id,
               name: "players_game_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    alter table(:games) do
      add :match_id, :text
      add :game_time, :bigint
      add :clock_time, :bigint
      add :game_state, :text
      add :radiant_score, :bigint
      add :dire_score, :bigint
      add :paused, :boolean
      add :daytime, :boolean

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create table(:buildings, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text
      add :team, :text
      add :health, :bigint
      add :max_health, :bigint
      add :type, :text

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create table(:abilities, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text
      add :ability_active, :boolean
      add :can_cast, :boolean
      add :cooldown, :bigint
      add :level, :bigint
      add :passive, :boolean
      add :ultimate, :boolean
      add :slot, :text

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :hero_id,
          references(:heroes,
            column: :id,
            name: "abilities_hero_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end
  end

  def down do
    drop constraint(:abilities, "abilities_hero_id_fkey")

    drop table(:abilities)

    drop table(:buildings)

    alter table(:games) do
      remove :updated_at
      remove :inserted_at
      remove :daytime
      remove :paused
      remove :dire_score
      remove :radiant_score
      remove :game_state
      remove :clock_time
      remove :game_time
      remove :match_id
    end

    drop constraint(:players, "players_game_id_fkey")

    alter table(:players) do
      modify :game_id, :uuid
    end

    drop table(:games)

    alter table(:heroes) do
      remove :updated_at
      remove :inserted_at
      remove :xp
      remove :gold
      remove :respawn_seconds
      remove :alive
      remove :ypos
      remove :xpos
      remove :max_mana
      remove :mana
      remove :max_health
      remove :health
      remove :level
      remove :internal_name
      remove :name
    end

    drop constraint(:items, "items_hero_id_fkey")

    alter table(:items) do
      modify :hero_id, :uuid
    end

    drop table(:heroes)

    drop table(:items)

    drop table(:players)
  end
end
