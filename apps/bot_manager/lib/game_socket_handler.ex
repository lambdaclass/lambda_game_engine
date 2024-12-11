defmodule BotManager.GameSocketHandler do
  @moduledoc """
  BotManager socket handler.
  It handles the communication with the server.
  """

  alias BotManager.BotStateMachine
  alias BotManager.BotStateMachineChecker

  use WebSockex, restart: :temporary
  require Logger

  @decision_delay_ms 1000
  @action_delay_ms 30

  def start_link(%{"bot_client" => bot_client, "game_id" => game_id} = params) do
    ws_url = ws_url(params)

    WebSockex.start_link(ws_url, __MODULE__, %{
      client_id: bot_client,
      game_id: game_id
    })
  end

  #######################
  #      handlers       #
  #######################

  def handle_connect(_conn, state) do
    send(self(), :decide_action)
    send(self(), :perform_action)

    state =
      state
      |> Map.put(:bots_enabled?, true)
      |> Map.put(:attack_blocked, false)
      |> Map.put(:bot_state_machine, BotStateMachineChecker.new())

    {:ok, state}
  end

  def handle_frame({:binary, frame}, state) do
    case BotManager.Protobuf.GameEvent.decode(frame) do
      %{event: {:update, game_state}} ->
        bot_player = Map.get(game_state.players, state.player_id)

        update = %{
          bot_player: bot_player,
          game_state: game_state
        }

        {:ok, Map.merge(state, update)}

      %{event: {:joined, joined}} ->
        {:ok, Map.merge(state, joined)}

      %{event: {:finished, _}} ->
        exit(:shutdown)

      %{event: {:toggle_bots, _}} ->
        {:ok, Map.put(state, :bots_enabled?, not state.bots_enabled?)}

      _ ->
        {:ok, state}
    end
  end

  def handle_info(:decide_action, state) do
    Process.send_after(self(), :decide_action, @decision_delay_ms)

    %{action: action, bot_state_machine: bot_state_machine} = BotStateMachine.decide_action(state)

    state = state |> Map.put(:current_action, action) |> Map.put(:bot_state_machine, bot_state_machine)
    {:ok, state}
  end

  def handle_info(:unblock_attack, state) do
    {:ok, Map.put(state, :attack_blocked, false)}
  end

  def handle_info(:perform_action, state) do
    Process.send_after(self(), :perform_action, @action_delay_ms)
    send_current_action(state)
    {:ok, update_block_attack_state(state)}
  end

  defp update_block_attack_state(%{current_action: {:use_skill, _, _}} = state) do
    Process.send_after(self(), :unblock_attack, Enum.random(500..1000))
    Map.put(state, :attack_blocked, true)
  end

  defp update_block_attack_state(state), do: state

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    {:reply, frame, state}
  end

  defp send_current_action(%{current_action: {:move, direction}}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:move,
           %BotManager.Protobuf.Move{
             direction: %BotManager.Protobuf.Direction{
               x: direction.x,
               y: direction.y
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})
  end

  defp send_current_action(%{current_action: {:use_skill, skill_key, direction}}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:attack,
           %BotManager.Protobuf.Attack{
             skill: skill_key,
             parameters: %BotManager.Protobuf.AttackParameters{
               target: %BotManager.Protobuf.Direction{
                 x: direction.x,
                 y: direction.y
               }
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})
  end

  defp send_current_action(_), do: nil

  defp ws_url(%{
         "bot_client" => bot_client,
         "game_id" => game_id,
         "arena_host" => arena_host
       }) do
    Logger.info("Connecting bot with client: #{bot_client} to game: #{game_id} in the server: #{arena_host}")

    if arena_host == "localhost" do
      "ws://localhost:4000/play/#{game_id}/#{bot_client}"
    else
      "wss://#{arena_host}/play/#{game_id}/#{bot_client}"
    end
  end

  def terminate(close_reason, state) do
    Logger.error("Terminating bot with reason: #{inspect(close_reason)}")
    Logger.error("Terminating bot with state: #{inspect(state)}")
  end
end
