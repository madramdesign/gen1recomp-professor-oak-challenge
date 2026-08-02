-- Blue exclusives patch over the Red segment table.
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
    if seg.id == "brock" then
      seg.add = replace(seg.add,
        { MANKEY = true, PRIMEAPE = true },
        { "EKANS", "ARBOK" })
    elseif seg.id == "misty" then
      seg.add = replace(seg.add,
        { SANDSHREW = true, SANDSLASH = true },
        { "ODDISH", "GLOOM", "VILEPLUME" })
    elseif seg.id == "surge" then
      seg.add = replace(seg.add,
        {
          BELLSPROUT = true, WEEPINBELL = true, VICTREEBEL = true,
          GROWLITHE = true, ARCANINE = true,
        },
        { "MEOWTH", "PERSIAN", "ODDISH", "GLOOM", "VILEPLUME" })
    elseif seg.id == "erika" then
      seg.add = replace(seg.add,
        {
          CUBONE = true, MAROWAK = true,
          SCYTHER = true,
          GROWLITHE = true, ARCANINE = true,
        },
        { "PINSIR", "EKANS", "ARBOK" })
    elseif seg.id == "koga" then
      seg.add = replace(seg.add, { SCYTHER = true }, { "PINSIR" })
    end
  end
  return segs
end
