defmodule Astra.CarTrips.Importer do
  alias Astra.Accounts
  alias Astra.Accounts.User
  alias Astra.CarTrips
  alias Astra.CarTrips.Trip
  alias Astra.Repo

  def empty_csv_data() do
    [["Start Odometer", "End Odometer", "Trip Date", "Trip Purpose", "Miles Driven"]]
    |> CSV.encode()
    |> Enum.to_list()
  end

  def preview(rows, user_id) do
    rows
    |> Enum.take(5)
    |> transform_keys()
    |> Enum.map(fn %{"trip_date" => trip_date, "trip_purpose" => trip_purpose} = attrs ->
      transformed_trip_date = date_from_string(trip_date)
      transformed_trip_purpose = trip_purpose |> String.capitalize() |> String.to_atom()

      updated_attrs =
        attrs
        |> Map.put("user_id", user_id)
        |> Map.replace("trip_purpose", transformed_trip_purpose)
        |> Map.replace("trip_date", transformed_trip_date)

      CarTrips.change_trip(%Trip{}, updated_attrs)
      |> Ecto.Changeset.change()
    end)
    |> Enum.split_with(fn row -> row.valid? end)
  end

  def import(rows, user_id) do
    rows =
      rows
      |> Enum.take(5)
      |> transform_keys()
      |> Enum.map(fn %{"trip_purpose" => trip_purpose} = row ->
        changeset =
          row
          |> Map.put("user_id", user_id)
          |> Map.replace("trip_purpose", String.to_atom(trip_purpose))

        CarTrips.change_trip(%Trip{}, changeset)
        |> Repo.insert()
      end)

    {successful_inserts, failed_inserts} =
      Enum.split_with(rows, fn {key, _val} -> key == :ok end)

    successful_inserts = Enum.map(successful_inserts, fn {_key, val} -> val end)
    failed_inserts = Enum.map(failed_inserts, fn {_key, val} -> val end)

    user = Accounts.get_user!(user_id)

    user
    |> User.trip_count_changeset(%{trip_count: user.trip_count + Enum.count(successful_inserts)})
    |> Repo.update!()

    {rows, successful_inserts, failed_inserts}
  end

  defp transform_keys(rows) do
    rows
    |> Enum.map(fn row ->
      Enum.reduce(row, %{}, fn {key, val}, map ->
        Map.put(map, underscore_key(key), val)
      end)
    end)
  end

  defp underscore_key(key) do
    key
    |> String.replace(" ", "")
    |> Phoenix.Naming.underscore()
  end

  defp date_from_string(string) do
    case Date.from_iso8601(string) do
      {:ok, date} -> date
      {:error, _error_message} -> string
    end
  end
end
