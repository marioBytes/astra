defmodule AstraWeb.MileageLiveTest do
  use AstraWeb.ConnCase

  import Phoenix.LiveViewTest
  import Astra.CarMileageFixtures

  @create_attrs %{start_odometer: 42, end_odometer: 42, trip_date: "2024-06-01", trip_purpose: "some trip_purpose", amount_driven: 42}
  @update_attrs %{start_odometer: 43, end_odometer: 43, trip_date: "2024-06-02", trip_purpose: "some updated trip_purpose", amount_driven: 43}
  @invalid_attrs %{start_odometer: nil, end_odometer: nil, trip_date: nil, trip_purpose: nil, amount_driven: nil}

  defp create_mileage(_) do
    mileage = mileage_fixture()
    %{mileage: mileage}
  end

  describe "Index" do
    setup [:create_mileage]

    test "lists all miles", %{conn: conn, mileage: mileage} do
      {:ok, _index_live, html} = live(conn, ~p"/trips")

      assert html =~ "Listing Miles"
      assert html =~ mileage.trip_purpose
    end

    test "saves new mileage", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/trips")

      assert index_live |> element("a", "New Mileage") |> render_click() =~
               "New Mileage"

      assert_patch(index_live, ~p"/trips/new")

      assert index_live
             |> form("#mileage-form", mileage: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#mileage-form", mileage: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/trips")

      html = render(index_live)
      assert html =~ "Mileage created successfully"
      assert html =~ "some trip_purpose"
    end

    test "updates mileage in listing", %{conn: conn, mileage: mileage} do
      {:ok, index_live, _html} = live(conn, ~p"/trips")

      assert index_live |> element("#miles-#{mileage.id} a", "Edit") |> render_click() =~
               "Edit Mileage"

      assert_patch(index_live, ~p"/trips/#{mileage}/edit")

      assert index_live
             |> form("#mileage-form", mileage: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#mileage-form", mileage: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/trips")

      html = render(index_live)
      assert html =~ "Mileage updated successfully"
      assert html =~ "some updated trip_purpose"
    end

    test "deletes mileage in listing", %{conn: conn, mileage: mileage} do
      {:ok, index_live, _html} = live(conn, ~p"/trips")

      assert index_live |> element("#miles-#{mileage.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#miles-#{mileage.id}")
    end
  end

  describe "Show" do
    setup [:create_mileage]

    test "displays mileage", %{conn: conn, mileage: mileage} do
      {:ok, _show_live, html} = live(conn, ~p"/trips/#{mileage}")

      assert html =~ "Show Mileage"
      assert html =~ mileage.trip_purpose
    end

    test "updates mileage within modal", %{conn: conn, mileage: mileage} do
      {:ok, show_live, _html} = live(conn, ~p"/trips/#{mileage}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Mileage"

      assert_patch(show_live, ~p"/trips/#{mileage}/show/edit")

      assert show_live
             |> form("#mileage-form", mileage: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#mileage-form", mileage: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/trips/#{mileage}")

      html = render(show_live)
      assert html =~ "Mileage updated successfully"
      assert html =~ "some updated trip_purpose"
    end
  end
end
