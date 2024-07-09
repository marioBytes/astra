defmodule AstraWeb.PageController do
  use AstraWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    if conn.assigns.current_user do
      conn
      |> redirect(to: "/trips")
      |> halt()
    else
      render(conn, :home, layout: false)
    end
  end
end
