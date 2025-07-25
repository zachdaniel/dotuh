defmodule Dotuh.Repo.Migrations.AddHeroIsCurrentPlayer do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:heroes) do
      add :is_current_player, :boolean, default: false
    end
  end

  def down do
    alter table(:heroes) do
      remove :is_current_player
    end
  end
end
