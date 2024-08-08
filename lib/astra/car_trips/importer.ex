defmodule Astra.CarTrips.Importer do
  alias Astra.CarTrips
  alias Astra.CarTrips.Trip

  def empty_csv_data() do
    [["Start Odometer", "End Odometer", "Trip Date", "Trip Purpose", "Miles Driven"]]
    |> CSV.encode()
    |> Enum.to_list()
  end

  def preview(rows, user_id) do
    rows
    |> Enum.take(5)
    |> transform_keys()
    |> Enum.map(fn attrs ->
      %{"trip_date" => trip_date, "trip_purpose" => trip_purpose} = attrs

      string_to_date = Date.from_iso8601!(trip_date)

      updated_attrs =
        attrs
        |> Map.put("user_id", user_id)
        |> Map.replace("trip_purpose", String.to_atom(trip_purpose))
        |> Map.replace("trip_date", string_to_date)
        |> IO.inspect(label: "attrs")

      CarTrips.change_trip(%Trip{}, updated_attrs)
      |> Ecto.Changeset.apply_changes()
    end)
  end

  def imp(rows, user_id) do
    rows
    |> transform_keys()
    |> Enum.map(fn attrs ->
      updated_attrs = Map.put(attrs, :user_id, user_id)

      CarTrips.create_trip(updated_attrs)
    end)
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
end
