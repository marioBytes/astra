defmodule Astra.CarMileageTest do
  use Astra.DataCase

  alias Astra.CarMileage

  describe "miles" do
    alias Astra.CarMileage.Mileage

    import Astra.CarMileageFixtures

    @invalid_attrs %{start_odometer: nil, end_odometer: nil, trip_date: nil, trip_purpose: nil, amount_driven: nil}

    test "list_miles/0 returns all miles" do
      mileage = mileage_fixture()
      assert CarMileage.list_miles() == [mileage]
    end

    test "get_mileage!/1 returns the mileage with given id" do
      mileage = mileage_fixture()
      assert CarMileage.get_mileage!(mileage.id) == mileage
    end

    test "create_mileage/1 with valid data creates a mileage" do
      valid_attrs = %{start_odometer: 42, end_odometer: 42, trip_date: ~D[2024-06-01], trip_purpose: "some trip_purpose", amount_driven: 42}

      assert {:ok, %Mileage{} = mileage} = CarMileage.create_mileage(valid_attrs)
      assert mileage.start_odometer == 42
      assert mileage.end_odometer == 42
      assert mileage.trip_date == ~D[2024-06-01]
      assert mileage.trip_purpose == "some trip_purpose"
      assert mileage.amount_driven == 42
    end

    test "create_mileage/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CarMileage.create_mileage(@invalid_attrs)
    end

    test "update_mileage/2 with valid data updates the mileage" do
      mileage = mileage_fixture()
      update_attrs = %{start_odometer: 43, end_odometer: 43, trip_date: ~D[2024-06-02], trip_purpose: "some updated trip_purpose", amount_driven: 43}

      assert {:ok, %Mileage{} = mileage} = CarMileage.update_mileage(mileage, update_attrs)
      assert mileage.start_odometer == 43
      assert mileage.end_odometer == 43
      assert mileage.trip_date == ~D[2024-06-02]
      assert mileage.trip_purpose == "some updated trip_purpose"
      assert mileage.amount_driven == 43
    end

    test "update_mileage/2 with invalid data returns error changeset" do
      mileage = mileage_fixture()
      assert {:error, %Ecto.Changeset{}} = CarMileage.update_mileage(mileage, @invalid_attrs)
      assert mileage == CarMileage.get_mileage!(mileage.id)
    end

    test "delete_mileage/1 deletes the mileage" do
      mileage = mileage_fixture()
      assert {:ok, %Mileage{}} = CarMileage.delete_mileage(mileage)
      assert_raise Ecto.NoResultsError, fn -> CarMileage.get_mileage!(mileage.id) end
    end

    test "change_mileage/1 returns a mileage changeset" do
      mileage = mileage_fixture()
      assert %Ecto.Changeset{} = CarMileage.change_mileage(mileage)
    end
  end
end
