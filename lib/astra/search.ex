defmodule Astra.Search do
  alias Astra.Search.SearchByDate

  def change_search_by_date(%SearchByDate{} = search, attrs \\ %{}) do
    SearchByDate.changeset(search, attrs)
  end
end
