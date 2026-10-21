local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__yinyu",  related_skills = {"fengsui_heg__zhue","fengsui_heg__fuzhu_xs"}, tags = { Skill.Compulsory, Skill.MainPlace } }

s:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    local place = H.inGeneralSkills(player, s.name)
    return target == player and player:hasShownSkill(s.name) and player:getMark(s.name) == 0 and
      place ~= nil and data and ((place == "m" and data.m) or (place == "d" and data.d)) and
      player.kingdom ~= "unknown" and player.kingdom ~= "fengsui_neutral" and player.kingdom ~= "fengsui_neutralall"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, s.name, 1)
    if player.kingdom == "qun" then
      room:handleAddLoseSkills(player, "fengsui_heg__zhue")
    elseif player.kingdom == "shu" then
      room:handleAddLoseSkills(player, "fengsui_heg__fuzhu_xs")
    end

  end,
})

return s
