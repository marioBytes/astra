defmodule Astra.CarTrips.Trip do
  use Ecto.Schema
  import Ecto.Changeset

  alias Astra.Accounts.User

  schema "trips" do
    field :start_odometer, :integer
    field :end_odometer, :integer
    field :trip_date, :date
    field :trip_purpose, :string
    field :miles_driven, :integer

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [
      :start_odometer,
      :end_odometer,
      :trip_date,
      :trip_purpose,
      :miles_driven,
      :user_id
    ])
    |> validate_required([
      :start_odometer,
      :end_odometer,
      :trip_date,
      :trip_purpose,
      :miles_driven,
      :user_id
    ])
    |> maybe_validate_start_odometer_is_less_than_end_odometer()
  end

  defp maybe_validate_start_odometer_is_less_than_end_odometer(changeset) do
    start_odometer = get_field(changeset, :start_odometer)
    end_odometer = get_field(changeset, :end_odometer)

    if is_nil(start_odometer) and is_nil(end_odometer) do
      changeset
    else
      validate_start_odometer_is_less_than_end_odometer(changeset)
    end
  end

  defp validate_start_odometer_is_less_than_end_odometer(changeset) do
    start_odometer = get_field(changeset, :start_odometer)
    end_odometer = get_field(changeset, :end_odometer)

    if start_odometer >= end_odometer do
      add_error(changeset, :end_odometer, "End Odometer cannot be less than or equal to Start Odometer")
    else
      changeset
    end
  end
end
