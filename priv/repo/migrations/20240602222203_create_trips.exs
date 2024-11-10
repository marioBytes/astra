defmodule Astra.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def change do
    create table(:trips) do
      add :start_odometer, :integer
      add :end_odometer, :integer
      add :trip_date, :date
      add :trip_purpose, :string
      add :amount_driven, :integer
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:trips, [:user_id])
  end
end
