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
          <%= if @disable_buttons do %>
            <.button_primary disabled>Search</.button_primary>
          <% else %>
            <.button_primary phx-click="search" phx-target={@myself}>Search</.button_primary>
          <% end %>
          <.button_secondary phx-click="reset" phx-target={@myself}>Reset</.button_secondary>
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
     |> assign_disable_buttons()
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
        {:noreply,
         socket
         |> assign_form(changeset)
         |> assign(:trip_search, trip_search)
         |> assign_disable_buttons()}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign_form(changeset)
         |> assign(:disable_buttons, true)}
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
        "reset",
        _value,
        %{assigns: %{trip_search: %{start_date: nil, end_date: nil, trip_purpose: nil}}} = socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _value, socket) do
    changeset = Search.change_trip_search(%TripSearch{}, %{})

    notify_parent({:reset_trip_search, nil})

    {:noreply, assign_form(socket, changeset)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, changeset) do
    assign(socket, :trip_search_form, to_form(changeset))
  end

  defp assign_disable_buttons(
         %{assigns: %{trip_search: %{start_date: nil, end_date: nil, trip_purpose: nil}}} = socket
       ) do
    assign(socket, :disable_buttons, true)
  end

  defp assign_disable_buttons(
         %{
           assigns: %{
             trip_search: %{start_date: start_date, end_date: end_date, trip_purpose: nil}
           }
         } = socket
       )
       when (is_nil(start_date) and not is_nil(end_date)) or
              (not is_nil(start_date) and is_nil(end_date)) do
    assign(socket, :disable_buttons, true)
  end

  defp assign_disable_buttons(
         %{
           assigns: %{
             trip_search: %{start_date: nil, end_date: nil, trip_purpose: trip_purpose}
           }
         } = socket
       )
       when not is_nil(trip_purpose) do
    assign(socket, :disable_buttons, false)
  end

  defp assign_disable_buttons(socket) do
    assign(socket, :disable_buttons, false)
  end
end
