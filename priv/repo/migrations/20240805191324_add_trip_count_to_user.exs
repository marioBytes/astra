defmodule Astra.Repo.Migrations.AddTripCountToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :trip_count, :integer, null: false, default: 0
    end
  end
end
