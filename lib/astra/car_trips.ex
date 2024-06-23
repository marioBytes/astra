defmodule Astra.CarTrips do
  @moduledoc """
  The CarTrips context.
  """

  import Ecto.Query, warn: false
  alias Astra.Repo

  alias Astra.Accounts.User
  alias Astra.Authorizer
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

      iex> get_trip(123)
      %Trip{}

      iex> get_trip(456)
      ** (Ecto.NoResultsError)

  """
  def get_trip!(id), do: Repo.get(Trip, id)

  def get_trip(%User{} = current_user, id) do
    trip = Repo.get(Trip, id)

    if is_nil(trip) do
      {:error, :not_found}
    else
      case Authorizer.authorize(:show, current_user, trip) do
        :ok -> {:ok, trip}
        {:error, :unauthorized} -> {:error, :unauthorized}
      end
    end
  end

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
  @spec update_trip(%User{}, %Trip{}, struct()) :: {atom(), struct()}
  def update_trip(%User{} = current_user, %Trip{} = trip, attrs) do
    case Authorizer.authorize(:update, current_user, trip) do
      :ok ->
        trip
        |> Trip.changeset(attrs)
        |> Repo.update()

      {:error, :unauthorized} ->
        {:error, :unauthorized}
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
  @spec delete_trip(%User{}, %Trip{}) :: {atom(), struct()}
  def delete_trip(%User{} = current_user, %Trip{} = trip) do
    case Authorizer.authorize(:update, current_user, trip) do
      :ok ->
        Repo.delete(trip)

      {:error, :unauthorized} ->
        {:error, :unauthorized}
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
end
