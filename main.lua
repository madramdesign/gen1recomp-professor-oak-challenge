-- Professor Oak Challenge for Gen1Recomp.
-- Catch (and evolve) every available Pokémon before each gym badge.

local SCREEN = "PocChecklist"

return function(mod)
  local compile = loadstring or load

  local function loadModule(path)
    local source, readError = mod:read(path)
    if not source then
      error("cannot read " .. path .. ": " .. tostring(readError), 0)
    end
    local chunk, err = compile(source, "@" .. mod.path .. "/" .. path)
    if not chunk then
      error("cannot compile " .. path .. ": " .. tostring(err), 0)
    end
    return chunk()
  end

  local Checklist = loadModule("checklist.lua")
  local redSegments = loadModule("segments_red.lua")
  local bluePatch = loadModule("segments_blue.lua")

  mod.options:define({
    {
      key = "mode",
      label = "GATE MODE",
      type = "choice",
      default = "soft",
      choices = {
        { "SOFT (WARN)", "soft" },
        { "HARD (BLOCK)", "hard" },
        { "OFF", "off" },
      },
      description = "SOFT asks before gyms. HARD blocks until the checklist is done. OFF only tracks.",
    },
    {
      key = "includeTrade",
      label = "REQUIRE TRADE EVOS",
      type = "toggle",
      default = false,
      description = "Also require Alakazam, Machamp, Golem, and Gengar (needs trading).",
    },
  })

  local function versionId(game)
    local ok, GameVersion = pcall(require, "src.core.GameVersion")
    if ok and GameVersion and GameVersion.get then
      return GameVersion.get(game) or GameVersion.get() or "red"
    end
    return "red"
  end

  local function segmentsFor(game)
    local v = tostring(versionId(game)):lower()
    if v == "blue" then return bluePatch(redSegments) end
    -- Yellow: start from Red (Pikachu starter still works via starterRequired)
    return redSegments
  end

  local function evalOpts()
    return { includeTrade = mod.options:get("includeTrade") == true }
  end

  local function displayName(game, species)
    local def = game and game.data and game.data.pokemon and game.data.pokemon[species]
    if def and def.name then return def.name end
    return species
  end

  -- ------- Start-menu checklist
  mod.content.screens:register(SCREEN, {
    new = function(game)
      local segs = segmentsFor(game)
      local status = Checklist.evaluate(segs, game, evalOpts())
      local items = {}

      if status.done then
        items[1] = { label = "ALL BADGES DONE!", right = "OK", value = "_done" }
      else
        local seg = status.segment
        items[#items + 1] = {
          label = ("NEXT: %s"):format(seg.label),
          right = ("%d/%d"):format(status.owned, status.total),
          value = "_hdr",
        }
        items[#items + 1] = {
          label = seg.mapHint or seg.badge,
          right = "",
          value = "_map",
        }
        for _, row in ipairs(status.rows) do
          local name = row.id:sub(1, 1) == "_" and (row.label or row.id)
            or displayName(game, row.id)
          if row.detail then name = name .. " (" .. row.detail .. ")" end
          -- trim for 18-col feel
          if #name > 14 then name = name:sub(1, 14) end
          items[#items + 1] = {
            label = name,
            right = row.ok and "OWN" or "NEED",
            value = row.id,
          }
        end
      end

      return mod.ui.ListMenu.new(game, "OAK CHALLENGE", items, {
        pageJump = true,
        onChoose = function(_, menu) menu:close() end,
      })
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "OAK CHALLENGE",
      onSelect = function() mod.ui.push(game, SCREEN) end,
    })
  end)

  -- ------- Gym leader gate
  local function leaderKey(npc)
    local d = npc and npc.def
    if not d or not d.trainerClass then return nil end
    return tostring(d.trainerClass) .. "#" .. tostring(d.trainerParty or 1)
  end

  local function isGymLeaderKey(key)
    local ok, victories = pcall(require, "data.scripts.victories")
    if not ok or type(victories) ~= "table" then return false end
    local reward = victories[key]
    return reward and reward.badge ~= nil
  end

  local function refuseMessage(status)
    local seg = status.segment
    local left = status.total - status.owned
    return ("OAK's words echoed…\nCatch every POKéMON\nfirst! (%d left)\n%s"):format(
      left, seg and seg.label or "")
  end

  local function softMessage(status)
    local left = status.total - status.owned
    return ("Professor Oak Challenge\n%d POKéMON still needed\nfor %s.\nChallenge anyway?"):format(
      left, status.segment and status.segment.label or "this gym")
  end

  local function install(game)
    local Overworld = require("src.world.OverworldController")
    local TextBox = require("src.render.TextBox")
    if Overworld._pocWrapped then return end
    Overworld._pocWrapped = true

    local vanilla = Overworld.engageTrainer
    Overworld.engageTrainer = function(self, npc, onDone)
      local mode = mod.options:get("mode")
      if mode == "off" then
        return vanilla(self, npc, onDone)
      end

      local key = leaderKey(npc)
      if not key or not isGymLeaderKey(key) then
        return vanilla(self, npc, onDone)
      end

      local victories = require("data.scripts.victories")
      local reward = victories[key]
      -- Already hold this badge (rematch / re-talk) — never gate
      if reward and Checklist.hasBadge(game, reward.badge) then
        return vanilla(self, npc, onDone)
      end

      local status = Checklist.evaluate(segmentsFor(game), game, evalOpts())
      if status.done or #status.missing == 0 then
        return vanilla(self, npc, onDone)
      end

      if mode == "hard" then
        game.stack:push(TextBox.new(game, refuseMessage(status), function()
          if onDone then onDone() end
        end))
        return
      end

      -- soft
      game.stack:push(TextBox.new(game, softMessage(status), nil, {
        choice = function(yes)
          if yes then
            vanilla(self, npc, onDone)
          elseif onDone then
            onDone()
          end
        end,
      }))
    end
  end

  mod.events:on("game.ready", function(ev)
    install(ev.game)
  end)

  mod.exports.evaluate = function(game)
    return Checklist.evaluate(segmentsFor(game), game, evalOpts())
  end
  mod.exports.checklist = Checklist

  mod.log:info("Professor Oak Challenge ready (mode=%s)", tostring(mod.options:get("mode")))
end
