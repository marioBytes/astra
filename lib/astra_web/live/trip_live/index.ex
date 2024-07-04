defmodule AstraWeb.TripLive.Index do
  use AstraWeb, :live_view

  alias Astra.CarTrips
  alias Astra.CarTrips.Trip
  alias Astra.Search.SearchByDate

  import AstraWeb.Paginator

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

    paginator = build_paginator_attrs("init", Enum.count(trips), total_trips)

    {:ok,
     socket
     |> stream(:trips, trips)
     |> assign_trip_order_init()
     |> assign(:paginator, paginator)
     |> assign_search_by_date(%SearchByDate{})}
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

    total_trips = CarTrips.count_trips(current_user)

    paginator = build_paginator_attrs("init", Enum.count(trips), total_trips)

    {:noreply,
     socket
     |> stream(:trips, trips, reset: true)
     |> assign_trip_order_init()
     |> assign(:paginator, paginator)}
  end

  @impl true
  def handle_info(
        {AstraWeb.SearchLive.SearchByDateForm,
         {:search_by_date_updated, %{start_date: start_date, end_date: end_date} = search_by_date}},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    trips =
      CarTrips.list_trips_by_date(current_user, start_date, end_date,
        page: @page,
        per_page: @per_page,
        order: @order,
        order_by: @order_by
      )

    total_trips = CarTrips.count_trips(current_user, start_date, end_date)

    paginator = build_paginator_attrs("init", Enum.count(trips), total_trips)

    {:noreply,
     socket
     |> stream(:trips, trips, reset: true)
     |> assign_trip_order_init(%{order: "asc", order_by: @order_by})
     |> assign(paginator: paginator)
     |> assign_search_by_date(search_by_date)}
  end

  def handle_info(
        {AstraWeb.SearchLive.SearchByDateForm, {:clear_search_by_date, _}},
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

    paginator = build_paginator_attrs("init", Enum.count(trips), total_trips)

    {:noreply,
     socket
     |> stream(:trips, trips, reset: true)
     |> assign_search_by_date(%SearchByDate{})
     |> assign(:paginator, paginator)}
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
        %{
          assigns: %{
            current_user: current_user,
            order_by: old_order_by,
            order: order,
            search_by_date: search_by_date
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
      build_trip_query(current_user, search_by_date,
        page: @page,
        per_page: @per_page,
        order_by: new_order_by,
        order: new_order
      )

    total_trips =
      if is_nil(search_by_date.start_date) and is_nil(search_by_date.end_date) do
        CarTrips.count_trips(current_user)
      else
        CarTrips.count_trips(current_user, search_by_date.start_date, search_by_date.end_date)
      end

    paginator = build_paginator_attrs("init", Enum.count(trips), total_trips)

    {:noreply,
     stream(socket, :trips, trips, reset: true)
     |> assign_trip_order_init(%{order: new_order, order_by: new_order_by})
     |> assign(paginator: paginator)}
  end

  def handle_event(
        "prev-page",
        _value,
        %{
          assigns: %{
            current_user: current_user,
            order: order,
            order_by: order_by,
            page: page,
            per_page: per_page,
            paginator: paginator,
            search_by_date: search_by_date
          }
        } = socket
      ) do
    new_page = page - 1

    trips =
      build_trip_query(current_user, search_by_date,
        page: new_page,
        per_page: per_page,
        order_by: order_by,
        order: order
      )

    paginator = build_paginator_attrs("prev", new_page, Enum.count(trips), @per_page, paginator)

    {:noreply,
     stream(socket, :trips, trips, reset: true)
     |> assign(page: new_page)
     |> assign(paginator: paginator)}
  end

  def handle_event(
        "next-page",
        _value,
        %{
          assigns: %{
            current_user: current_user,
            order: order,
            order_by: order_by,
            page: page,
            per_page: per_page,
            paginator: paginator,
            search_by_date: search_by_date
          }
        } = socket
      ) do
    new_page = page + 1

    trips =
      build_trip_query(current_user, search_by_date,
        page: new_page,
        per_page: per_page,
        order_by: order_by,
        order: order
      )

    paginator = build_paginator_attrs("next", new_page, Enum.count(trips), @per_page, paginator)

    {:noreply,
     stream(socket, :trips, trips, reset: true)
     |> assign(page: new_page)
     |> assign(paginator: paginator)}
  end

  defp assign_trip_order_init(socket) do
    socket
    |> assign(:per_page, @per_page)
    |> assign(:page, @page)
    |> assign(:order, @order)
    |> assign(:order_by, @order_by)
  end

  defp assign_trip_order_init(socket, %{order_by: order_by, order: order}) do
    socket
    |> assign(:per_page, @per_page)
    |> assign(:page, @page)
    |> assign(:order, order)
    |> assign(:order_by, order_by)
  end

  defp assign_current_user(socket) do
    assign(socket, :current_user, socket.assigns.current_user)
  end

  defp assign_search_by_date(socket, search_by_date) do
    assign(socket, :search_by_date, search_by_date)
  end

  defp build_trip_query(current_user, search_by_date, criteria) do
    if is_nil(search_by_date.start_date) and is_nil(search_by_date.end_date) do
      CarTrips.list_trips(current_user, criteria)
    else
      CarTrips.list_trips_by_date(
        current_user,
        search_by_date.start_date,
        search_by_date.end_date,
        criteria
      )
    end
  end
end
