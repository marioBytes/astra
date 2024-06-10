defmodule AstraWeb.TripLive.Index do
  use AstraWeb, :live_view

  alias Astra.CarTrips
  alias Astra.CarTrips.Trip

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :trips, CarTrips.list_trips(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    trip = CarTrips.get_trip!(id)
    current_user = socket.assigns.current_user

    if current_user.id == trip.user_id do
      socket
      |> assign(:page_title, "Edit Trip")
      |> assign(:trip, trip)
      |> assign(:user_id, current_user.id)
    else
      socket
      |> assign(:page_title, "Edit Trip")
      |> assign(:trip, %Trip{})
      |> assign(:error, "You cannot edit trips that do not belong to you")
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Trip")
    |> assign(:trip, %Trip{user_id: socket.assigns.current_user.id})
    |> assign(:user_id, socket.assigns.current_user.id)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Your Trips")
    |> assign(:trip, nil)
    |> assign(:user_id, socket.assigns.current_user.id)
  end

  @impl true
  def handle_info({AstraWeb.TripLive.FormComponent, {:saved, mileage}}, socket) do
    {:noreply, stream_insert(socket, :trips, mileage)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    trip = CarTrips.get_trip!(id)
    {:ok, _} = CarTrips.delete_trip(trip)

    {:noreply, stream_delete(socket, :trips, trip)}
  end
end
