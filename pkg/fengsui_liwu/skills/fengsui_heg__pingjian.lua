local U = require "packages.utility.utility"
local FU = require "packages.fengsui.pkg.fengsui_liwu.util"

local s = fk.CreateSkill { name = "fengsui_heg__pingjian" }
local XUSHAO = "fengsui_heg__xushao"

local function getXushaoPlace(player)
  return FU.getGeneralPlace(player, XUSHAO)
end

local function xushaoRevealed(player)
  local isDeputy = getXushaoPlace(player)
  if isDeputy == nil then return false end
  return isDeputy and player.deputyGeneral == XUSHAO or not isDeputy and player.general == XUSHAO
end

local function skillMatchesXushaoPlace(player, skillName)
  local skill = Fk.skills[skillName]
  local isDeputy = getXushaoPlace(player)
  if not skill or isDeputy == nil then return false end
  return not (skill:hasTag(Skill.MainPlace) and isDeputy) and
    not (skill:hasTag(Skill.DeputyPlace) and not isDeputy)
end

local function visitorProvidesSkill(player, generalName, skillName)
  local general = Fk.generals[generalName]
  return general and table.contains(general:getSkillNameList(), skillName) and
    skillMatchesXushaoPlace(player, skillName)
end

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
      return visitorProvidesSkill(player, name, skillName)
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
    return target == player and xushaoRevealed(player) and player:hasSkill(s.name) and data.skill and
      table.contains(player:getTableMark("fengsui_heg__fangke_skills"), data.skill:getSkeleton().name)
  end,
  on_cost = function()
    return true
  end,
  on_use = function(self, event, target, player, data)
    local skillName = data.skill:getSkeleton().name
    local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
    local choices = table.filter(visitors, function(name)
      return visitorProvidesSkill(player, name, skillName)
    end)
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or player.room:askToChoice(player, {
      choices = choices, skill_name = s.name, prompt = "#fengsui_heg__pingjian-remove",
    })
    removeVisitor(player.room, player, choice, skillName)
  end,
})

s:addTest(function(room, me)
  FkTest.runInRoom(function()
    room:changeHero(me, XUSHAO, false, false, true, false, false)
  end)
  lu.assertTrue(skillMatchesXushaoPlace(me, "fengsui_heg__yinbing"))
  lu.assertFalse(skillMatchesXushaoPlace(me, "fengsui_heg__yuandao"))
end)

return s
