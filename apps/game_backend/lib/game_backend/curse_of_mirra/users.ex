defmodule GameBackend.CurseOfMirra.Users do
  @moduledoc """
    Module to work with users logic
  """
  alias GameBackend.Units
  alias GameBackend.Repo
  alias GameBackend.Users.User
  alias GameBackend.Utils
  alias GameBackend.CurseOfMirra.Config

  @doc """
  Generates a default map with its associations for a new user

  ## Examples

      iex>create_user_params()
      %{game_id: 1, username: "some_user", ...}

  """
  def create_user_params() do
    # TODO delete the following in a future refactor -> https://github.com/lambdaclass/mirra_backend/issues/557
    level = 1
    experience = 1
    amount_of_users = Repo.aggregate(User, :count)
    username = "User_#{amount_of_users + 1}"
    ##################################################################

    units =
      Enum.reduce(Config.get_characters_config(), [], fn char_params, acc ->
        acc ++
          [
            Units.get_unit_default_values(char_params.name)
          ]
      end)
      |> mark_random_unit_as_selected()

    %{
      game_id: Utils.get_game_id(:curse_of_mirra),
      username: username,
      level: level,
      experience: experience,
      units: units,
      last_daily_quest_generation_at: NaiveDateTime.utc_now()
    }
  end

  defp mark_random_unit_as_selected(units) do
    random_index = Enum.random(0..(length(units) - 1))

    Enum.with_index(units)
    |> Enum.map(fn {unit, index} ->
      if index == random_index do
        Map.put(unit, :selected, true)
      else
        unit
      end
    end)
  end
end
