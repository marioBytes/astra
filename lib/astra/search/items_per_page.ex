defmodule Astra.Search.ItemsPerPage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items_per_page" do
    field :item_limit, :integer
  end

  def changeset(items_per_page, attrs) do
    items_per_page
    |> cast(attrs, [:item_limit])
  end
end
