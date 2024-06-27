defmodule AstraWeb.TripLive.Index do
  use AstraWeb, :live_view

  alias Astra.CarTrips
  alias Astra.CarTrips.Trip

  @per_page 25

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    page = 1
    per_page = @per_page
    order_by = :trip_date
    order = "desc"

    {:ok,
     socket
     |> stream(
       :trips,
       CarTrips.list_trips(current_user,
         per_page: per_page,
         page: page,
         order: order,
         order_by: order_by
       )
     )
     |> assign(:per_page, per_page)
     |> assign(:page, page)
     |> assign(:order, order)
     |> assign(:order_by, order_by)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    case CarTrips.get_trip(current_user, id) do
      {:ok, trip} ->
        socket
        |> assign(:page_title, "Edit Trip")
        |> assign(:trip, trip)
        |> assign_current_user()

      {:error, :unauthorized} ->
        socket
        |> put_flash(:error, "You cannot view trips that don't belong to you.")
        |> redirect(to: "/trips")
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Trip")
    |> assign(:trip, %Trip{user_id: socket.assigns.current_user.id})
    |> assign_current_user()
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Your Trips")
    |> assign(:trip, nil)
    |> assign_current_user()
  end

  @impl true
  def handle_info({AstraWeb.TripLive.FormComponent, {:saved, mileage}}, socket) do
    {:noreply, stream_insert(socket, :trips, mileage)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    trip = CarTrips.get_trip!(id)

    case CarTrips.delete_trip(socket.assigns.current_user, trip) do
      {:ok, _} ->
        {:noreply, stream_delete(socket, :trips, trip)}

      {:error, %Ecto.Changeset{}} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong, refresh the page and try again.")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You cannot update trips that don't belong to you.")}
    end
  end

  def handle_event(
        "order-by",
        value,
        %{assigns: %{current_user: current_user, order_by: old_order_by, order: order}} = socket
      ) do
    new_order_by =
      value["order-column"]
      |> String.split(" ")
      |> Enum.join("_")
      |> String.downcase()
      |> String.to_atom()

    page = 1
    per_page = @per_page

    new_order =
      (fn
         new_order_by, old_order_by, "asc" when new_order_by == old_order_by ->
           "desc"

         _, _, _ ->
           "asc"
       end).(new_order_by, old_order_by, order)

    trips =
      CarTrips.list_trips(current_user,
        page: page,
        per_page: per_page,
        order_by: new_order_by,
        order: order
      )

    {:noreply,
     stream(socket, :trips, trips, reset: true)
     |> assign(page: page)
     |> assign(per_page: per_page)
     |> assign(order_by: new_order_by)
     |> assign(order: new_order)}
  end

  defp assign_current_user(socket) do
    assign(socket, :current_user, socket.assigns.current_user)
  end
end
