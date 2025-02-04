defmodule Arena.Game.Skill do
  @moduledoc """
  Module for handling skills
  """
  alias Arena.Game.Effect
  alias Arena.{Entities, Utils}
  alias Arena.Game.{Player, Crate}

  def do_mechanic(game_state, _entity, nil, _skill_params) do
    game_state
  end

  def do_mechanic(game_state, entity, mechanics, skill_params) when is_list(mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, entity, mechanic, skill_params)
    end)
  end

  def do_mechanic(game_state, entity, mechanic, skill_params) do
    if entity.category == :player and not Player.alive?(entity) do
      game_state
    else
      execute_mechanic(game_state, entity, mechanic, skill_params)
    end
  end

  defp execute_mechanic(
         game_state,
         entity,
         %{type: "circle_hit"} = circle_hit,
         %{skill_direction: skill_direction} = _skill_params
       ) do
    circle_center_position = get_position_with_offset(entity.position, skill_direction, circle_hit.offset)
    circular_damage_area = Entities.make_circular_area(entity.id, circle_center_position, circle_hit.range)

    entity_player_owner = get_entity_player_owner(game_state, entity)

    apply_damage_and_effects_to_entities(
      game_state,
      entity_player_owner,
      circular_damage_area,
      circle_hit.damage,
      circle_hit.effect
    )
    |> maybe_move_player(entity, circle_hit[:move_by])
  end

  defp execute_mechanic(
         game_state,
         entity,
         %{type: "circle_hit"} = circle_hit,
         _skill_params
       ) do
    circle_center_position = get_position_with_offset(entity.position, nil, circle_hit.offset)
    circular_damage_area = Entities.make_circular_area(entity.id, circle_center_position, circle_hit.range)

    entity_player_owner = get_entity_player_owner(game_state, entity)

    apply_damage_and_effects_to_entities(
      game_state,
      entity_player_owner,
      circular_damage_area,
      circle_hit.damage,
      circle_hit.effect
    )
    |> maybe_move_player(entity, circle_hit[:move_by])
  end

  defp execute_mechanic(
         game_state,
         entity,
         %{type: "cone_hit"} = cone_hit,
         %{skill_direction: skill_direction} = _skill_params
       ) do
    triangle_points =
      Physics.calculate_triangle_vertices(
        entity.position,
        skill_direction,
        cone_hit.range,
        cone_hit.angle
      )

    cone_area = Entities.make_polygon(entity.id, triangle_points)
    entity_player_owner = get_entity_player_owner(game_state, entity)

    apply_damage_and_effects_to_entities(game_state, entity_player_owner, cone_area, cone_hit.damage)
    |> maybe_move_player(entity, cone_hit[:move_by])
  end

  defp execute_mechanic(game_state, entity, %{type: "multi_cone_hit"} = multi_cone_hit, skill_params) do
    Enum.each(1..(multi_cone_hit.amount - 1), fn i ->
      mechanic = %{multi_cone_hit | type: "cone_hit"}

      Process.send_after(
        self(),
        {:trigger_mechanic, entity.id, mechanic, skill_params},
        i * multi_cone_hit.interval_ms
      )
    end)

    execute_mechanic(game_state, entity, %{multi_cone_hit | type: "cone_hit"}, skill_params)
  end

  defp execute_mechanic(game_state, entity, %{type: "multi_circle_hit", amount: nil} = multi_circle_hit, skill_params) do
    amount = div(multi_circle_hit.duration_ms, multi_circle_hit.interval_ms)
    execute_mechanic(game_state, entity, Map.put(multi_circle_hit, :amount, amount), skill_params)
  end

  defp execute_mechanic(game_state, entity, %{type: "multi_circle_hit"} = multi_circle_hit, skill_params) do
    Enum.each(1..(multi_circle_hit.amount - 1), fn i ->
      mechanic = %{multi_circle_hit | type: "circle_hit"}

      Process.send_after(
        self(),
        {:trigger_mechanic, entity.id, mechanic, skill_params},
        i * multi_circle_hit.interval_ms
      )
    end)

    execute_mechanic(game_state, entity, %{multi_circle_hit | type: "circle_hit"}, skill_params)
  end

  defp execute_mechanic(
         game_state,
         entity,
         %{type: "dash", speed: speed, duration_ms: duration_ms},
         %{skill_direction: skill_direction} = _skill_params
       ) do
    Process.send_after(self(), {:stop_dash, entity.id, entity.aditional_info.base_speed}, duration_ms)

    ## Modifying base_speed rather than speed because effects will reset the speed on game tick
    ## by modifying base_speed we ensure that the dash speed is kept as expected
    entity =
      entity
      |> Map.put(:is_moving, true)
      |> put_in([:aditional_info, :base_speed], speed)
      |> put_in([:aditional_info, :direction], skill_direction)
      |> put_in([:aditional_info, :forced_movement], true)

    players = Map.put(game_state.players, entity.id, entity)

    %{game_state | players: players}
  end

  defp execute_mechanic(game_state, entity, %{type: "repeated_shot"} = repeated_shot, skill_params) do
    remaining_amount = repeated_shot.amount - 1

    if remaining_amount > 0 do
      repeated_shot = Map.put(repeated_shot, :amount, remaining_amount)

      Process.send_after(
        self(),
        {:trigger_mechanic, entity.id, repeated_shot, skill_params},
        repeated_shot.interval_ms
      )
    end

    entity_player_owner = get_entity_player_owner(game_state, entity)

    last_id = game_state.last_id + 1

    projectile =
      Entities.new_projectile(%{
        id: last_id,
        owner: entity_player_owner,
        position:
          get_position_with_offset(
            entity_player_owner.position,
            entity_player_owner.direction,
            repeated_shot.projectile_offset
          ),
        direction: randomize_direction_in_angle(entity.direction, repeated_shot.angle),
        skill_key: skill_params.skill_key,
        config_params: repeated_shot
      })

    Process.send_after(self(), {:remove_projectile, projectile.id}, repeated_shot.duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  defp execute_mechanic(
         game_state,
         entity,
         %{type: "multi_shoot"} = multishot,
         %{skill_direction: skill_direction} = skill_params
       ) do
    entity_player_owner = get_entity_player_owner(game_state, entity)

    calculate_angle_directions(multishot.amount, multishot.angle_between, skill_direction)
    |> Enum.reduce(game_state, fn direction, game_state_acc ->
      last_id = game_state_acc.last_id + 1

      projectile =
        Entities.new_projectile(%{
          id: last_id,
          owner: entity_player_owner,
          position:
            get_position_with_offset(
              entity_player_owner.position,
              skill_direction,
              multishot.projectile_offset
            ),
          direction: direction,
          skill_key: skill_params.skill_key,
          config_params: multishot
        })

      Process.send_after(self(), {:remove_projectile, projectile.id}, multishot.duration_ms)

      game_state_acc
      |> Map.put(:last_id, last_id)
      |> put_in([:projectiles, projectile.id], projectile)
    end)
  end

  defp execute_mechanic(
         game_state,
         entity,
         %{type: "simple_shoot"} = simple_shoot,
         %{skill_direction: skill_direction, can_pick_destination: true} = skill_params
       ) do
    last_id = game_state.last_id + 1
    entity_player_owner = get_entity_player_owner(game_state, entity)

    direction = maybe_multiply_by_range(skill_direction, skill_params.auto_aim?, simple_shoot.range)

    target_position = %{
      x: entity.position.x + direction.x,
      y: entity.position.y + direction.y
    }

    direction =
      Utils.normalize(%{
        x: target_position.x - entity.position.x,
        y: target_position.y - entity.position.y
      })

    duration_ms = Physics.calculate_duration(entity.position, target_position, simple_shoot.speed, simple_shoot.range)

    projectile =
      Entities.new_projectile(%{
        id: last_id,
        owner: entity_player_owner,
        position:
          get_position_with_offset(
            entity_player_owner.position,
            direction,
            simple_shoot.projectile_offset
          ),
        direction: direction,
        skill_key: skill_params.skill_key,
        config_params: simple_shoot
      })

    Process.send_after(self(), {:remove_projectile, projectile.id}, duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  defp execute_mechanic(
         game_state,
         entity,
         %{type: "simple_shoot"} = simple_shoot,
         %{skill_direction: skill_direction} = skill_params
       ) do
    last_id = game_state.last_id + 1
    entity_player_owner = get_entity_player_owner(game_state, entity)

    projectile =
      Entities.new_projectile(%{
        id: last_id,
        owner: entity_player_owner,
        position:
          get_position_with_offset(
            entity_player_owner.position,
            skill_direction,
            simple_shoot.projectile_offset
          ),
        direction: skill_direction,
        skill_key: skill_params.skill_key,
        config_params: simple_shoot
      })

    Process.send_after(self(), {:remove_projectile, projectile.id}, simple_shoot.duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  defp execute_mechanic(game_state, entity, %{type: "leap"} = leap, %{execution_duration: execution_duration}) do
    Process.send_after(
      self(),
      {:stop_leap, entity.id, entity.aditional_info.base_speed, leap.on_arrival_mechanic},
      execution_duration
    )

    ## Modifying base_speed rather than speed because effects will reset the speed on game tick
    ## by modifying base_speed we ensure that the dash speed is kept as expected cause when the
    ## stat effects are reapplied there is a check on speed effects to prevent adding if `forced_movement = true`
    player =
      entity
      |> Map.put(:is_moving, true)
      |> put_in([:aditional_info, :base_speed], leap.speed)
      |> put_in([:aditional_info, :forced_movement], true)

    put_in(game_state, [:players, player.id], player)
  end

  defp execute_mechanic(game_state, entity, %{type: "teleport"}, %{skill_destination: skill_destination}) do
    entity =
      entity
      |> Map.put(:aditional_info, entity.aditional_info)
      |> Map.put(:position, skill_destination)

    put_in(game_state, [:players, entity.id], entity)
  end

  defp execute_mechanic(
         game_state,
         %{category: :projectile} = entity,
         %{type: "spawn_pool"} = pool_params,
         skill_params
       ) do
    last_id = game_state.last_id + 1
    entity_player_owner = get_entity_player_owner(game_state, entity)

    skill_direction = maybe_multiply_by_range(skill_params.skill_direction, skill_params.auto_aim?, pool_params.range)

    target_position = %{
      x: entity.position.x + skill_direction.x,
      y: entity.position.y + skill_direction.y
    }

    Process.send_after(self(), {:activate_pool, last_id}, pool_params.activation_delay)

    pool_params =
      Map.merge(
        %{
          id: last_id,
          owner: entity_player_owner,
          position: target_position,
          skill_key: entity.aditional_info.skill_key,
          status: :WAITING
        },
        pool_params
      )

    pool =
      Entities.new_pool(pool_params)

    put_in(game_state, [:pools, last_id], pool)
    |> put_in([:last_id], last_id)
  end

  defp execute_mechanic(game_state, player, %{type: "spawn_pool"} = pool_params, skill_params) do
    last_id = game_state.last_id + 1
    entity_player_owner = get_entity_player_owner(game_state, player)

    skill_direction = maybe_multiply_by_range(skill_params.skill_direction, skill_params.auto_aim?, pool_params.range)

    target_position = %{
      x: player.position.x + skill_direction.x,
      y: player.position.y + skill_direction.y
    }

    Process.send_after(self(), {:activate_pool, last_id}, pool_params.activation_delay)

    pool_params =
      Map.merge(
        %{
          id: last_id,
          owner: entity_player_owner,
          position: target_position,
          skill_key: skill_params.skill_key,
          status: :WAITING
        },
        pool_params
      )

    pool =
      Entities.new_pool(pool_params)

    put_in(game_state, [:pools, last_id], pool)
    |> put_in([:last_id], last_id)
  end

  defp execute_mechanic(game_state, entity, {:polygon_hit, polygon_hit}, _skill_params) do
    polygon_damage_area = Entities.make_polygon_area(entity.id, polygon_hit.vertices)

    entity_player_owner = get_entity_player_owner(game_state, entity)

    apply_damage_and_effects_to_entities(game_state, entity_player_owner, polygon_damage_area, polygon_hit.damage)
  end

  def handle_on_owner_effect(game_state, player, skill) do
    Effect.put_effect_to_entity(game_state, player, player.id, skill.execution_duration_ms, skill.on_owner_effect)
  end

  defp calculate_angle_directions(amount, angle_between, base_direction) do
    base_direction_normalized = Utils.normalize(base_direction)
    middle = if rem(amount, 2) == 1, do: [base_direction_normalized], else: []
    side_amount = div(amount, 2)
    angles = Enum.map(1..side_amount, fn i -> angle_between * i end)

    {add_side, sub_side} =
      Enum.reduce(angles, {[], []}, fn angle, {add_side_acc, sub_side_acc} ->
        add_side_acc = [
          Physics.add_angle_to_direction(base_direction_normalized, angle) | add_side_acc
        ]

        sub_side_acc = [
          Physics.add_angle_to_direction(base_direction_normalized, -angle) | sub_side_acc
        ]

        {add_side_acc, sub_side_acc}
      end)

    Enum.concat([add_side, middle, sub_side])
  end

  defp get_position_with_offset(position, nil, offset) do
    real_position_x = position.x + offset
    real_position_y = position.y + offset

    %{x: real_position_x, y: real_position_y}
  end

  defp get_position_with_offset(position, direction, offset) do
    real_position_x = position.x + offset * direction.x
    real_position_y = position.y + offset * direction.y

    %{x: real_position_x, y: real_position_y}
  end

  defp randomize_direction_in_angle(direction, angle) do
    angle = :rand.uniform() * angle - angle / 2
    Physics.add_angle_to_direction(direction, angle)
  end

  @doc """
  Receives player's skill input direction, the skill, the player and a list of entities.
  Returns a tuple containing {boolean, direction}:
  - boolean indicates if the skill can trigger the auto aim behavior. All of the following must be met:
    - skill's direction is (0, 0).
    - skill.autoaim is true.
    - nearest entity direction isn't the player's.
  - direction can be one of the following:
    - Direction from player to closest entity, if auto aim can be triggered.
    - Direction where the player is moving, normalized if skill can't pick destination.
    - Direction received by parameter, normalized if skill can't pick destination.
  """
  def maybe_auto_aim(%{x: x, y: y}, skill, player, entities) when x == 0.0 and y == 0.0 do
    case skill.autoaim do
      true ->
        targetable_entities = Entities.filter_targetable(player, entities)

        {use_autoaim?, nearest_entity_position_in_range} =
          Physics.nearest_entity_position_in_range(player, targetable_entities, skill.max_autoaim_range)

        {use_autoaim?, nearest_entity_position_in_range |> maybe_normalize(not skill.can_pick_destination)}

      false ->
        {false, player.direction |> maybe_normalize(not skill.can_pick_destination)}
    end
  end

  def maybe_auto_aim(skill_direction, skill, _player, _entities) do
    {false, skill_direction |> maybe_normalize(not skill.can_pick_destination)}
  end

  defp maybe_normalize(direction, true) do
    Utils.normalize(direction)
  end

  defp maybe_normalize(direction, _false) do
    direction
  end

  defp get_entity_player_owner(_game_state, %{category: :player} = player), do: player

  defp get_entity_player_owner(game_state, %{
         category: :projectile,
         aditional_info: %{owner_id: owner_id}
       }),
       do: get_in(game_state, [:players, owner_id])

  defp get_entity_player_owner(game_state, %{
         category: :trap,
         aditional_info: %{owner_id: owner_id}
       }),
       do: get_in(game_state, [:players, owner_id])

  # Default to zone
  defp get_entity_player_owner(_game_state, _),
    do: %{id: 9999, aditional_info: %{team: :zone}}

  defp maybe_move_player(game_state, %{category: :player} = player, move_by)
       when not is_nil(move_by) do
    player_for_moving = %{player | is_moving: true, speed: move_by}

    physics_player = Physics.move_entity(player_for_moving, 1.0, game_state.external_wall, game_state.obstacles)

    player = Map.merge(player, %{physics_player | is_moving: false, speed: player.speed})
    put_in(game_state, [:players, player.id], player)
  end

  defp maybe_move_player(game_state, _, _) do
    game_state
  end

  def maybe_multiply_by_range(%{x: x, y: y}, false = _auto_aim?, range) do
    %{x: x * range, y: y * range}
  end

  def maybe_multiply_by_range(direction, true = _auto_aim?, _range) do
    direction
  end

  defp apply_damage_and_effects_to_entities(game_state, player, skill_entity, damage, effect \\ nil) do
    # Players
    damageable_players = Entities.filter_damageable(player, game_state.players)
    collided_players = Physics.check_collisions(skill_entity, damageable_players)

    # Apply effects to players
    game_state =
      if is_nil(effect) do
        game_state
      else
        Enum.reduce(collided_players, game_state, fn collided_player_id, game_state ->
          collided_player = Map.get(game_state.players, collided_player_id)
          Effect.put_effect_to_entity(game_state, collided_player, skill_entity.id, effect)
        end)
      end

    players =
      collided_players
      |> Enum.reduce(game_state.players, fn player_id, players_acc ->
        real_damage = Player.calculate_real_damage(player, damage)

        target_player =
          Map.get(players_acc, player_id)
          |> Entities.take_damage(real_damage, player.id)

        send(self(), {:damage_done, player.id, damage})

        Map.put(players_acc, player_id, target_player)
      end)

    # Crates

    alive_crates =
      Crate.alive_crates(game_state.crates)

    crates =
      Physics.check_collisions(skill_entity, alive_crates)
      |> Enum.reduce(game_state.crates, fn crate_id, crates_acc ->
        real_damage = Player.calculate_real_damage(player, damage)

        crate =
          Map.get(crates_acc, crate_id)
          |> Entities.take_damage(real_damage, player.id)

        Map.put(crates_acc, crate_id, crate)
      end)

    %{game_state | players: players, crates: crates}
  end
end
