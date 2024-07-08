defmodule AstraWeb.Paginator do
  use AstraWeb, :live_component

  import AstraWeb.CoreComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-4">
      <div class="flex items-center sm:justify-between justify-end">
        <%!-- Helper text --%>
        <div class="hidden sm:block">
          <p>
            Showing <span class="font-bold"><%= @first_item %></span>
            to <span class="font-bold"><%= @last_item %></span>
            of <span class="font-bold"><%= @total_items %></span>
            results
          </p>
        </div>

        <%!-- Buttons --%>
        <div class="flex gap-3">
          <div>
            <%= if @has_prev_page? do %>
              <.button_primary phx-click="prev-page" phx-target={@myself}>Previous</.button_primary>
            <% else %>
              <.button_primary disabled>Previous</.button_primary>
            <% end %>
          </div>
          <div>
            <%= if @has_next_page? do %>
              <.button_primary phx-click="next-page" phx-target={@myself}>Next</.button_primary>
            <% else %>
              <.button_primary disabled>Next</.button_primary>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_paginator_items()}
  end

  @impl true
  def handle_event("prev-page", _value, socket) do
    notify_parent({:prev_page, nil})

    {:noreply, assign_paginator_items(socket)}
  end

  @impl true
  def handle_event("next-page", _value, socket) do
    notify_parent({:next_page, nil})

    {:noreply, assign_paginator_items(socket)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_paginator_items(
         %{
           assigns: %{
             current_page: current_page,
             items: items,
             items_per_page: items_per_page,
             total_items: total_items
           }
         } = socket
       ) do
    item_count = Enum.count(items)

    first_item = get_first_item_num(current_page, items_per_page)
    last_item = get_last_item_num(first_item, item_count)

    has_prev_page? = current_page > 1
    has_next_page? = last_item != total_items

    assign_paginator_items(
      socket,
      first_item,
      last_item,
      total_items,
      has_prev_page?,
      has_next_page?
    )
  end

  defp assign_paginator_items(
         socket,
         first_item,
         last_item,
         total_items,
         has_prev_page?,
         has_next_page?
       ) do
    socket
    |> assign(:first_item, first_item)
    |> assign(:last_item, last_item)
    |> assign(:total_items, total_items)
    |> assign(:has_prev_page?, has_prev_page?)
    |> assign(:has_next_page?, has_next_page?)
  end

  defp get_first_item_num(current_page, items_per_page),
    do: (current_page - 1) * items_per_page + 1

  defp get_last_item_num(first_item, item_count), do: first_item + item_count - 1
end
