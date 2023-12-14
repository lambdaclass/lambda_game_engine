defmodule DarkWorldsServer.Config.Game.Loot do
  use Ecto.Schema
  import Ecto.Changeset

  @pickup_mechanics ["collision_use", "collision_to_inventory"]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "loots" do
    field(:name, :string)
    field(:size, :integer)
    field(:pickup_mechanic, :string)

    timestamps()
  end

  @doc false
  def changeset(loot, attrs),
    do:
      loot
      |> cast(attrs, [:name, :size])
      |> cast_pickup_mechanic(attrs)
      |> validate_required([:name, :size, :pickup_mechanic])
      |> validate_inclusion(:pickup_mechanic, @pickup_mechanics)

  defp cast_pickup_mechanic(changeset, %{pickup_mechanic: :collision_use}),
    do: cast(changeset, %{pickup_mechanic: "collision_use"}, [:pickup_mechanic])

  defp cast_pickup_mechanic(changeset, %{pickup_mechanic: :collision_to_inventory}),
    do: cast(changeset, %{pickup_mechanic: "collision_to_inventory"}, [:pickup_mechanic])

  defp cast_pickup_mechanic(changeset, %{pickup_mechanic: pickup_mechanic}),
    do: cast(changeset, %{pickup_mechanic: pickup_mechanic}, [:pickup_mechanic])
end
