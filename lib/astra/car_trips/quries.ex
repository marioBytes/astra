defmodule Astra.CarTrips.Queries do
  import Ecto.Query, warn: false

  alias Astra.CarTrips.Trip

  defp base() do
    from(t in Trip)
    |> order_by([t], t.trip_date)
    |> limit(50)
  end

  def filter_by_user(user_id) do
    base() |> where([t], t.user_id == ^user_id)
  end

  def filter_by_date(query \\ base(), start_date, end_date) do
    query
    |> where([t], t.trip_date >= ^start_date)
    |> where([t], t.trip_date <= ^end_date)
  end

  def filter_by_purpose(query \\ base(), purpose) do
    query |> where([t], t.trip_purpose == ^purpose)
  end

  def filter_by_date_and_purpose(query \\ base(), start_date, end_date, purpose) do
    query
    |> filter_by_date(start_date, end_date)
    |> filter_by_purpose(purpose)
  end

  def total_miles_driven(query) do
    query |> select([t], sum(t.miles_driven))
  end
end
