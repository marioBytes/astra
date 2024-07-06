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
              <.button phx-click="prev-page" phx-target={@myself}>Previous</.button>
            <% else %>
              <.button disabled>Previous</.button>
            <% end %>
          </div>
          <div>
            <%= if @has_next_page? do %>
              <.button phx-click="next-page" phx-target={@myself}>Next</.button>
            <% else %>
              <.button disabled>Next</.button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(
        %{
          items: items,
          total_items: total_items,
          current_page: current_page,
          items_per_page: items_per_page
        } = assigns,
        socket
      ) do
    if current_page == 1 do
      {:ok,
       socket
       |> assign(assigns)
       |> assign_paginator_items("init", items, items_per_page, total_items)}
    else
      {:ok,
       socket
       |> assign(assigns)
       |> assign_paginator_items(items, total_items, current_page)}
    end
  end

  @impl true
  def handle_event(
        "prev-page",
        _value,
        %{assigns: %{items: items, total_items: total_items, current_page: current_page}} = socket
      ) do
    notify_parent({:prev_page, nil})

    {:noreply, assign_paginator_items(socket, items, total_items, current_page)}
  end

  @impl true
  def handle_event(
        "next-page",
        _value,
        %{assigns: %{items: items, total_items: total_items, current_page: current_page}} = socket
      ) do
    notify_parent({:next_page, nil})

    {:noreply, assign_paginator_items(socket, items, total_items, current_page)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_paginator_items(socket, "init", items, items_per_page, total_items) do
    item_count = Enum.count(items)

    first_item = 1
    last_item = get_last_item_num(first_item, item_count)

    assign_paginator_items(
      socket,
      first_item,
      last_item,
      total_items,
      false,
      item_count != total_items
    )
  end

  defp assign_paginator_items(socket, items, total_items, current_page) do
    item_count = Enum.count(items)

    first_item = get_first_item_num(current_page, socket.assigns.items_per_page)
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

  defp get_first_item_num(current_page, items_per_page), do: (current_page - 1) * items_per_page + 1
  defp get_last_item_num(first_item, item_count), do: first_item + item_count - 1
end
