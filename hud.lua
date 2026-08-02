-- Overworld HUD: show what you still need in this area (QoL banner pattern).
local OVERLAY_KEY = "__pocAreaHudOverlay"

return function(mod, deps)
  local Checklist = deps.Checklist
  local Areas = deps.Areas
  local segmentsFor = deps.segmentsFor
  local evalOpts = deps.evalOpts

  local hudState = setmetatable({}, { __mode = "k" })
  local lastMap = setmetatable({}, { __mode = "k" })

  local function game()
    return mod.world and mod.world.game
  end

  local function overworld()
    if mod.world and mod.world.overworld then
      return mod.world:overworld()
    end
  end

  local function displayName(g, species)
    local def = g and g.data and g.data.pokemon and g.data.pokemon[species]
    if def and def.name then return def.name end
    return species:gsub("_", " ")
  end

  local function shortName(g, species)
    local n = displayName(g, species):upper()
    if #n > 10 then n = n:sub(1, 10) end
    return n
  end

  local function wantedSet(status)
    local set = {}
    for _, row in ipairs(status.rows or {}) do
      if not row.ok and row.id and row.id:sub(1, 1) ~= "_" then
        set[row.id] = true
      end
    end
    for _, id in ipairs(status.missing or {}) do
      if type(id) == "string" and id:sub(1, 1) ~= "_"
         and id ~= "STARTER" and id ~= "FOSSIL" and id ~= "MOON_STONE_EVO" then
        set[id] = true
      end
    end
    return set
  end

  local function buildState(g, mapId)
    local segs = segmentsFor(g)
    local status = Checklist.evaluate(segs, g, evalOpts())
    if status.done then
      return {
        title = "OAK DONE",
        progress = "",
        lines = { "Version complete!" },
        hereCount = 0,
      }
    end
    local seg = status.segment
    local owns = function(s) return Checklist.owns(g, s) end
    local here = Areas.missingHere(mapId, wantedSet(status), owns)
    local lines = {}
    if #here == 0 then
      local areaHas = Areas.speciesForMap(mapId)
      if #areaHas == 0 then
        lines[1] = "No catches here"
      else
        lines[1] = "Area clear!"
      end
    else
      local buf = ""
      for i, s in ipairs(here) do
        local piece = shortName(g, s)
        if #buf == 0 then
          buf = piece
        elseif #buf + 1 + #piece <= 16 then
          buf = buf .. " " .. piece
        else
          lines[#lines + 1] = buf
          buf = piece
          if #lines >= 3 then
            local left = #here - i + 1
            if left > 0 then lines[#lines + 1] = ("+%d MORE"):format(left) end
            buf = ""
            break
          end
        end
      end
      if buf ~= "" and #lines < 4 then lines[#lines + 1] = buf end
    end
    return {
      title = seg and ("OAK " .. seg.label) or "OAK",
      progress = ("%d/%d"):format(status.owned, status.total),
      mapId = mapId,
      lines = lines,
      hereCount = #here,
    }
  end

  local function drawHud(ow)
    local state = hudState[ow]
    if not state then return end
    local mode = mod.options:get("areaHud")
    if mode == "off" then
      hudState[ow] = nil
      return
    end
    if mode == "enter" and state.expiresAt and love.timer.getTime() >= state.expiresAt then
      hudState[ow] = nil
      return
    end

    local Font = mod.ui.Font
    local lines = state.lines or {}
    local extra = (state.hereCount and state.hereCount > 0) and 1 or 0
    local h = math.min(8, 2 + extra + #lines)
    local ty = 18 - h
    if ty < 1 then ty = 1 end
    Font.drawBox(0, ty, 20, h)
    love.graphics.setColor(0, 0, 0, 1)
    local header = state.title or "OAK"
    if state.progress and state.progress ~= "" then
      header = header .. " " .. state.progress
    end
    Font.draw(header, 8, ty * 8 + 8)
    local y = ty * 8 + 16
    if state.hereCount and state.hereCount > 0 then
      Font.draw("NEED HERE:", 8, y)
      y = y + 8
    end
    for _, line in ipairs(lines) do
      Font.draw(line, 8, y)
      y = y + 8
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  local function ensureOverlay(ow)
    local overlay = rawget(ow, OVERLAY_KEY)
    if not overlay and type(ow.drawUI) == "function" then
      overlay = {}
      ow[OVERLAY_KEY] = overlay
      local drawUI = ow.drawUI
      ow.drawUI = function(self, ...)
        drawUI(self, ...)
        local current = rawget(self, OVERLAY_KEY)
        if current and current.draw then current.draw(self) end
      end
    end
    if overlay then overlay.draw = drawHud end
  end

  local function showForMap(mapId)
    local g = game()
    local ow = overworld()
    if not g or not ow or not mapId then return end
    local mode = mod.options:get("areaHud")
    if mode == "off" then
      hudState[ow] = nil
      return
    end
    local state = buildState(g, mapId)
    if mode == "enter" then
      local dur = tonumber(mod.options:get("areaHudSeconds")) or 4
      state.expiresAt = love.timer.getTime() + dur
    else
      state.expiresAt = nil
    end
    hudState[ow] = state
    lastMap[ow] = mapId
    ensureOverlay(ow)
  end

  mod.events:on("map.entered", function(event)
    if not event or not event.mapId then return end
    showForMap(event.mapId)
  end)

  local function refresh()
    if mod.options:get("areaHud") ~= "always" then return end
    local ow = overworld()
    local mapId = ow and lastMap[ow]
    if not mapId and ow and ow.map then mapId = ow.map.id end
    if mapId then showForMap(mapId) end
  end

  mod.events:on("pokemon.caught", function() refresh() end)
  mod.events:on("pokemon.evolved", function() refresh() end)

  return { refresh = refresh, showForMap = showForMap }
end
