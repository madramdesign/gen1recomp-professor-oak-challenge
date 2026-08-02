-- Map → catch targets from Mewlax RB Oak Guide.
-- Keys are map ids (or prefixes). Values are species you can obtain here.
-- Evolutions of those lines are inferred in the HUD when still needed.

local Areas = {}

-- Longest-prefix match helpers for caves / multi-floor maps.
Areas.PREFIX = {
  MT_MOON = { "ZUBAT", "GEODUDE", "PARAS", "CLEFAIRY" },
  DIGLETTS_CAVE = { "DIGLETT", "DUGTRIO" },
  POKEMON_TOWER = { "GASTLY", "HAUNTER", "CUBONE" },
  POKEMON_MANSION = { "KOFFING", "GRIMER", "PONYTA", "MAGMAR" },
  SEAFOAM_ISLANDS = { "SEEL", "DEWGONG", "ARTICUNO" },
  SAFARI_ZONE = {
    "DRATINI", "EXEGGCUTE", "RHYHORN", "CHANSEY",
    "SCYTHER", "PINSIR", "TAUROS", "KANGASKHAN", "VENONAT",
  },
  VICTORY_ROAD = { "MOLTRES" },
  CERULEAN_CAVE = { "MEWTWO" },
  POWER_PLANT = { "MAGNEMITE", "ELECTABUZZ", "ZAPDOS", "VOLTORB" },
  SILPH_CO = { "LAPRAS" },
  SS_ANNE = {}, -- trainers / HM only
  ROCK_TUNNEL = { "MACHOP", "ONIX" },
  CELADON_MANSION = { "EEVEE" },
}

