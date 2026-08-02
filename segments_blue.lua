-- Blue exclusives over Mewlax RB Oak Guide Red table.
return function(redSegments)
  local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = deepCopy(v) end
    return out
  end

  local function replace(list, removeSet, addList)
    local out, seen = {}, {}
    for _, s in ipairs(list or {}) do
      if not removeSet[s] and not seen[s] then
        out[#out + 1] = s
        seen[s] = true
      end
    end
    for _, s in ipairs(addList or {}) do
      if not seen[s] then
        out[#out + 1] = s
        seen[s] = true
      end
    end
    return out
  end

  local segs = deepCopy(redSegments)
  for _, seg in ipairs(segs) do
    if seg.id == "misty" then
      -- Red: Ekans, Oddish, Mankey → Blue: Sandshrew, Bellsprout, Meowth
      seg.add = replace(seg.add,
        {
          EKANS = true, ARBOK = true,
          ODDISH = true, GLOOM = true,
          MANKEY = true, PRIMEAPE = true,
        },
        {
          "SANDSHREW", "SANDSLASH",
          "BELLSPROUT", "WEEPINBELL",
          "MEOWTH", "PERSIAN",
        })
    elseif seg.id == "koga" then
      -- Red: Growlithe/Arcanine, Cubone/Marowak, Scyther, Vileplume
      -- Blue: Vulpix/Ninetales, Pinsir, Victreebel (no Cubone in tower on Blue? Cubone is both)
      -- Guide: Cubone in tower for both; Magmar is Blue mansion later
      seg.add = replace(seg.add,
        {
          GROWLITHE = true, ARCANINE = true,
          SCYTHER = true,
          VILEPLUME = true,
        },
        {
          "VULPIX", "NINETALES",
          "VICTREEBEL",
          "PINSIR",
        })
      -- Leaf stone for Weepinbell→Victreebel already in tips via Celadon
    elseif seg.id == "erika" then
      seg.add = replace(seg.add,
        { ELECTABUZZ = true },
        { "MAGMAR" })
    end
  end
  return segs
end
