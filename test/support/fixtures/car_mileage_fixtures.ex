defmodule Astra.CarMileageFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Astra.CarMileage` context.
  """

  @doc """
  Generate a mileage.
  """
  def mileage_fixture(attrs \\ %{}) do
    {:ok, mileage} =
      attrs
      |> Enum.into(%{
        end_odometer: 42,
        miles_driven: 42,
        start_odometer: 42,
        trip_date: ~D[2024-06-01],
        trip_purpose: "some trip_purpose"
      })
      |> Astra.CarMileage.create_mileage()

    mileage
  end
end
