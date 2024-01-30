defmodule GameBackend.Campaigns do
  @moduledoc """
  Operations with Campaigns and Levels.
  """
  @units_per_level 5
  @champions_of_mirra_id 2

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Campaigns.Level
  alias GameBackend.Units

  @doc """
  Gets all levels, grouped by campaign and sorted ascendingly.
  """
  def get_campaigns() do
    Repo.all(from(l in Level))
    |> Repo.preload(:units)
    |> Enum.sort(fn l1, l2 -> l1.level_number < l2.level_number end)
    |> Enum.group_by(fn l -> l.campaign end)
  end

  def get_campaign(campaign_number) do
    Repo.all(from(l in Level, where: l.campaign == ^campaign_number))
    |> Repo.preload(:units)
  end

  @doc """
  Inserts a level.
  """
  def insert_level(attrs) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get a level by id.
  """
  def get_level(level_id) do
    Repo.get(Level, level_id) |> Repo.preload(units: :items)
  end

  @doc """
  Creates levels for Champions of Mirra with a given set of rules, storing them and their units in the DB.

  Rules needed are:
  - `base_level`: the aggregate level of all units in the first level of the campaign
  - `scaler`: used to calculate the aggregate level of the campaign's levels, multiplying the previous level's aggregate by this value
  - `possible_factions`: which factions the randomly generated units can belong to
  - `length`: the length of the campaign.

  Each of the rule maps given represents a campaign, and the number of the campaign (stored in the Level)
  will be equal to the index of its rules in the list (1-based).

  Returns an :ok atom.
  """
  def create_campaigns() do
    create_campaigns([
      %{base_level: 5, scaler: 1.5, possible_factions: ["Araban", "Kaline"], length: 10},
      %{base_level: 50, scaler: 1.7, possible_factions: ["Merliot", "Otobi"], length: 20}
    ])
  end

  defp create_campaigns(rules) do
    Enum.each(Enum.with_index(rules, 1), fn {campaign_rules, campaign_index} ->
      base_level = campaign_rules.base_level
      level_scaler = campaign_rules.scaler

      possible_characters = Units.all_characters_from_factions(campaign_rules.possible_factions)

      Enum.map(1..campaign_rules.length, fn level_index ->
        agg_difficulty = (base_level * (level_scaler |> Math.pow(level_index))) |> round()

        level_units =
          create_unit_params(possible_characters, div(agg_difficulty, @units_per_level))
          |> add_remainder_unit_levels(rem(agg_difficulty, @units_per_level))

        insert_level(%{
          game_id: @champions_of_mirra_id,
          units: level_units,
          campaign: campaign_index,
          level_number: level_index
        })
      end)
    end)
  end

  defp create_unit_params(possible_characters, level) do
    Enum.map(0..4, fn _ ->
      Units.unit_params_for_level(possible_characters, level)
    end)
  end

  defp add_remainder_unit_levels(units, amount_to_add) do
    Enum.reduce(0..(amount_to_add - 1), units, fn index, units ->
      List.update_at(units, index, fn unit -> %{unit | unit_level: unit.unit_level + 1} end)
    end)
  end
end
