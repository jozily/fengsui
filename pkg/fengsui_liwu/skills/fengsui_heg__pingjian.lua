local H = require "packages.fengsui.hegemony_util"
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
  if FU.isGeneralStateSkill(skill) then return false end
  return not (skill:hasTag(Skill.MainPlace) and isDeputy) and
    not (skill:hasTag(Skill.DeputyPlace) and not isDeputy)
end

local function chooseVisitor(player, choices, prompt)
  if #choices == 0 then return nil end
  if #choices == 1 then return choices[1] end
  local selected = U.askToChooseGeneralsAndChoice(player, {
    generals = choices,
    all_generals = choices,
    min_num = 1,
    max_num = 1,
    skill_name = s.name,
    prompt = prompt,
    cancelable = false,
  })
  return selected[1]
end

local function visitorProvidesSkill(player, generalName, skillName)
  local general = Fk.generals[generalName]
  return general and general.kingdom ~= "wild" and general.kingdom ~= "fengsui_neutral_old" and
    general.kingdom ~= "fengsui_neutral" and table.contains(general:getSkillNameList(), skillName) and
    skillMatchesXushaoPlace(player, skillName)
end

local function removeVisitor(room, player, generalName)
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
      local skill = Fk.skills[skillName]
      if skill then
        player:prelightSkill(skill, false)
        player:loseFakeSkill(skill)
      end
    end
  end
end

local function clearVisitors(room, player)
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  if #visitors > 0 then room:returnToGeneralPile(visitors) end
  room:setPlayerMark(player, "@[private]&fengsui_heg__fangke", 0)
  local granted = player:getTableMark("fengsui_heg__fangke_skills")
  for _, skillName in ipairs(granted) do
    local skill = Fk.skills[skillName]
    if skill then
      player:prelightSkill(skill, false)
      player:loseFakeSkill(skill)
    end
  end
  room:setPlayerMark(player, "fengsui_heg__fangke_skills", 0)
end

s:addEffect(H.GeneralTransformed, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data and data.origName == XUSHAO
  end,
  on_use = function(self, event, target, player, data)
    clearVisitors(player.room, player)
    player.room:setPlayerMark(player, "@fengsui_neutral", 0)
    player.room:setPlayerMark(player, "@fengsui_neutral_old", 0)
  end,
})

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
    local choice = chooseVisitor(player, choices, "#fengsui_heg__pingjian-remove")
    local removeChoices = { "fengsui_heg__pingjian_remove_used" }
    if #visitors > 1 then
      table.insert(removeChoices, "fengsui_heg__pingjian_remove_other")
    end
    local removeChoice = #removeChoices == 1 and removeChoices[1] or player.room:askToChoice(player, {
      choices = removeChoices,
      skill_name = s.name,
      prompt = "#fengsui_heg__pingjian-choice",
    })
    if removeChoice == "fengsui_heg__pingjian_remove_used" then
      local general = Fk.generals[choice]
      local sameKingdom = general and
        (general.kingdom == player.kingdom or general.subkingdom == player.kingdom)
      removeVisitor(player.room, player, choice)
      player:drawCards(sameKingdom and 2 or 1, s.name)
    else
      local otherChoices = table.filter(visitors, function(name) return name ~= choice end)
      if #otherChoices > 0 then
        local other = chooseVisitor(player, otherChoices, "#fengsui_heg__pingjian-other")
        removeVisitor(player.room, player, other)
      end
    end
  end,
})

s:addTest(function(room, me)
  FkTest.runInRoom(function()
    room:changeHero(me, XUSHAO, false, false, true, false, false)
  end)
  lu.assertFalse(skillMatchesXushaoPlace(me, "fengsui_heg__yinbing"))
  lu.assertTrue(skillMatchesXushaoPlace(me, "fengsui_heg__jianhe"))
  lu.assertTrue(skillMatchesXushaoPlace(me, "fengsui_heg__yuandao"))
end)

return s
