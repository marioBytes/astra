defmodule Astra.CarTrips do
  @moduledoc """
  The CarTrips context.
  """

  import Ecto.Query, warn: false
  alias Astra.Repo

  alias Astra.CarTrips.Trip
  alias Astra.CarTrips.Queries

  @doc """
  Returns the list of trips by user id.

  ## Examples

      iex> list_trips(1)
      [%Trip{}, ...]

  """
  def list_trips(user_id) do
    Queries.filter_by_user(user_id) |> Repo.all()
  end

  @doc """
  Returns a list of trips within a date range YYYY-MM-DD

  ## Examples

      iex> list_trips_by_date(1, ~D[2024-01-01], ~D[2024-02-28])
      [%Trip{}, ...]
  """
  def list_trips_by_date(user_id, start_date, end_date) do
    user_id
    |> Queries.filter_by_user()
    |> Queries.filter_by_date(start_date, end_date)
    |> Repo.all()
  end

  @doc """
  Returns a list of trips by trip purpose

  ## Examples

      iex> list_trips_by_purpose(1, "Business")
      [%Trip{}, ...]
  """
  def list_trips_by_purpose(user_id, purpose) do
    user_id
    |> Queries.filter_by_user()
    |> Queries.filter_by_purpose(purpose)
    |> Repo.all()
  end

  @doc """
  Returns a list of trips within a date range YYYY-MM-DD and by trip purpose

  ## Examples

      iex> list_trips_by_date_and_purpose(1, ~D[2024-01-01], ~D[2024-02-28], "Business")
      [%Trip{}, ...]
  """
  def list_trips_by_date_and_purpose(user_id, start_date, end_date, purpose) do
    user_id
    |> Queries.filter_by_user()
    |> Queries.filter_by_date_and_purpose(start_date, end_date, purpose)
    |> Repo.all()
  end

  @doc """
  Gets a single trip.

  Raises `Ecto.NoResultsError` if the Trip does not exist.

  ## Examples

      iex> get_trip!(123)
      %Trip{}

      iex> get_trip!(456)
      ** (Ecto.NoResultsError)

  """
  def get_trip!(id), do: Repo.get!(Trip, id)

  @doc """
  Creates a trip.

  ## Examples

      iex> create_trip(%{field: value})
      {:ok, %Trip{}}

      iex> create_trip(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_trip(struct()) :: {atom(), struct()}
  def create_trip(attrs \\ %{}) do
    %Trip{}
    |> Trip.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trip.

  ## Examples

      iex> update_trip(user_id, trip, %{field: new_value})
      {:ok, %Trip{}}

      iex> update_trip(user_id, trip, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_trip(integer(), %Trip{}, struct()) :: {atom(), struct()}
  def update_trip(user_id, %Trip{} = trip, attrs) do
    if trip.user_id == user_id do
      trip
      |> Trip.changeset(attrs)
      |> Repo.update()
    else
      {:error,
       change_trip_error(trip, :invalid_credentials, "You cannot update a trip that isn't yours.")}
    end
  end

  @doc """
  Deletes a trip.

  ## Examples

      iex> delete_trip(user_id, trip)
      {:ok, %Trip{}}

      iex> delete_trip(user_id, trip)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_trip(integer(), %Trip{}) :: {atom(), struct()}
  def delete_trip(user_id, %Trip{} = trip) do
    if trip.user_id == user_id do
      Repo.delete(trip)
    else
      {:error,
       change_trip_error(trip, :invalid_credentials, "You cannot update a trip that isn't yours.")}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trip changes.

  ## Examples

      iex> change_trip(trip)
      %Ecto.Changeset{data: %Trip{}}

  """
  @spec change_trip(%Trip{}, struct()) :: %Ecto.Changeset{}
  def change_trip(%Trip{} = trip, attrs \\ %{}) do
    Trip.changeset(trip, attrs)
  end

  @doc """
  Returns a `%Ecto.Changeset{}` with a custom error

  ## Examples

      iex> change_trip_error(trip, :invalid_credentials, "You cannot update a trip that isn't yours.")
      %Ecto.Changeset{errors: [invalid_credentials: {"You cannot update a trip that isn't yours.", []}]}

  """
  @spec change_trip_error(%Trip{}, atom(), String.t()) :: %Ecto.Changeset{}
  def change_trip_error(%Trip{} = trip, key, msg) do
    changeset = change_trip(trip)

    Ecto.Changeset.add_error(
      changeset,
      key,
      msg
    )
  end
end
