defmodule Dotuh.Repo.Migrations.AddGameRelationships do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:items) do
      add :game_id,
          references(:games,
            column: :id,
            name: "items_game_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    alter table(:heroes) do
      add :game_id,
          references(:games,
            column: :id,
            name: "heroes_game_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    alter table(:buildings) do
      add :game_id,
          references(:games,
            column: :id,
            name: "buildings_game_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    alter table(:abilities) do
      add :game_id,
          references(:games,
            column: :id,
            name: "abilities_game_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end
  end

  def down do
    drop constraint(:abilities, "abilities_game_id_fkey")

    alter table(:abilities) do
      remove :game_id
    end

    drop constraint(:buildings, "buildings_game_id_fkey")

    alter table(:buildings) do
      remove :game_id
    end

    drop constraint(:heroes, "heroes_game_id_fkey")

    alter table(:heroes) do
      remove :game_id
    end

    drop constraint(:items, "items_game_id_fkey")

    alter table(:items) do
      remove :game_id
    end
  end
end
