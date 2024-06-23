defmodule Astra.Authorizer do
  alias Astra.Accounts.User
  alias Astra.CarTrips.Trip

  @spec authorize(atom(), struct(), %Trip{}) :: {atom(), atom()}
  def authorize(:show, %User{} = current_user, %Trip{} = trip) do
    if current_user.id == trip.user_id do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  @spec authorize(atom(), struct(), %Trip{}) :: {atom(), atom()}
  def authorize(:update, %User{} = current_user, %Trip{} = trip) do
    if current_user.id == trip.user_id do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
