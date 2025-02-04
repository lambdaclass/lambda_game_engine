defmodule GameBackend.Utils do
  @moduledoc """
  Helper module
  """

  def get_game_id(:curse_of_mirra), do: 1
  def get_game_id(:champions_of_mirra), do: 2

  def get_daily_rewards_config(),
    do: Application.get_env(:game_backend, :daily_rewards_config) |> Map.get("reward_per_day")
end
