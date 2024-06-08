defmodule AstraWeb.TripLive.Show do
  use AstraWeb, :live_view

  alias Astra.CarTrips

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    trip = CarTrips.get_trip!(id)

    if trip.user_id == socket.assigns.current_user.id do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:trip, trip)}
    else
      {:noreply, push_navigate(socket, to: "/trips")}
    end
  end

  defp page_title(:show), do: "Show Trip"
  defp page_title(:edit), do: "Edit Trip"
end
