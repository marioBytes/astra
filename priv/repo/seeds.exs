# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Astra.Repo.insert!(%Astra.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Astra.Accounts.User
alias Astra.CarTrips.Trip
alias Astra.Repo

users = [
  %{id: 1, email: "mario@astra.io", password: "12345678"},
  %{id: 2, email: "bob@astra.io", password: "12345678"},
  %{id: 3, email: "sonya@astra.io", password: "12345678"},
  %{id: 4, email: "bella@astra.io", password: "12345678"}
]

purposes = ["Business", "Personal", "Other"]

Enum.map(users, fn u ->
  %User{}
  |> User.registration_changeset(u)
  |> Repo.insert!()

  Enum.map(1..100, fn _i ->
    start_odometer = :rand.uniform(200_000)
    end_odometer = start_odometer + :rand.uniform(100)
    miles_driven = end_odometer - start_odometer

    month = :rand.uniform(12)
    day = :rand.uniform(28)

    {:ok, trip_date} = Date.new(2024, month, day)

    purpose = Enum.random(purposes)

    trip_changeset = %{
      start_odometer: start_odometer,
      end_odometer: end_odometer,
      trip_date: trip_date,
      trip_purpose: purpose,
      miles_driven: miles_driven,
      user_id: u.id
    }

    %Trip{}
    |> Trip.changeset(trip_changeset)
    |> Repo.insert!()
  end)
end)