Areas.MAPS = {
  PALLET_TOWN = { "BULBASAUR", "CHARMANDER", "SQUIRTLE", "TANGELA" }, -- Tangela via Surf south grass
  ROUTE_1 = { "PIDGEY", "RATTATA" },
  ROUTE_22 = { "NIDORAN_F", "NIDORAN_M", "SPEAROW", "MANKEY", "EKANS" },
  VIRIDIAN_FOREST = { "CATERPIE", "WEEDLE", "METAPOD", "KAKUNA", "PIKACHU" },
  VIRIDIAN_FOREST_NORTH_GATE = { "CATERPIE", "WEEDLE", "PIKACHU" },
  VIRIDIAN_FOREST_SOUTH_GATE = { "CATERPIE", "WEEDLE", "PIKACHU" },
  ROUTE_2 = { "PIDGEY", "RATTATA", "CATERPIE", "WEEDLE" },
  ROUTE_2_TRADE_HOUSE = { "MR_MIME" },
  ROUTE_3 = { "JIGGLYPUFF", "SPEAROW", "PIDGEY" },
  ROUTE_4 = { "MAGIKARP", "EKANS", "SANDSHREW", "SPEAROW", "RATTATA" },
  MT_MOON_POKECENTER = { "MAGIKARP" },
  ROUTE_24 = { "ABRA", "ODDISH", "BELLSPROUT", "CATERPIE", "WEEDLE", "PIDGEY" },
  ROUTE_25 = { "ABRA", "ODDISH", "BELLSPROUT", "PIDGEY", "SPEAROW" },
  ROUTE_5 = { "MANKEY", "MEOWTH", "PIDGEY", "ODDISH", "BELLSPROUT" },
  ROUTE_6 = { "MANKEY", "MEOWTH", "PIDGEY", "ODDISH", "BELLSPROUT" },
  ROUTE_11 = { "DROWZEE", "SPEAROW", "EKANS", "SANDSHREW" },
  VERMILION_CITY = { "FARFETCHD" }, -- Spearow trade
  VERMILION_TRADE_HOUSE = { "FARFETCHD" },
  VERMILION_OLD_ROD_HOUSE = { "MAGIKARP" },
  CERULEAN_CITY = {},
  CERULEAN_TRADE_HOUSE = { "JYNX" }, -- Poliwhirl trade
  ROUTE_9 = { "VOLTORB", "SPEAROW", "EKANS", "SANDSHREW" },
  ROUTE_10 = { "VOLTORB", "SPEAROW", "EKANS", "SANDSHREW" },
  ROUTE_8 = { "GROWLITHE", "VULPIX", "PIDGEY", "MANKEY", "MEOWTH" },
  CELADON_CITY = { "EEVEE", "PORYGON" },
  CELADON_MANSION_ROOF_HOUSE = { "EEVEE" },
  GAME_CORNER = { "PORYGON" },
  GAME_CORNER_PRIZE_ROOM = { "PORYGON", "ABRA", "CLEFAIRY" },
  ROUTE_16 = { "DODUO", "RATTATA", "SPEAROW" },
  LAVENDER_TOWN = {},
  ROUTE_12 = { "SNORLAX", "PIDGEY", "ODDISH", "VENONAT", "BELLSPROUT" },
  ROUTE_12_SUPER_ROD_HOUSE = {}, -- Super Rod
  ROUTE_11 = { "DROWZEE", "SPEAROW", "EKANS" },
  ROUTE_13 = { "PIDGEY", "ODDISH", "VENONAT", "BELLSPROUT", "DITTO" },
  ROUTE_14 = { "DITTO", "VENONAT", "PIDGEY", "ODDISH", "BELLSPROUT" },
  ROUTE_15 = { "DITTO", "VENONAT", "PIDGEY", "ODDISH", "BELLSPROUT" },
  FUCHSIA_CITY = {},
  FUCHSIA_GOOD_ROD_HOUSE = {},
  ROUTE_18_GATE_2F = { "LICKITUNG" }, -- Slowbro trade
  FIGHTING_DOJO = { "HITMONLEE", "HITMONCHAN" },
  ROUTE_19 = { "TENTACOOL" }, -- surf/fish
  ROUTE_20 = { "TENTACOOL" },
  ROUTE_21 = { "TANGELA", "TENTACOOL" },
  CINNABAR_ISLAND = {},
  CINNABAR_LAB = { "OMANYTE", "KABUTO", "AERODACTYL" },
  CINNABAR_LAB_FOSSIL_ROOM = { "OMANYTE", "KABUTO", "AERODACTYL" },
  PEWTER_CITY = {},
  PEWTER_GYM = {}, -- grind tip only
  VIRIDIAN_CITY = {},
  -- Fishing hubs (rods work in many waters; list common targets)
  VERMILION_DOCK = { "TENTACOOL", "SHELLDER", "KRABBY", "POLIWAG", "GOLDEEN" },
}

