defmodule Astra.Search do
  alias Astra.Search.TripSearch

  def change_trip_search(%TripSearch{} = search, attrs \\ %{}) do
    TripSearch.changeset(search, attrs)
  end
end
