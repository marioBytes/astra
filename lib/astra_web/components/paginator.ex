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

  def build_paginator_attrs(%{
         first_item: first_item,
         last_item: last_item,
         page_item_count: page_item_count,
         total_items: total_items,
         has_prev_page?: has_prev_page?,
         has_next_page?: has_next_page?
       }) do
    %{
      first_item: first_item,
      last_item: last_item,
      page_item_count: page_item_count,
      total_items: total_items,
      has_prev_page?: has_prev_page?,
      has_next_page?: has_next_page?
    }
  end
end