-- Gen 1 evolution lines for "still need to evolve" hints on the catch map.
Areas.LINES = {
  BULBASAUR = { "BULBASAUR", "IVYSAUR", "VENUSAUR" },
  CHARMANDER = { "CHARMANDER", "CHARMELEON", "CHARIZARD" },
  SQUIRTLE = { "SQUIRTLE", "WARTORTLE", "BLASTOISE" },
  CATERPIE = { "CATERPIE", "METAPOD", "BUTTERFREE" },
  WEEDLE = { "WEEDLE", "KAKUNA", "BEEDRILL" },
  PIDGEY = { "PIDGEY", "PIDGEOTTO", "PIDGEOT" },
  RATTATA = { "RATTATA", "RATICATE" },
  SPEAROW = { "SPEAROW", "FEAROW" },
  NIDORAN_F = { "NIDORAN_F", "NIDORINA", "NIDOQUEEN" },
  NIDORAN_M = { "NIDORAN_M", "NIDORINO", "NIDOKING" },
  PIKACHU = { "PIKACHU", "RAICHU" },
  SANDSHREW = { "SANDSHREW", "SANDSLASH" },
  EKANS = { "EKANS", "ARBOK" },
  ZUBAT = { "ZUBAT", "GOLBAT" },
  GEODUDE = { "GEODUDE", "GRAVELER", "GOLEM" },
  PARAS = { "PARAS", "PARASECT" },
  CLEFAIRY = { "CLEFAIRY", "CLEFABLE" },
  JIGGLYPUFF = { "JIGGLYPUFF", "WIGGLYTUFF" },
  MAGIKARP = { "MAGIKARP", "GYARADOS" },
  ABRA = { "ABRA", "KADABRA", "ALAKAZAM" },
  ODDISH = { "ODDISH", "GLOOM", "VILEPLUME" },
  BELLSPROUT = { "BELLSPROUT", "WEEPINBELL", "VICTREEBEL" },
  MANKEY = { "MANKEY", "PRIMEAPE" },
  MEOWTH = { "MEOWTH", "PERSIAN" },
  DROWZEE = { "DROWZEE", "HYPNO" },
  DIGLETT = { "DIGLETT", "DUGTRIO" },
  VOLTORB = { "VOLTORB", "ELECTRODE" },
  MACHOP = { "MACHOP", "MACHOKE", "MACHAMP" },
  GROWLITHE = { "GROWLITHE", "ARCANINE" },
  VULPIX = { "VULPIX", "NINETALES" },
  EEVEE = { "EEVEE", "VAPOREON", "JOLTEON", "FLAREON" },
  DODUO = { "DODUO", "DODRIO" },
  GASTLY = { "GASTLY", "HAUNTER", "GENGAR" },
  CUBONE = { "CUBONE", "MAROWAK" },
  SHELLDER = { "SHELLDER", "CLOYSTER" },
  POLIWAG = { "POLIWAG", "POLIWHIRL", "POLIWRATH" },
  GOLDEEN = { "GOLDEEN", "SEAKING" },
  KRABBY = { "KRABBY", "KINGLER" },
  HORSEA = { "HORSEA", "SEADRA" },
  STARYU = { "STARYU", "STARMIE" },
  PSYDUCK = { "PSYDUCK", "GOLDUCK" },
  SLOWPOKE = { "SLOWPOKE", "SLOWBRO" },
  TENTACOOL = { "TENTACOOL", "TENTACRUEL" },
  VENONAT = { "VENONAT", "VENOMOTH" },
  DRATINI = { "DRATINI", "DRAGONAIR", "DRAGONITE" },
  EXEGGCUTE = { "EXEGGCUTE", "EXEGGUTOR" },
  RHYHORN = { "RHYHORN", "RHYDON" },
  MAGNEMITE = { "MAGNEMITE", "MAGNETON" },
  OMANYTE = { "OMANYTE", "OMASTAR" },
  KABUTO = { "KABUTO", "KABUTOPS" },
  KOFFING = { "KOFFING", "WEEZING" },
  GRIMER = { "GRIMER", "MUK" },
  PONYTA = { "PONYTA", "RAPIDASH" },
  SEEL = { "SEEL", "DEWGONG" },
}

function Areas.speciesForMap(mapId)
  if not mapId then return {} end
  local exact = Areas.MAPS[mapId]
  if exact then return exact end
  for prefix, list in pairs(Areas.PREFIX) do
    if mapId:sub(1, #prefix) == prefix then
      return list
    end
  end
  return {}
end

function Areas.lineFor(species)
  if Areas.LINES[species] then return Areas.LINES[species] end
  for _, line in pairs(Areas.LINES) do
    for _, s in ipairs(line) do
      if s == species then return line end
    end
  end
  return { species }
end

--- Missing species relevant to this map, among `wanted` (set or list of ids).
function Areas.missingHere(mapId, wantedSet, ownsFn)
  local catchables = Areas.speciesForMap(mapId)
  local missing, seen = {}, {}
  for _, base in ipairs(catchables) do
    local line = Areas.lineFor(base)
    for _, s in ipairs(line) do
      if wantedSet[s] and not ownsFn(s) and not seen[s] then
        missing[#missing + 1] = s
        seen[s] = true
      end
    end
  end
  return missing
end

return Areas
