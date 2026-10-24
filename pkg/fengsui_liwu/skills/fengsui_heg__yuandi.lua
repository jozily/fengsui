local H = require "packages.fengsui.hegemony_util"

local yuandi = fk.CreateSkill {
  name = "fengsui_heg__yuandi",
  tags = { Skill.Compulsory },
}

local seen_player_mark = "fengsui_heg__yuandi_seen"
local xinyou_count = "fengsui_heg__xinyou_count"
local xinyou_visible = "@fengsui_heg__xinyou"
local kingdom_visible = "@fengsui_heg__yuandi"
local recorded_kingdoms = "fengsui_heg__yuandi_kingdoms"

local function updateXinyou(room, owner)
  room:setPlayerMark(owner, xinyou_visible, tostring(owner:getMark(xinyou_count)))
end

local function getFirstKingdom(room)
  local cached = room:getTag("fengsui_heg__yuandi_first_kingdom")
  if cached and cached ~= "unknown" then return cached end
  local first = room:getTag("TheFirstToShowRewarded")
  for _, p in ipairs(room.players) do
    if first == p.id or tostring(first) == tostring(p.id) then
      local kingdom = H.getKingdom(p)
      if kingdom ~= "unknown" then
        room:setTag("fengsui_heg__yuandi_first_kingdom", kingdom)
        return kingdom
      end
      break
    end
  end
  return nil
end

local function recordKingdom(room, target)
  local kingdom = H.getKingdom(target)
  if kingdom == "unknown" or kingdom == "wild" or kingdom == getFirstKingdom(room) then return end
  local tag = "fengsui_heg__yuandi_seen_" .. kingdom
  if room:getTag(tag) then return end
  room:setTag(tag, true)
  local kingdoms = room:getTag(recorded_kingdoms)
  if type(kingdoms) ~= "table" then kingdoms = {} end
  table.insertIfNeed(kingdoms, kingdom)
  room:setTag(recorded_kingdoms, kingdoms)
end

local function recordFirstKingdom(room, target)
  local kingdom = H.getKingdom(target)
  if kingdom == "unknown" or kingdom == "wild" then return end
  local tag = "fengsui_heg__yuandi_seen_" .. kingdom
  if room:getTag(tag) then return end
  room:setTag(tag, true)
  local kingdoms = room:getTag(recorded_kingdoms)
  if type(kingdoms) ~= "table" then kingdoms = {} end
  table.insertIfNeed(kingdoms, kingdom)
  room:setTag(recorded_kingdoms, kingdoms)
end

local function updateKingdomVisible(room, owner)
  if not owner:hasShownSkill(yuandi.name) then return end
  local kingdoms = {}
  local recorded = room:getTag(recorded_kingdoms)
  if type(recorded) == "table" then
    for _, kingdom in ipairs(recorded) do
      table.insertIfNeed(kingdoms, Fk:translate(kingdom))
    end
  end
  for _, target in ipairs(room.players) do
    if target:getMark("@!!vanguard") > 0 then
      local kingdom = H.getKingdom(target)
      if kingdom ~= "unknown" and kingdom ~= "wild" then
        table.insertIfNeed(kingdoms, Fk:translate(kingdom))
      end
    end
  end
  table.sort(kingdoms)
  room:setPlayerMark(owner, kingdom_visible, table.concat(kingdoms, " "))
end

yuandi:addEffect(fk.GeneralShown, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    if not (target and data and (data.m or data.d) and player:hasSkill(yuandi.name)) then return false end
    if target:getMark(seen_player_mark) > 0 then return false end
    local kingdom = H.getKingdom(target)
    return kingdom ~= "unknown" and kingdom ~= "wild" and kingdom ~= getFirstKingdom(player.room) and
      not player.room:getTag("fengsui_heg__yuandi_seen_" .. kingdom)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(target, seen_player_mark, 1)
    local first_id = room:getTag("TheFirstToShowRewarded")
    local first_player = first_id == target.id or tostring(first_id) == tostring(target.id)
    if not first_id then
      -- The mode rule may set this tag later in the same reveal event. Keep
      -- Yuandi's first-reveal exception deterministic regardless of priority.
      room:setTag("TheFirstToShowRewarded", target.id)
      first_player = true
    end
    if first_player then
      -- The first revealed role is recorded, but does not receive Yuandi's Vanguard.
      recordFirstKingdom(room, target)
    else
      recordKingdom(room, target)
      H.addHegMark(room, target, "vanguard")
    end
    updateKingdomVisible(room, player)
  end,
})

yuandi:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and data.skill and data.skill.name == "vanguard_skill&" and
      player:hasShownSkill(yuandi.name) and H.getKingdom(target) ~= "wild" and
      target:getMark("__heg_wild") == 0 and target:getMark("__heg_join_wild") == 0 and
      target:getMark("__heg_construct_wild") == 0
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(player, xinyou_count, player:getMark(xinyou_count) + 1)
    if player:hasShownSkill(yuandi.name) then updateXinyou(room, player) end
  end,
})

yuandi:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, _, target, player)
    return target == player and player:hasShownSkill(yuandi.name) and
      player:getMark(kingdom_visible) == 0
  end,
  on_refresh = function(self, _, target, player)
    updateKingdomVisible(player.room, player)
  end,
})

return yuandi
