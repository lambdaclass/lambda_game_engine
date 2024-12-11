defmodule BotManager.BotStateMachine do
  @moduledoc """
  This module will take care of deciding what the bot will do on each deciding step
  """

  alias BotManager.Utils
  alias BotManager.Math.Vector
  require Logger

  @skill_1_key "1"
  @skill_2_key "2"
  @dash_skill_key "3"
  @vision_range 1500

  def decide_action(%{bots_enabled?: false}) do
    {:move, %{x: 0, y: 0}}
  end

  def decide_action(%{
        game_state: game_state,
        bot_player: bot_player,
        attack_blocked: attack_blocked,
        bot_state_machine: bot_state_machine
      }) do
    use_skill(%{
      bot_player: bot_player,
      bot_state_machine: bot_state_machine,
      game_state: game_state,
      attack_blocked: attack_blocked
    })
  end

  def decide_action(%{bot_state_machine: bot_state_machine}),
    do: %{action: :stand, bot_state_machine: bot_state_machine}

  def use_skill(%{attack_blocked: true, bot_state_machine: bot_state_machine}),
    do: %{action: {:move, create_random_direction()}, bot_state_machine: bot_state_machine}

  def use_skill(%{
        game_state: game_state,
        bot_player: bot_player,
        bot_state_machine: bot_state_machine
      }) do
    players_with_distances = map_directions_to_players(game_state, bot_player, @vision_range)

    bot_state_machine =
      if is_nil(bot_state_machine.previous_position) do
        bot_state_machine
        |> Map.put(:previous_position, bot_player.position)
        |> Map.put(:current_position, bot_player.position)
      else
        bot_state_machine
        |> Map.put(:previous_position, bot_state_machine.current_position)
        |> Map.put(:current_position, bot_player.position)
      end

    %{distance: distance} =
      get_distance_and_direction_to_positions(bot_state_machine.previous_position, bot_state_machine.current_position)

    bot_state_machine =
      Map.put(bot_state_machine, :progress_for_basic_skill, bot_state_machine.progress_for_basic_skill + distance)

    cond do
      bot_state_machine.progress_for_basic_skill >= bot_state_machine.cap_for_basic_skill ->
        bot_state_machine =
          Map.put(bot_state_machine, :progress_for_basic_skill, 0)
          |> Map.put(:progress_for_ultimate_skill, bot_state_machine.progress_for_ultimate_skill + 1)
          |> Map.put(:state, :attacking)

        %{action: {:use_skill, @skill_1_key, create_random_direction()}, bot_state_machine: bot_state_machine}

      bot_state_machine.progress_for_ultimate_skill >= bot_state_machine.cap_for_ultimate_skill ->
        bot_state_machine =
          Map.put(bot_state_machine, :progress_for_ultimate_skill, 0)
          |> Map.put(:state, :attacking)

        %{action: {:use_skill, @skill_2_key, create_random_direction()}, bot_state_machine: bot_state_machine}

      true ->
        %{action: {:move, bot_player.direction}, bot_state_machine: bot_state_machine}
    end
  end

  defp create_random_direction() do
    %{x: Enum.random(1..200) / 100 - 1, y: Enum.random(1..200) / 100 - 1}
  end

  defp map_directions_to_players(game_state, bot_player, max_distance) do
    Map.delete(game_state.players, bot_player.id)
    |> Map.filter(fn {player_id, player} ->
      Utils.player_alive?(player) && player_within_visible_players?(bot_player, player_id)
    end)
    |> Enum.map(fn {_player_id, player} ->
      player_info =
        get_distance_and_direction_to_positions(bot_player.position, player.position)

      Map.merge(player, player_info)
    end)
    |> Enum.filter(fn player_info -> player_info.distance <= max_distance end)
  end

  defp get_distance_and_direction_to_positions(base_position, base_position) do
    %{
      direction: %{x: 0, y: 0},
      distance: 0
    }
  end

  defp get_distance_and_direction_to_positions(base_position, end_position) do
    %{x: x, y: y} = Vector.sub(end_position, base_position)

    distance = :math.sqrt(:math.pow(x, 2) + :math.pow(y, 2))

    direction = %{x: x / distance, y: y / distance}

    %{
      direction: direction,
      distance: distance
    }
  end

  defp player_within_visible_players?(bot_player, player_id) do
    {:player, bot_player_info} = bot_player.aditional_info
    Enum.member?(bot_player_info.visible_players, player_id)
  end

  defp determine_player_move_action(bot_player, direction) do
    {:player, bot_player_info} = bot_player.aditional_info

    if Map.has_key?(bot_player_info.cooldowns, @dash_skill_key) do
      {:move, maybe_run_away(bot_player_info, direction)}
    else
      {:use_skill, @dash_skill_key, maybe_run_away(bot_player_info, direction)}
    end
  end

  defp maybe_run_away(bot_player_info, direction) do
    health_percentage = bot_player_info.health * 100 / bot_player_info.max_health

    if health_percentage < 30 do
      Vector.mult(direction, -1)
    else
      direction
    end
  end
end
