defmodule AstraWeb.TripLive.Index do
  use AstraWeb, :live_view

  alias Astra.CarTrips
  alias Astra.CarTrips.Trip
  alias Astra.Search.TripSearch

  @page 1
  @per_page 10
  @order "desc"
  @order_by :trip_date

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    trips =
      CarTrips.list_trips(current_user,
        per_page: @per_page,
        page: @page,
        order: @order,
        order_by: @order_by
      )

    total_trips = CarTrips.count_trips(current_user)

    {:ok,
     socket
     |> stream(:trips, trips)
     |> assign_trip_order()
     |> assign(:total_trips, total_trips)
     |> assign_trip_search(%TripSearch{})
     |> assign_max_page()}
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
  def handle_info(
        {AstraWeb.TripLive.FormComponent, {:saved, _trip}},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    trips =
      CarTrips.list_trips(current_user,
        per_page: @per_page,
        page: @page,
        order: @order,
        order_by: @order_by
      )

    {:noreply,
     socket
     |> stream(:trips, trips, reset: true)
     |> assign_trip_order()
     |> assign(:total_trips, socket.assigns.total_trips + 1)
     |> assign_max_page()}
  end

  @impl true
  def handle_info(
        {AstraWeb.SearchLive.TripSearch, {:search_trips, trip_search}},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    trips =
      build_trip_query(current_user, trip_search,
        page: @page,
        per_page: @per_page,
        order: @order,
        order_by: @order_by
      )

    total_trips = build_trip_count_query(current_user, trip_search)

    {:noreply,
     socket
     |> stream(:trips, trips, reset: true)
     |> assign(:total_trips, total_trips)
     |> assign_trip_order(%{order: "asc", order_by: @order_by})
     |> assign_trip_search(trip_search)}
  end

  @impl true
  def handle_info(
        {AstraWeb.SearchLive.TripSearch, {:clear_trip_search, _}},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    trips =
      CarTrips.list_trips(current_user,
        per_page: @per_page,
        page: @page,
        order: @order,
        order_by: @order_by
      )

    total_trips = CarTrips.count_trips(current_user)

    {:noreply,
     socket
     |> stream(:trips, trips, reset: true)
     |> assign(:total_trips, total_trips)
     |> assign(:page, 1)
     |> assign_trip_search(%TripSearch{})}
  end

  @impl true
  def handle_info(
        {AstraWeb.Paginator, {:prev_page, _}},
        %{
          assigns: %{
            current_user: current_user,
            order: order,
            order_by: order_by,
            page: page,
            per_page: per_page,
            trip_search: trip_search
          }
        } = socket
      ) do
    new_page = page - 1

    trips =
      build_trip_query(current_user, trip_search,
        page: new_page,
        per_page: per_page,
        order_by: order_by,
        order: order
      )

    {:noreply,
     stream(socket, :trips, trips, reset: true)
     |> assign(page: new_page)}
  end

  @impl true
  def handle_info(
        {AstraWeb.Paginator, {:next_page, _}},
        %{
          assigns: %{
            current_user: current_user,
            order: order,
            order_by: order_by,
            page: page,
            per_page: per_page,
            trip_search: trip_search
          }
        } = socket
      ) do
    new_page = page + 1

    trips =
      build_trip_query(current_user, trip_search,
        page: new_page,
        per_page: per_page,
        order_by: order_by,
        order: order
      )

    {:noreply,
     stream(socket, :trips, trips, reset: true)
     |> assign(page: new_page)}
  end

  @impl true
  def handle_event(
        "delete",
        %{"id" => id},
        %{
          assigns: %{
            current_user: current_user,
            trip_search: trip_search,
            total_trips: total_trips,
            page: page,
            per_page: per_page,
            order: order,
            order_by: order_by
          }
        } = socket
      ) do
    trip = CarTrips.get_trip!(id)

    case CarTrips.delete_trip(current_user, trip) do
      {:ok, _} ->
        new_max_page = calc_max_page(total_trips - 1, per_page)

        new_page =
          if page > new_max_page do
            page - 1
          else
            page
          end

        trips =
          build_trip_query(current_user, trip_search,
            page: new_page,
            per_page: per_page,
            order: order,
            order_by: order_by
          )

        {:noreply,
         socket
         |> stream(:trips, trips, reset: true)
         |> assign(:total_trips, total_trips - 1)
         |> assign(:page, new_page)
         |> assign(:max_page, new_max_page)}

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

  @impl true
  def handle_event(
        "order-by",
        value,
        %{
          assigns: %{
            current_user: current_user,
            order_by: old_order_by,
            order: order,
            trip_search: trip_search
          }
        } = socket
      ) do
    new_order_by =
      value["order-column"]
      |> String.split(" ")
      |> Enum.join("_")
      |> String.downcase()
      |> String.to_atom()

    new_order =
      (fn
         new_order_by, old_order_by, "asc" when new_order_by == old_order_by ->
           "desc"

         _, _, _ ->
           "asc"
       end).(new_order_by, old_order_by, order)

    trips =
      build_trip_query(current_user, trip_search,
        page: @page,
        per_page: @per_page,
        order_by: new_order_by,
        order: new_order
      )

    {:noreply,
     stream(socket, :trips, trips, reset: true)
     |> assign_trip_order(%{order: new_order, order_by: new_order_by})}
  end

  defp assign_trip_order(socket) do
    socket
    |> assign(:per_page, @per_page)
    |> assign(:page, @page)
    |> assign(:order, @order)
    |> assign(:order_by, @order_by)
  end

  defp assign_trip_order(socket, %{order_by: order_by, order: order}) do
    socket
    |> assign(:per_page, @per_page)
    |> assign(:page, @page)
    |> assign(:order, order)
    |> assign(:order_by, order_by)
  end

  defp assign_current_user(socket) do
    assign(socket, :current_user, socket.assigns.current_user)
  end

  defp assign_trip_search(socket, trip_search) do
    assign(socket, :trip_search, trip_search)
  end

  defp build_trip_query(
         current_user,
         %{start_date: nil, end_date: nil, trip_purpose: nil},
         criteria
       ),
       do: CarTrips.list_trips(current_user, criteria)

  defp build_trip_query(
         current_user,
         %{start_date: start_date, end_date: end_date, trip_purpose: trip_purpose},
         criteria
       )
       when (is_nil(start_date) or is_nil(end_date)) and not is_nil(trip_purpose) do
    CarTrips.list_trips_by_trip_purpose(current_user, trip_purpose, criteria)
  end

  defp build_trip_query(
         current_user,
         %{start_date: start_date, end_date: end_date, trip_purpose: nil},
         criteria
       ) do
    CarTrips.list_trips_by_date(
      current_user,
      start_date,
      end_date,
      criteria
    )
  end

  defp build_trip_query(
         current_user,
         %{start_date: start_date, end_date: end_date, trip_purpose: trip_purpose},
         criteria
       ) do
    CarTrips.list_trips_by_date_and_purpose(
      current_user,
      start_date,
      end_date,
      trip_purpose,
      criteria
    )
  end

  defp build_trip_count_query(current_user, %{
         start_date: start_date,
         end_date: end_date,
         trip_purpose: trip_purpose
       })
       when (is_nil(start_date) or is_nil(end_date)) and not is_nil(trip_purpose) do
    CarTrips.count_trips(current_user, trip_purpose)
  end

  defp build_trip_count_query(current_user, %{
         start_date: start_date,
         end_date: end_date,
         trip_purpose: nil
       }) do
    CarTrips.count_trips(current_user, start_date, end_date)
  end

  defp build_trip_count_query(current_user, %{
         start_date: start_date,
         end_date: end_date,
         trip_purpose: trip_purpose
       }) do
    CarTrips.count_trips(current_user, start_date, end_date, trip_purpose)
  end

  defp assign_max_page(%{assigns: %{total_trips: total_trips, per_page: per_page}} = socket) do
    max_page = calc_max_page(total_trips, per_page)

    assign(socket, :max_page, max_page)
  end

  defp calc_max_page(total_trips, per_page) do
    {max_page, _} = Float.ceil(total_trips / per_page) |> Float.to_string() |> Integer.parse()

    max_page
  end
end
