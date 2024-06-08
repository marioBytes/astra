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
        <.input
          field={@form[:start_odometer]}
          type="number"
          label="Start odometer"
        />
        <.input field={@form[:end_odometer]} type="number" label="End odometer" />
        <.input field={@form[:trip_date]} type="date" label="Trip date" />
        <.input field={@form[:trip_purpose]} type="text" label="Trip purpose" />
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
     |> assign_form(changeset)}
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
    trip_params =
      trip_params
      |> Map.put("miles_driven", calculate_miles_driven(trip_params))
      |> Map.put("user_id", socket.assigns.trip.user_id)

    save_trip(socket, socket.assigns.action, trip_params)
  end

  defp save_trip(socket, :edit, trip_params) do
    case CarTrips.update_trip(socket.assigns.trip, trip_params) do
      {:ok, trip} ->
        notify_parent({:saved, trip})

        {:noreply,
         socket
         |> put_flash(:info, "Trip updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_trip(socket, :new, trip_params) do
    case CarTrips.create_trip(trip_params) do
      {:ok, trip} ->
        notify_parent({:saved, trip})
        IO.inspect("done")

        {:noreply,
         socket
         |> put_flash(:info, "Trip created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp calculate_miles_driven(%{"start_odometer" => start_odometer,"end_odometer" => end_odometer}) do
    if String.length(start_odometer) > 0 and String.length(end_odometer) > 0 do
      total = String.to_integer(end_odometer) - String.to_integer(start_odometer)
      if total > 0 do
        total
      else
        ""
      end
    else
      ""
    end
  end
end
