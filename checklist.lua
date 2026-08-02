-- Checklist math for Professor Oak Challenge (Mewlax RB guide order).
local Checklist = {}

local STARTER_LINES = {
  { "BULBASAUR", "IVYSAUR", "VENUSAUR" },
  { "CHARMANDER", "CHARMELEON", "CHARIZARD" },
  { "SQUIRTLE", "WARTORTLE", "BLASTOISE" },
}

local TRADE_FINALS = {
  ALAKAZAM = true, MACHAMP = true, GOLEM = true, GENGAR = true,
}

function Checklist.owns(game, species)
  local dex = game and game.save and game.save.pokedex
  return dex and dex.owned and dex.owned[species] == true
end

function Checklist.hasBadge(game, badgeId)
  if not badgeId then return true end
  local inv = game and game.save and game.save.inventory
  return inv and inv[badgeId] ~= nil and inv[badgeId] ~= 0
end

function Checklist.isChampion(game)
  local flags = game and game.save and game.save.flags
  -- Common champion / hall of fame flags across ports
  if not flags then return false end
  return flags.EVENT_BEAT_CHAMPION_RIVAL
      or flags.EVENT_HALL_OF_FAME
      or flags.STATUS_COMPLETED_HALL
      or flags.EVENT_BECOME_CHAMPION
      or false
end

local function dedupe(list)
  local out, seen = {}, {}
  for _, s in ipairs(list or {}) do
    if s and not seen[s] then
      out[#out + 1] = s
      seen[s] = true
    end
  end
  return out
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
  for _, line in ipairs(pair) do
    if lineComplete(game, line) then return true end
  end
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

local function moonStoneStatus(game, pool, need)
  local owned = 0
  local have = {}
  for _, s in ipairs(pool or {}) do
    if Checklist.owns(game, s) then
      owned = owned + 1
      have[#have + 1] = s
    end
  end
  need = need or #pool
  return {
    ok = owned >= need,
    owned = owned,
    need = need,
    have = have,
    missing = math.max(0, need - owned),
  }
end

--- Active segment follows Mewlax part order, not gym number order.
function Checklist.activeIndex(segments, game)
  for i, seg in ipairs(segments) do
    if seg.badge and not Checklist.hasBadge(game, seg.badge) then
      return i, seg
    elseif seg.requireBadge then
      if Checklist.hasBadge(game, seg.requireBadge) then
        local pending = false
        for _, s in ipairs(seg.add or {}) do
          if not Checklist.owns(game, s) then pending = true break end
        end
        if pending then return i, seg end
      end
    elseif seg.gateEliteFour then
      if Checklist.hasBadge(game, "RAINBOWBADGE")
         and Checklist.owns(game, "ARTICUNO")
         and not Checklist.owns(game, "MOLTRES") then
        return i, seg
      end
    elseif seg.postGame then
      if Checklist.isChampion(game) and not Checklist.owns(game, "MEWTWO") then
        return i, seg
      end
    end
  end
  return nil, nil
end

function Checklist.requiredThrough(segments, index, opts)
  opts = opts or {}
  local includeTrade = opts.includeTrade == true
  local required, anyOfGroups, fossilPair = {}, {}, nil
  local starterRequired = false
  local moonPool, moonNeed = nil, nil

  for i = 1, index do
    local seg = segments[i]
    for _, s in ipairs(seg.add or {}) do
      if TRADE_FINALS[s] and not includeTrade then
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
    if seg.moonStonePool then
      moonPool = seg.moonStonePool
      moonNeed = seg.moonStoneNeed or #seg.moonStonePool
    end
  end

  local skip = {}
  for _, group in ipairs(anyOfGroups) do
    for _, s in ipairs(group) do skip[s] = true end
  end
  if fossilPair then
    for _, line in ipairs(fossilPair) do
      for _, s in ipairs(line) do skip[s] = true end
    end
  end
  if moonPool then
    for _, s in ipairs(moonPool) do skip[s] = true end
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
    moonStonePool = moonPool,
    moonStoneNeed = moonNeed,
  }
end

function Checklist.evaluateAt(segments, game, index, opts)
  opts = opts or {}
  local seg = segments[index]
  local req = Checklist.requiredThrough(segments, index, opts)
  local missing, rows = {}, {}

  if req.starterRequired then
    local st = starterStatus(game)
    rows[#rows + 1] = {
      id = "_starter",
      label = "STARTER",
      detail = st.line and table.concat(st.line, "/") or "pick one",
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

  if req.moonStonePool then
    local ms = moonStoneStatus(game, req.moonStonePool, req.moonStoneNeed)
    rows[#rows + 1] = {
      id = "_moon",
      label = "MOON STONES",
      detail = ("%d/%d evolutions"):format(ms.owned, ms.need),
      ok = ms.ok,
    }
    if not ms.ok then missing[#missing + 1] = "MOON_STONE_EVO" end
  end

  for _, group in ipairs(req.anyOf) do
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
    complete = #missing == 0,
    segment = seg,
    index = index,
    owned = owned,
    total = #rows,
    missing = missing,
    rows = rows,
    tips = seg and seg.tips or {},
  }
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
      tips = {
        "Challenge complete for this version!",
        "Still missing: trade evos, other version exclusives,",
        "unchosen starters / Hitmon / Eevee / fossil, and Mew.",
      },
    }
  end
  local st = Checklist.evaluateAt(segments, game, idx, opts)
  st.done = false
  return st
end

--- True if this gym leader should be gated by the active checklist.
function Checklist.shouldGateLeader(segments, game, leaderKey, opts)
  local status = Checklist.evaluate(segments, game, opts)
  if status.done or #status.missing == 0 then return false, status end
  local seg = status.segment
  if not seg then return false, status end
  -- Gate if talking to the leader that ends this part
  if seg.leaderKey and seg.leaderKey == leaderKey then
    return true, status
  end
  -- Also gate any later gym while an earlier part is incomplete
  local victories = require("data.scripts.victories")
  local reward = victories[leaderKey]
  if not reward or not reward.badge then return false, status end
  if Checklist.hasBadge(game, reward.badge) then return false, status end
  -- Find if this leader is a "later" gate than active
  for _, s in ipairs(segments) do
    if s.leaderKey == leaderKey then
      -- Fighting a part-leader while stuck on an earlier incomplete part
      if seg.leaderKey and s.leaderKey ~= seg.leaderKey then
        return true, status
      end
      if s.leaderKey == seg.leaderKey then
        return true, status
      end
    end
  end
  -- Non-guide gyms (Surge etc.) while early parts incomplete: warn/block too
  if seg.badge and not Checklist.hasBadge(game, seg.badge) then
    return true, status
  end
  return false, status
end

Checklist.STARTER_LINES = STARTER_LINES
Checklist.TRADE_FINALS = TRADE_FINALS

return Checklist
