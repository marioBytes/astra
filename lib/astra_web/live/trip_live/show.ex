defmodule AstraWeb.TripLive.Show do
  use AstraWeb, :live_view

  alias Astra.CarTrips

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, %{assigns: %{current_user: current_user}} = socket) do
    case CarTrips.get_trip(current_user, id) do
      {:ok, trip} ->
        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:trip, trip)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You cannot view trips that don't belong to you.")
         |> push_navigate(to: "/trips")}
    end
  end

  defp page_title(:show), do: "Show Trip"
  defp page_title(:edit), do: "Edit Trip"
end
