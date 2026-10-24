local H = require "packages.fengsui.hegemony_util"

local yuandi = fk.CreateSkill {
  name = "fengsui_heg__yuandi",
  tags = { Skill.Compulsory },
}

local seen_player_mark = "fengsui_heg__yuandi_seen"
local granted_mark = "fengsui_heg__yuandi_granted"
local xinyou_count = "fengsui_heg__xinyou_count"
local xinyou_visible = "@fengsui_heg__xinyou"
local kingdom_visible = "@fengsui_heg__yuandi"

local function updateXinyou(room, owner)
  room:setPlayerMark(owner, xinyou_visible, tostring(owner:getMark(xinyou_count)))
end

local function isFirstShown(room, target)
  local first = room:getTag("TheFirstToShowRewarded")
  return first == target.id or tostring(first) == tostring(target.id)
end

local function grantVanguardForKingdom(room, target)
  local kingdom = H.getKingdom(target)
  if kingdom == "unknown" or isFirstShown(room, target) then return end
  local tag = "fengsui_heg__yuandi_seen_" .. kingdom
  if room:getTag(tag) then return end
  room:setTag(tag, true)
  H.addHegMark(room, target, "vanguard", 1)
  room:setPlayerMark(target, granted_mark, target:getMark(granted_mark) + 1)
end

local function refreshVanguardTargets(room)
  for _, target in ipairs(room.alive_players) do
    if target.general ~= "anjiang" or target.deputyGeneral ~= "anjiang" then
      grantVanguardForKingdom(room, target)
    end
  end
end

yuandi:addEffect(fk.GeneralShown, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and (data.m or data.d) and player:hasShownSkill(yuandi.name)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    if target:getMark(seen_player_mark) == 0 then
      room:setPlayerMark(target, seen_player_mark, 1)
      grantVanguardForKingdom(room, target)
    end
  end,
})

yuandi:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and data.skill and data.skill.name == "vanguard_skill&" and
      player:hasShownSkill(yuandi.name) and target:getMark(granted_mark) > 0
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(target, granted_mark, target:getMark(granted_mark) - 1)
    room:setPlayerMark(player, xinyou_count, player:getMark(xinyou_count) + 1)
    updateXinyou(room, player)
  end,
})

yuandi:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, _, target, player)
    return target == player and player:hasShownSkill(yuandi.name) and
      player:getMark(kingdom_visible) == 0 and H.getKingdom(player) ~= "unknown"
  end,
  on_refresh = function(self, _, target, player)
    player.room:setPlayerMark(player, kingdom_visible, Fk:translate(H.getKingdom(player)))
    refreshVanguardTargets(player.room)
  end,
})

return yuandi
