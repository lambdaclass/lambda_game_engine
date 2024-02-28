defmodule GameBackend.Campaigns.Rewards.UnitReward do
  @moduledoc """
  The representation of a level reward that gives a unit to the user.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Unit
  alias GameBackend.Campaigns.Level

  schema "unit_rewards" do
    # TODO: Should have a character and other unit params to build it, not an unit [CHoM-#215]
    belongs_to(:unit, Unit)
    belongs_to(:level, Level)
    field(:amount, :integer)

    timestamps()
  end

  @doc false
  def changeset(unit_reward, attrs) do
    unit_reward
    |> cast(attrs, [:unit_id, :level_id, :amount])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_required([:amount])
  end
end
