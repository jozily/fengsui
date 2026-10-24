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
  room:setPlayerMark(owner, xinyou_visible, "心幽 " .. tostring(owner:getMark(xinyou_count)))
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
      local kingdom = H.getKingdom(target)
      if kingdom ~= "unknown" and not room:getTag("fengsui_heg__yuandi_seen_" .. kingdom) then
        room:setTag("fengsui_heg__yuandi_seen_" .. kingdom, true)
        H.addHegMark(room, target, "vanguard", 1)
      end
    end
  end,
})

yuandi:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and data.skill and data.skill.name == "vanguard_skill&" and
      player:hasShownSkill(yuandi.name)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
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
    player.room:setPlayerMark(player, kingdom_visible, "元嫡 " .. Fk:translate(H.getKingdom(player)))
  end,
})

return yuandi
