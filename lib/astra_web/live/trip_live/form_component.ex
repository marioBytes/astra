defmodule AstraWeb.TripLive.FormComponent do
  use AstraWeb, :live_component

  alias Astra.CarTrips

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage trip records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="trip-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:start_odometer]} type="number" label="Start odometer" />
        <.input field={@form[:end_odometer]} type="number" label="End odometer" />
        <.input field={@form[:trip_date]} type="date" label="Trip date" />
        <.input
          field={@form[:trip_purpose]}
          type="select"
          label="Trip purpose"
          options={@options}
          value={@default_value}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Trip</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{trip: trip} = assigns, socket) do
    changeset = CarTrips.change_trip(trip)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign_options()
     |> assign_default_option(changeset)
     |> assign(current_user: assigns.current_user)}
  end

  @impl true
  def handle_event("validate", %{"trip" => trip_params}, socket) do
    changeset =
      socket.assigns.trip
      |> CarTrips.change_trip(trip_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"trip" => trip_params}, socket) do
    trip_params = maybe_calculate_miles_driven(socket.assigns.trip, trip_params)

    save_trip(socket, socket.assigns.action, trip_params)
  end

  defp save_trip(
         %{assigns: %{current_user: current_user, trip: trip}} = socket,
         :edit,
         trip_params
       ) do
    case CarTrips.update_trip(current_user, trip, trip_params) do
      {:ok, trip} ->
        notify_parent({:saved, trip})

        {:noreply,
         socket
         |> put_flash(:info, "Trip updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You cannot update trips that don't belong to you.")
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp save_trip(socket, :new, trip_params) do
    trip_params = Map.put(trip_params, "user_id", socket.assigns.current_user.id)

    case CarTrips.create_trip(trip_params) do
      {:ok, trip} ->
        notify_parent({:saved, trip})

        {:noreply,
         socket
         |> put_flash(:info, "Trip created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_options(socket),
    do: socket |> assign(:options, Personal: :Personal, Business: :Business, Other: :Other)

  defp assign_default_option(socket, %{data: %{trip_purpose: purpose}}),
    do: assign(socket, :default_value, purpose)

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp maybe_calculate_miles_driven(
         trip,
         %{"start_odometer" => start_odometer, "end_odometer" => end_odometer} = trip_params
       ) do
    if trip.start_odometer == start_odometer and trip.end_odometer == end_odometer do
      trip_params
    else
      Map.put(trip_params, "miles_driven", calculate_miles_driven(trip_params))
    end
  end

  defp calculate_miles_driven(%{
         "start_odometer" => start_odometer,
         "end_odometer" => end_odometer
       }) do
    if String.length(start_odometer) > 0 and String.length(end_odometer) > 0 do
      {start_odometer, _} = Integer.parse(start_odometer)
      {end_odometer, _} = Integer.parse(end_odometer)

      total = end_odometer - start_odometer

      if total > 0, do: total, else: 0
    else
      0
    end
  end
end
