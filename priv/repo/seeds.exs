alias GameBackend.Units.Characters
alias GameBackend.Items
alias GameBackend.Users

champions_of_mirra_id = 2

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Muflus",
  faction: "Araban",
  rarity: "Epic",
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Uma",
  faction: "Kaline",
  rarity: "Epic",
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Dagna",
  faction: "Merliot",
  rarity: "Epic",
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "H4ck",
  faction: "Otobi",
  rarity: "Epic",
})

ChampionsOfMirra.Campaigns.create_campaigns()

Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Epic Sword of Epicness", type: "weapon"})
Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Mythical Helmet of Mythicness", type: "helmet"})
Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Legendary Chestplate of Legendaryness", type: "chest"})
Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Magical Boots of Magicness", type: "boots"})

Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})
Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gems"})
Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Scrolls"})
