local U = require "packages.utility.utility"

local s = fk.CreateSkill { name = "fengsui_heg__pingjian" }

local function removeVisitor(room, player, generalName, usedSkill)
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  if not table.removeOne(visitors, generalName) then return end
  if #visitors == 0 then
    room:setPlayerMark(player, "@[private]&fengsui_heg__fangke", 0)
  else
    U.setPrivateMark(player, "&fengsui_heg__fangke", visitors)
  end
  room:returnToGeneralPile({ generalName })
  local general = Fk.generals[generalName]
  for _, skillName in ipairs(general:getSkillNameList()) do
    local stillProvided = table.find(visitors, function(name)
      return table.contains(Fk.generals[name]:getSkillNameList(), skillName)
    end)
    if not stillProvided then
      room:removeTableMark(player, "fengsui_heg__fangke_skills", skillName)
      player:loseFakeSkill(Fk.skills[skillName])
    end
  end
  local sameKingdom = general.kingdom == player.kingdom or general.subkingdom == player.kingdom
  player:drawCards(sameKingdom and 2 or 1, s.name)
end

s:addEffect(fk.AfterSkillEffect, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and data.skill and
      table.contains(player:getTableMark("fengsui_heg__fangke_skills"), data.skill:getSkeleton().name)
  end,
  on_use = function(self, event, target, player, data)
    local skillName = data.skill:getSkeleton().name
    local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
    local choices = table.filter(visitors, function(name)
      return table.contains(Fk.generals[name]:getSkillNameList(), skillName)
    end)
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or player.room:askToChoice(player, {
      choices = choices, skill_name = s.name, prompt = "#fengsui_heg__pingjian-remove",
    })
    removeVisitor(player.room, player, choice, skillName)
  end,
})

return s
