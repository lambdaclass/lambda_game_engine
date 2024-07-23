defmodule Arena.Configuration do
  @moduledoc """
  Module in charge of configuration related things
  """

  def get_character_config(name, config) do
    Enum.find(config.characters, fn character -> character.name == name end)
  end

  def get_game_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/config.json")
      |> File.read()

    config = Jason.decode!(config_json, [{:keys, :atoms}])
    characters = parse_characters_config(get_characters_config())
    client_config = get_client_config()
    game_config = get_game_configuration()
    items_config = get_consumable_items_configuration()

    config
    |> Map.put(:characters, characters)
    |> Map.put(:game, game_config)
    |> Map.put(:characters, characters)
    |> Map.put(:items, items_config)
    |> Map.put(:client_config, client_config)
  end

  defp get_client_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/client_config.json")
      |> File.read()

    Jason.decode!(config_json, [{:keys, :atoms}])
  end

  defp get_characters_config() do
    gateway_url = Application.get_env(:arena, :gateway_url)

    {:ok, payload} =
      Finch.build(:get, "#{gateway_url}/curse/configuration/characters", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    Jason.decode!(payload.body, [{:keys, :atoms}])
  end

  defp get_game_configuration() do
    gateway_url = Application.get_env(:arena, :gateway_url)

    {:ok, payload} =
      Finch.build(:get, "#{gateway_url}/curse/configuration/game", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    Jason.decode!(payload.body, [{:keys, :atoms}])
  end

  def get_consumable_items_configuration() do
    gateway_url = Application.get_env(:arena, :gateway_url)

    {:ok, payload} =
      Finch.build(:get, "#{gateway_url}/curse/configuration/consumable_items", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    Jason.decode!(payload.body, [{:keys, :atoms}])
  end

  defp parse_characters_config(characters) do
    Enum.map(characters, fn character ->
      character_skills = %{
        "1" => parse_skill_config(character.basic_skill),
        "2" => parse_skill_config(character.ultimate_skill),
        "3" => parse_skill_config(character.dash_skill)
      }

      Map.put(character, :skills, character_skills)
      |> Map.drop([:basic_skill, :ultimate_skill, :dash_skill])
    end)
  end

  defp parse_skill_config(%{cooldown_mechanism: "stamina", stamina_cost: cost} = skill_config) when cost >= 0 do
    mechanics = parse_mechanics_config(skill_config.mechanics)
    %{skill_config | mechanics: mechanics}
  end

  defp parse_skill_config(%{cooldown_mechanism: "time", cooldown_ms: cooldown} = skill_config) when cooldown >= 0 do
    mechanics = parse_mechanics_config(skill_config.mechanics)
    %{skill_config | mechanics: mechanics}
  end

  defp parse_skill_config(skill_config) do
    case skill_config.cooldown_mechanism do
      "stamina" ->
        raise "Invalid Skill config for `#{skill_config[:name]}` stamina_cost should be a number greater than or equal to zero"

      "time" ->
        raise "Invalid Skill config for `#{skill_config[:name]}` cooldown_ms should be a number greater than or equal to zero"

      _ ->
        raise "Invalid Skill config for `#{skill_config[:name]}` cooldown_mechanism is invalid, should be either `time` or `stamina`"
    end
  end

  defp parse_mechanics_config(mechanics_config) do
    Enum.reduce(mechanics_config, [], fn mechanic_config, acc ->
      mechanic = parse_mechanic_config(mechanic_config)
      [mechanic | acc]
    end)
  end

  defp parse_mechanic_config(nil) do
    nil
  end

  defp parse_mechanic_config(mechanic) do
    ## Why do we even need this? Well it happens that some of our fields are represented
    ## as Decimal. To prevent precision loss this struct its converted to a string of the float
    ## which should be read back and converted to Decimal
    ## The not so small problem we have is that our code expects floats so we still need to parse
    ## the strings, but end up with regular floats
    %{
      mechanic
      | angle_between: maybe_to_float(mechanic.angle_between),
        move_by: maybe_to_float(mechanic.move_by),
        radius: maybe_to_float(mechanic.radius),
        range: maybe_to_float(mechanic.range),
        speed: maybe_to_float(mechanic.speed),
        on_arrival_mechanic: parse_mechanic_config(mechanic.on_arrival_mechanic),
        on_explode_mechanics: parse_mechanics_config(mechanic.on_explode_mechanics)
    }
  end

  defp maybe_to_float(nil), do: nil

  defp maybe_to_float(float_string) do
    {float, ""} = Float.parse(float_string)
    float
  end
end
