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
  def handle_event("validate", _value, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("parse", _value, socket) do
    parsed_rows = parse_csv(socket) |> IO.inspect(label: "parsed_rows")

    {:noreply,
     socket
     |> assign(:parsed_rows, parsed_rows)
     |> assign(:sample_trips, Importer.preview(parsed_rows, socket.assigns.current_user.id))
     |> assign(:uploaded_files, [])}
  end

  @impl true
  def handle_event("import", _value, socket) do
    imported_trips = Importer.imp(socket.assigns.parsed_rows, socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(:sample_trips, [])
     |> assign(:imported_trips, imported_trips)}
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
     |> assign(:sample_trips, [])
     |> assign(:uploaded_files, [])
  end
end
