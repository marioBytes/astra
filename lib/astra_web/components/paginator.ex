defmodule AstraWeb.Paginator do
  use Phoenix.Component

  import AstraWeb.CoreComponents

  def paginator(assigns) do
    ~H"""
    <div class="py-4">
      <div class="flex items-center sm:justify-between justify-end">
        <%!-- Helper text --%>
        <div class="hidden sm:block">
          <p>
            Showing <span><%= @paginator.first_item %></span>
            to <span><%= @paginator.last_item %></span>
            of <span><%= @paginator.total_items %></span>
            results
          </p>
        </div>

        <%!-- Buttons --%>
        <div class="flex gap-3">
          <div>
            <%= if @paginator.has_prev_page? do %>
              <.button phx-click="prev-page">Previous</.button>
            <% else %>
              <.button disabled>Previous</.button>
            <% end %>
          </div>
          <div>
            <%= if @paginator.has_next_page? do %>
              <.button phx-click="next-page">Next</.button>
            <% else %>
              <.button disabled>Next</.button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def build_paginator_attrs("prev", current_page, item_count, item_per_page, paginator) do
    first_item = get_first_item_num(current_page, item_per_page)
    last_item = get_last_item_num(first_item, item_count)

    %{
      first_item: first_item,
      last_item: last_item,
      page_item_count: item_count,
      total_items: paginator.total_items,
      has_prev_page?: current_page > 1,
      has_next_page?: paginator.last_item - item_count != paginator.total_items
    }
  end

  def build_paginator_attrs("next", current_page, item_count, item_per_page, paginator) do
    first_item = get_first_item_num(current_page, item_per_page)
    last_item = get_last_item_num(first_item, item_count)

    %{
      first_item: first_item,
      last_item: last_item,
      page_item_count: item_count,
      total_items: paginator.total_items,
      has_prev_page?: current_page > 1,
      has_next_page?: paginator.last_item + item_count != paginator.total_items
    }
  end

  def build_paginator_attrs("init", item_count, total_items) do
    %{
      first_item: 1,
      last_item: item_count,
      page_item_count: item_count,
      total_items: total_items,
      has_prev_page?: false,
      has_next_page?: total_items - item_count != total_items
    }
  end

  defp get_first_item_num(current_page, item_per_page), do: (current_page - 1) * item_per_page + 1
  defp get_last_item_num(first_item, item_count), do: first_item + item_count - 1
end
