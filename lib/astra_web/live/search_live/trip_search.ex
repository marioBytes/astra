defmodule AstraWeb.SearchLive.TripSearch do
  use AstraWeb, :live_component

  alias Astra.Search
  alias Astra.Search.TripSearch

  import Ecto.Changeset

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-5">
      <.simple_form
        for={@trip_search_form}
        id="trip-search"
        phx-target={@myself}
        phx-change="validate"
      >
        <div class="flex flex-col gap-5">
          <div class="flex gap-4 flex-col sm:flex-row">
            <div class="w-100 sm:w-1/2">
              <.input field={@trip_search_form[:start_date]} type="date" label="Start Date" />
            </div>
            <div class="w-100 sm:w-1/2">
              <.input field={@trip_search_form[:end_date]} type="date" label="End Date" />
            </div>
          </div>
          <div>
            <.input
              field={@trip_search_form[:trip_purpose]}
              type="select"
              label="Trip Purpose"
              options={@options}
            />
          </div>
        </div>
      </.simple_form>
      <div class="flex">
        <div class="ml-auto">
          <.button_primary phx-click="search" phx-target={@myself}>Search</.button_primary>
          <.button_secondary phx-click="clear" phx-target={@myself}>Clear</.button_secondary>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{trip_search: trip_search} = assigns, socket) do
    options = [
      [key: "Select trip purpose", value: "", disabled: true, selected: true],
      [key: "Personal", value: :Personal],
      [key: "Business", value: :Business],
      [key: "Other", value: :Other]
    ]

    changeset = Search.change_trip_search(trip_search)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:options, options)
     |> assign_form(changeset)
     |> assign(:trip_search, trip_search)}
  end

  @impl true
  def handle_event("validate", %{"trip_search" => trip_search_params}, socket) do
    changeset =
      socket.assigns.trip_search
      |> Search.change_trip_search(trip_search_params)
      |> Map.put(:action, :validate)

    case apply_action(changeset, :update) do
      {:ok, trip_search} ->
        changeset = Search.change_trip_search(trip_search)

        {:noreply, socket |> assign_form(changeset) |> assign(:trip_search, trip_search)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event(
        "search",
        _value,
        %{assigns: %{trip_search: %{start_date: nil, end_date: nil, trip_purpose: nil}}} = socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", _value, socket) do
    notify_parent({:search_trips, socket.assigns.trip_search})

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "clear",
        _value,
        %{assigns: %{trip_search: %{start_date: nil, end_date: nil, trip_purpose: nil}}} = socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear", _value, %{assigns: %{trip_search: trip_search}} = socket) do
    changeset = Search.change_trip_search(%TripSearch{}, %{})

    notify_parent({:clear_trip_search, trip_search})

    {:noreply, assign_form(socket, changeset)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, changeset) do
    assign(socket, :trip_search_form, to_form(changeset))
  end
end