-- Professor Oak Challenge for Gen1Recomp.
-- Progression follows Mewlax's RB Oak Guide:
-- https://docs.google.com/document/d/1gmp-piwpfUUyxnWULjQtB2m2lzWeYc-wwsXnnbyp_RY

local SCREEN = "PocChecklist"
local E4_KEYS = {
  ["OPP_LORELEI#1"] = true,
  ["OPP_BRUNO#1"] = true,
  ["OPP_AGATHA#1"] = true,
  ["OPP_LANCE#1"] = true,
  ["OPP_RIVAL3#1"] = true,
  ["OPP_RIVAL3#2"] = true,
  ["OPP_RIVAL3#3"] = true,
}

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
  local Areas = loadModule("areas.lua")
  local installHud = loadModule("hud.lua")

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
      description = "SOFT asks before gated fights. HARD blocks. OFF tracks only.",
    },
    {
      key = "includeTrade",
      label = "REQUIRE TRADE EVOS",
      type = "toggle",
      default = false,
      description = "Also require Alakazam, Machamp, Golem, Gengar (needs trading).",
    },
    {
      key = "showTips",
      label = "SHOW GUIDE TIPS",
      type = "toggle",
      default = true,
      description = "Include Mewlax guide tips at the top of the checklist.",
    },
    {
      key = "areaHud",
      label = "AREA CATCH HUD",
      type = "choice",
      default = "enter",
      choices = {
        { "ON ENTER", "enter" },
        { "ALWAYS", "always" },
        { "OFF", "off" },
      },
      description = "Show what you still need to catch in the current area on the overworld.",
    },
    {
      key = "areaHudSeconds",
      label = "HUD SECONDS",
      type = "number",
      default = 4,
      min = 2,
      max = 10,
      description = "How long the area HUD stays when set to ON ENTER.",
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
    return redSegments
  end

  local function evalOpts()
    return { includeTrade = mod.options:get("includeTrade") == true }
  end

  installHud(mod, {
    Checklist = Checklist,
    Areas = Areas,
    segmentsFor = segmentsFor,
    evalOpts = evalOpts,
  })

  local function displayName(game, species)
    local def = game and game.data and game.data.pokemon and game.data.pokemon[species]
    if def and def.name then return def.name end
    return species
  end

  local function short(s, n)
    n = n or 14
    if not s then return "" end
    if #s <= n then return s end
    return s:sub(1, n)
  end

  -- ------- Start-menu checklist
  mod.content.screens:register(SCREEN, {
    new = function(game)
      local segs = segmentsFor(game)
      local status = Checklist.evaluate(segs, game, evalOpts())
      local items = {}

      if status.done then
        items[#items + 1] = { label = "VERSION COMPLETE!", right = "OK", value = "_done" }
      else
        local seg = status.segment
        items[#items + 1] = {
          label = ("NEXT: %s"):format(seg.label),
          right = ("%d/%d"):format(status.owned, status.total),
          value = "_hdr",
        }
        if seg.mapHint then
          items[#items + 1] = {
            label = short(seg.mapHint, 16),
            right = "",
            value = "_map",
          }
        end
      end

      if mod.options:get("showTips") ~= false then
        for i, tip in ipairs(status.tips or {}) do
          items[#items + 1] = {
            label = short("· " .. tip, 16),
            right = "TIP",
            value = "_tip" .. i,
          }
        end
      end

      for _, row in ipairs(status.rows or {}) do
        local name = row.id:sub(1, 1) == "_" and (row.label or row.id)
          or displayName(game, row.id)
        if row.detail then name = name .. " " .. row.detail end
        items[#items + 1] = {
          label = short(name, 14),
          right = row.ok and "OWN" or "NEED",
          value = row.id,
        }
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

  -- ------- Gates
  local function leaderKey(npc)
    local d = npc and npc.def
    if not d or not d.trainerClass then return nil end
    return tostring(d.trainerClass) .. "#" .. tostring(d.trainerParty or 1)
  end

  local function isGymOrE4(key)
    if not key then return false end
    if E4_KEYS[key] then return true end
    local ok, victories = pcall(require, "data.scripts.victories")
    if not ok or type(victories) ~= "table" then return false end
    local reward = victories[key]
    return reward and reward.badge ~= nil
  end

  local function refuseMessage(status)
    local seg = status.segment
    local left = status.total - status.owned
    return ("OAK's words echoed…\nFinish the %s list\nfirst! (%d left)"):format(
      seg and seg.label or "Oak", left)
  end

  local function softMessage(status)
    local left = status.total - status.owned
    return ("Professor Oak Challenge\n%d still needed for\n%s.\nChallenge anyway?"):format(
      left, status.segment and status.segment.label or "this part")
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
      if not key or not isGymOrE4(key) then
        return vanilla(self, npc, onDone)
      end

      local segs = segmentsFor(game)
      local opts = evalOpts()

      -- Elite Four: require Moltres (guide part 6)
      if E4_KEYS[key] then
        local status = Checklist.evaluate(segs, game, opts)
        if Checklist.owns(game, "MOLTRES") then
          return vanilla(self, npc, onDone)
        end
        -- Force moltres-oriented status if needed
        if not status.segment or not status.segment.gateEliteFour then
          status = {
            segment = { label = "MOLTRES" },
            owned = Checklist.owns(game, "MOLTRES") and 1 or 0,
            total = 1,
            missing = { "MOLTRES" },
          }
        end
        if mode == "hard" then
          game.stack:push(TextBox.new(game,
            "Catch MOLTRES in\nVictory Road before\nthe Elite Four!", function()
              if onDone then onDone() end
            end))
          return
        end
        game.stack:push(TextBox.new(game,
          "Oak Challenge:\nMOLTRES not caught.\nEnter E4 anyway?", nil, {
            choice = function(yes)
              if yes then vanilla(self, npc, onDone)
              elseif onDone then onDone() end
            end,
          }))
        return
      end

      local gate, status = Checklist.shouldGateLeader(segs, game, key, opts)
      if not gate then
        return vanilla(self, npc, onDone)
      end

      if mode == "hard" then
        game.stack:push(TextBox.new(game, refuseMessage(status), function()
          if onDone then onDone() end
        end))
        return
      end

      game.stack:push(TextBox.new(game, softMessage(status), nil, {
        choice = function(yes)
          if yes then vanilla(self, npc, onDone)
          elseif onDone then onDone() end
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

  mod.log:info("Professor Oak Challenge ready (Mewlax RB order, mode=%s)",
    tostring(mod.options:get("mode")))
end
