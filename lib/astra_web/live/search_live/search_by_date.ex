defmodule AstraWeb.SearchLive.SearchByDateForm do
  use AstraWeb, :live_component

  alias Astra.Search

  import Ecto.Changeset

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@search_by_date_form}
        id="date-search"
        phx-target={@myself}
        phx-change="update-date-search"
        phx-submit="clear"
      >
        <div class="flex flex-col gap-5">
          <div class="flex gap-4 flex-col sm:flex-row">
            <div class="w-100 sm:w-1/2">
              <.input field={@search_by_date_form[:start_date]} type="date" label="Start Date" />
            </div>
            <div class="w-100 sm:w-1/2">
              <.input field={@search_by_date_form[:end_date]} type="date" label="End Date" />
            </div>
          </div>
          <div class="ml-auto">
            <%= if is_nil(@search_by_date.start_date) and is_nil(@search_by_date.end_date) do %>
              <.button disabled>Clear</.button>
            <% else %>
              <.button>Clear</.button>
            <% end %>
          </div>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{search_by_date: search_by_date} = assigns, socket) do
    changeset = Search.change_search_by_date(search_by_date)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event(
        "update-date-search",
        %{"search_by_date" => search_by_date_params},
        %{assigns: %{search_by_date: search_by_date}} = socket
      ) do
    changeset =
      search_by_date
      |> Search.change_search_by_date(search_by_date_params)
      |> Map.put(:action, :validate)

    start_date_updated? = get_field(changeset, :start_date)
    end_date_updated? = get_field(changeset, :end_date)

    if changeset.valid? and not is_nil(start_date_updated?) and not is_nil(end_date_updated?) do
      {:ok, search_by_date} = apply_action(changeset, :update)

      notify_parent({:search_by_date_updated, search_by_date})
    end

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("clear", _value, %{assigns: %{search_by_date: search_by_date}} = socket) do
    changeset = Search.change_search_by_date(search_by_date, %{})

    notify_parent({:clear_search_by_date, search_by_date})

    {:noreply, assign_form(socket, changeset)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, changeset) do
    assign(socket, :search_by_date_form, to_form(changeset))
  end
end
