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
alias Ecto.Multi

# Create constant for trip purposes
purposes = [:Business, :Personal, :Other]

# Inserts users
[
  %{email: "mario@astra.io", password: "password1234"},
  %{email: "bob@astra.io", password: "password1234"},
  %{email: "sonya@astra.io", password: "password1234"},
  %{email: "bella@astra.io", password: "password1234"}
]
|> Enum.map(fn u ->
  %User{}
  |> User.registration_changeset(u)
  |> Repo.insert!()
end)

# Fetches inserted users
users = Repo.all(User)

# Creates 100 trips for each user
Enum.map(users, fn user ->
  trip_count = 100

  changesets =
    Enum.map(1..trip_count, fn i ->
      start_odometer = :rand.uniform(200_000)
      end_odometer = start_odometer + :rand.uniform(100)
      amount_driven = end_odometer - start_odometer

      month = :rand.uniform(12)
      day = :rand.uniform(28)

      {:ok, trip_date} = Date.new(2024, month, day)

      purpose = Enum.random(purposes)

      trip_changeset = %{
        start_odometer: start_odometer,
        end_odometer: end_odometer,
        trip_date: trip_date,
        trip_purpose: purpose,
        amount_driven: amount_driven,
        user_id: user.id
      }
    end)

  Enum.reduce(changesets, {0, Multi.new()}, fn changeset, {n, multi} ->
    {n + 1, Multi.insert(multi, n, Trip.changeset(%Trip{}, changeset))}
  end)
  |> elem(1)
  |> Multi.update(:user_trip_count, User.trip_count_changeset(user, %{trip_count: trip_count}))
  |> Repo.transaction
end)
