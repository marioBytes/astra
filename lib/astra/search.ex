defmodule Astra.Search do
  alias Astra.Search.{ItemsPerPage, TripSearch}

  def change_trip_search(%TripSearch{} = search, attrs \\ %{}) do
    TripSearch.changeset(search, attrs)
  end

  def change_items_per_page(%ItemsPerPage{} = items_per_page, attrs \\ %{}) do
    ItemsPerPage.changeset(items_per_page, attrs)
  end
end
