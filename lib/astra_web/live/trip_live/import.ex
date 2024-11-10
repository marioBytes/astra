defmodule AstraWeb.TripLive.Import do
  use AstraWeb, :live_view

  alias Astra.CarTrips.Importer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_defaults()
     |> assign(:page_title, "Import Your Trips")
     |> allow_upload(:sample_csv, accept: ~w(.csv), max_entries: 1)}
  end

  @impl true
  def handle_event("reset", _value, socket) do
    {:noreply, assign_defaults(socket)}
  end

  @impl true
  def handle_event("validate", _value, %{assigns: %{uploads: uploads}} = socket) do
    csv_errors = uploads.sample_csv.errors

    if csv_errors != [] do
      error =
        Enum.map(csv_errors, fn {_, error} ->
          case error do
            :not_accepted -> "The only accepted file type is .CSV."
            :too_large -> "File is too large."
            :too_many_files -> "Only one file upload is allowed at a time."
            _ -> "Something went wrong, please reload and upload another file"
          end
        end)

      {:noreply, socket |> assign(:error, error)}
    else
      {:noreply, socket |> assign(:error, nil)}
    end
  end

  @impl true
  def handle_event("parse", _value, %{assigns: %{current_user: current_user}} = socket) do
    parsed_rows = parse_csv(socket)
    {valid_sample_trips, invalid_sample_trips} = Importer.preview(parsed_rows, current_user.id)
    valid_sample_trips_count = Enum.count(valid_sample_trips)
    total_sample_trips_count = valid_sample_trips_count + Enum.count(invalid_sample_trips)

    {:noreply,
     socket
     |> assign(:parsed_rows, parsed_rows)
     |> assign(:valid_sample_trips, valid_sample_trips)
     |> assign(:invalid_sample_trips, invalid_sample_trips)
     |> assign(:valid_sample_trips_count, valid_sample_trips_count)
     |> assign(:total_sample_trips_count, total_sample_trips_count)
     |> assign(:uploaded_files, [])}
  end

  @impl true
  def handle_event(
        "import",
        _value,
        %{assigns: %{parsed_rows: parsed_rows, current_user: current_user}} = socket
      ) do
    {imported_trips, successful_inserts, failed_inserts} = Importer.import(parsed_rows, current_user.id)

    {:noreply,
     socket
     |> assign(:valid_sample_trips, [])
     |> assign(:invalid_sample_trips, [])
     |> assign(:imported_trips, imported_trips)
     |> assign(:imported_trips_count, Enum.count(successful_inserts))
     |> assign(:failed_imported_trips, failed_inserts)}
  end

  @impl true
  def handle_event("order-by", _value, socket) do
    {:noreply, socket}
  end

  defp parse_csv(socket) do
    Phoenix.LiveView.consume_uploaded_entries(socket, :sample_csv, fn %{path: path}, _entry ->
      rows =
        path
        |> File.stream!()
        |> CSV.decode!(headers: true)
        |> Enum.to_list()

      {:ok, rows}
    end)
    |> List.flatten()
  end

  defp assign_defaults(socket) do
    socket
    |> assign(:parsed_rows, [])
    |> assign(:imported_trips, [])
    |> assign(:imported_trips_count, 0)
    |> assign(:successfully_imported_trips, 0)
    |> assign(:failed_imported_trips, 0)
    |> assign(:valid_sample_trips, [])
    |> assign(:invalid_sample_trips, [])
    |> assign(:valid_sample_trips_count, 0)
    |> assign(:total_sample_trips_count, 0)
    |> assign(:uploaded_files, [])
    |> assign(:error, nil)
  end
end
