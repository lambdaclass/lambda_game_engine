defmodule GameBackend.Repo.Migrations.AddDungeonUpgradesAndBuffs do
  use Ecto.Migration

  def change do
    create(table(:upgrades)) do
      add(:game_id, :integer)
      add(:name, :string)
      add(:description, :string)
      add(:group, :integer)
      add(:cost, :map)

      timestamps()
    end

    create(table(:buffs)) do
      add(:game_id, :integer)
      add(:name, :string)
      add(:modifiers, :map)
      add(:upgrade_id, references(:upgrades, on_delete: :delete_all))

      timestamps()
    end

    alter(table(:skills)) do
      add(:buff_id, references(:buffs, on_delete: :delete_all))
    end

    create(table(:upgrade_unlocks)) do
      add(:upgrade_locking_id, references(:upgrades, on_delete: :delete_all), null: false, primary_key: true)
      add(:upgrade_unlocked_id, references(:upgrades, on_delete: :delete_all), null: false, primary_key: true)

      timestamps()
    end

    create(unique_index(:upgrades, [:name]))
    create(unique_index(:buffs, [:name]))
  end
end
