defmodule Arena.Game.Item do
  @moduledoc """
  Module to handle items logic
  """

  alias Arena.Entities

  @doc """
  Apply all item mechanics to an entity
  """
  def do_mechanics(game_state, entity, mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, entity, mechanic)
    end)
  end

  @doc """
  Apply an item mechanic to an entity, depending on the mechanic type.
  """
  def do_mechanic(game_state, entity, {:spawn_bomb, bomb_params}) do
    last_id = game_state.last_id + 1
    new_trap =
      Entities.new_trap(last_id, entity.id, entity.position, bomb_params)

    game_state
    |> put_in([:last_id], last_id)
    |> put_in([:traps, new_trap.id], new_trap)
  end
end
