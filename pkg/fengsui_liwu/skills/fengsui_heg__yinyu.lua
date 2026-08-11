local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__yinyu",  related_skills = {"fengsui_heg__zhue","fengsui_heg__fuzhu_xs"}, tags = { Skill.Compulsory, Skill.MainPlace } }

s:addEffect(fk.GeneralShown, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and player:getMark(s.name) == 0 and
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
    local deputy = Fk.generals[player.deputyGeneral]
    if deputy and deputy.kingdom == "shu" and string.find(player.deputyGeneral, "xushu", 1, true) then
      local place = H.inGeneralSkills(player, s.name)
      if place == "m" then
        local deputyName = player.deputyGeneral
        H.removeGeneral(player, false)
        if player:isAlive() then
          room:setPlayerProperty(player, "general", deputyName)
          room:setPlayerProperty(player, "deputyGeneral", "blank_shibing")
          room:setPlayerMark(player, "__heg_general", deputyName)
          room:setPlayerMark(player, "__heg_deputy", "blank_shibing")
          room:handleAddLoseSkills(player, table.concat(deputy:getSkillNameList(), "|"), nil, true, false)
          if table.contains(deputy:getSkillNameList(), "ld__jujian") then
            room:handleAddLoseSkills(player, "ld__jujian", nil, true, false)
          end
          player:filterHandcards()
        end
      elseif place == "d" then
        H.removeGeneral(player, true)
      end
    end
  end,
})

return s
