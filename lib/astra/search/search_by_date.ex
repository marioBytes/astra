defmodule Astra.Search.SearchByDate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "search_by_date" do
    field :start_date, :date
    field :end_date, :date
  end

  def changeset(search_by_date, attrs) do
    search_by_date
    |> cast(attrs, [:start_date, :end_date])
    |> maybe_validate_start_date_is_before_end_date()
  end

  defp maybe_validate_start_date_is_before_end_date(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if is_nil(start_date) or is_nil(end_date) do
      changeset
    else
      validate_start_date_is_before_end_date(changeset)
    end
  end

  defp validate_start_date_is_before_end_date(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if Date.compare(start_date, end_date) == :gt do
      add_error(changeset, :start_date, "Start date cannot be before the end date.")
    else
      changeset
    end
  end
end
