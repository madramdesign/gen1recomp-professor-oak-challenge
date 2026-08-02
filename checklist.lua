-- Checklist math for Professor Oak Challenge.
local Checklist = {}

local STARTER_LINES = {
  { "BULBASAUR", "IVYSAUR", "VENUSAUR" },
  { "CHARMANDER", "CHARMELEON", "CHARIZARD" },
  { "SQUIRTLE", "WARTORTLE", "BLASTOISE" },
}

local TRADE_FINALS = {
  ALAKAZAM = true,
  MACHAMP = true,
  GOLEM = true,
  GENGAR = true,
}

local OPTIONAL_DEFAULT = {
  MEW = true, -- event
}

function Checklist.owns(game, species)
  local dex = game and game.save and game.save.pokedex
  return dex and dex.owned and dex.owned[species] == true
end

function Checklist.hasBadge(game, badgeId)
  local inv = game and game.save and game.save.inventory
  return inv and inv[badgeId] ~= nil and inv[badgeId] ~= 0
end

local function dedupe(list)
  local out, seen = {}, {}
  for _, s in ipairs(list) do
    if s and not seen[s] then
      out[#out + 1] = s
      seen[s] = true
    end
  end
  return out
end

function Checklist.activeIndex(segments, game)
  for i, seg in ipairs(segments) do
    if not Checklist.hasBadge(game, seg.badge) then
      return i, seg
    end
  end
  return nil, nil
end

function Checklist.requiredThrough(segments, index, opts)
  opts = opts or {}
  local includeTrade = opts.includeTrade == true
  local required, anyOfGroups, fossilPair = {}, {}, nil
  local starterRequired = false

  for i = 1, index do
    local seg = segments[i]
    for _, s in ipairs(seg.add or {}) do
      if TRADE_FINALS[s] and not includeTrade then
        -- skip
      elseif OPTIONAL_DEFAULT[s] and not opts.includeOptional then
        -- skip
      else
        required[#required + 1] = s
      end
    end
    if seg.starterRequired then starterRequired = true end
    for _, group in ipairs(seg.anyOf or {}) do
      anyOfGroups[#anyOfGroups + 1] = group
    end
    if seg.fossilPair then fossilPair = seg.fossilPair end
  end

  -- Drop species that are satisfied by anyOf / fossil (checked separately)
  local skip = {}
  for _, group in ipairs(anyOfGroups) do
    for _, s in ipairs(group) do skip[s] = true end
  end
  if fossilPair then
    for _, line in ipairs(fossilPair) do
      for _, s in ipairs(line) do skip[s] = true end
    end
  end

  local filtered = {}
  for _, s in ipairs(dedupe(required)) do
    if not skip[s] then filtered[#filtered + 1] = s end
  end

  return {
    species = filtered,
    anyOf = anyOfGroups,
    fossilPair = fossilPair,
    starterRequired = starterRequired,
  }
end

local function lineComplete(game, line)
  for _, s in ipairs(line) do
    if not Checklist.owns(game, s) then return false end
  end
  return true
end

local function anyOfSatisfied(game, group)
  for _, s in ipairs(group) do
    if Checklist.owns(game, s) then return true end
  end
  return false
end

local function fossilSatisfied(game, pair)
  -- Need one full line complete
  for _, line in ipairs(pair) do
    if lineComplete(game, line) then return true end
  end
  -- Or at least the base of one line if mid-progress? Classic POC wants evo too.
  return false
end

local function starterStatus(game)
  local chosen = nil
  for _, line in ipairs(STARTER_LINES) do
    if Checklist.owns(game, line[1]) then
      chosen = line
      break
    end
  end
  if not chosen then
    return { ok = false, line = nil, missing = { "STARTER" } }
  end
  local missing = {}
  for _, s in ipairs(chosen) do
    if not Checklist.owns(game, s) then missing[#missing + 1] = s end
  end
  return { ok = #missing == 0, line = chosen, missing = missing }
end

function Checklist.evaluate(segments, game, opts)
  local idx, seg = Checklist.activeIndex(segments, game)
  if not idx then
    return {
      done = true,
      index = nil,
      segment = nil,
      owned = 0,
      total = 0,
      missing = {},
      rows = {},
    }
  end

  local req = Checklist.requiredThrough(segments, idx, opts)
  local missing, rows = {}, {}

  if req.starterRequired then
    local st = starterStatus(game)
    local label = st.line and table.concat(st.line, "/") or "STARTER LINE"
    rows[#rows + 1] = {
      id = "_starter",
      label = "STARTER",
      detail = label,
      ok = st.ok,
    }
    if not st.ok then
      for _, s in ipairs(st.missing) do missing[#missing + 1] = s end
    end
  end

  for _, s in ipairs(req.species) do
    local ok = Checklist.owns(game, s)
    rows[#rows + 1] = { id = s, label = s, ok = ok }
    if not ok then missing[#missing + 1] = s end
  end

  for _, group in ipairs(req.anyOf) do
    -- Skip fossil lines if fossilPair handles them
    local isFossil = false
    if req.fossilPair then
      for _, line in ipairs(req.fossilPair) do
        if group[1] == line[1] then isFossil = true break end
      end
    end
    if not isFossil then
      local ok = anyOfSatisfied(game, group)
      rows[#rows + 1] = {
        id = "_any:" .. table.concat(group, "|"),
        label = table.concat(group, " / "),
        ok = ok,
        anyOf = true,
      }
      if not ok then missing[#missing + 1] = group[1] end
    end
  end

  if req.fossilPair then
    local ok = fossilSatisfied(game, req.fossilPair)
    rows[#rows + 1] = {
      id = "_fossil",
      label = "FOSSIL LINE",
      detail = "OMANYTE or KABUTO",
      ok = ok,
    }
    if not ok then missing[#missing + 1] = "FOSSIL" end
  end

  local owned = 0
  for _, row in ipairs(rows) do
    if row.ok then owned = owned + 1 end
  end

  return {
    done = false,
    index = idx,
    segment = seg,
    owned = owned,
    total = #rows,
    missing = missing,
    rows = rows,
  }
end

Checklist.STARTER_LINES = STARTER_LINES
Checklist.TRADE_FINALS = TRADE_FINALS

return Checklist
