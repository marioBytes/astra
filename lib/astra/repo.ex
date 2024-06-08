defmodule Astra.Repo do
  use Ecto.Repo,
    otp_app: :astra,
    adapter: Ecto.Adapters.Postgres
end
