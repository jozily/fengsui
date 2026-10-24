local H = require "packages.fengsui.hegemony_util"

local yuandi = fk.CreateSkill {
  name = "fengsui_heg__yuandi",
  tags = { Skill.Compulsory },
}

local seen_player_mark = "fengsui_heg__yuandi_seen"
local xinyou_count = "fengsui_heg__xinyou_count"
local xinyou_visible = "@fengsui_heg__xinyou"
local kingdom_visible = "@fengsui_heg__yuandi"

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

local function grantVanguardForKingdom(room, target)
  local kingdom = H.getKingdom(target)
  if kingdom == "unknown" or kingdom == "wild" or kingdom == getFirstKingdom(room) then return end
  local tag = "fengsui_heg__yuandi_seen_" .. kingdom
  if room:getTag(tag) then return end
  room:setTag(tag, true)
  H.addHegMark(room, target, "vanguard", 1)
end

local function updateKingdomVisible(room, owner)
  if not owner:hasShownSkill(yuandi.name) then return end
  local kingdoms = {}
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
    grantVanguardForKingdom(room, target)
    updateKingdomVisible(room, player)
  end,
})

yuandi:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and data.skill and data.skill.name == "vanguard_skill&" and
      player:hasShownSkill(yuandi.name) and H.getKingdom(target) ~= "wild"
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
