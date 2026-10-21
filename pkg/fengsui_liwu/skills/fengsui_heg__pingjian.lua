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
  return general and general.kingdom ~= "wild" and general.kingdom ~= "fengsui_neutral" and
    general.kingdom ~= "fengsui_neutralall" and table.contains(general:getSkillNameList(), skillName) and
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

local function hasSkillMark(player, skillName)
  for _, markName in ipairs(player:getMarkNames()) do
    if markName == skillName or markName:startsWith(skillName .. "-") or markName:startsWith(skillName .. "_") then
      local value = player:getMark(markName)
      if (type(value) == "number" and value ~= 0) or (type(value) == "table" and #value > 0) then return true end
    end
  end
  return false
end

local function flushPending(room, player)
  local pending = player:getTableMark("fengsui_heg__fangke_pending")
  if #pending == 0 then return end
  local keep = {}
  for _, item in ipairs(pending) do
    local generalName = item.general or item
    local skillName = item.skill
    if skillName and hasSkillMark(player, skillName) then
      table.insert(keep, item)
    else
      removeVisitor(room, player, generalName, skillName)
    end
  end
  room:setPlayerMark(player, "fengsui_heg__fangke_pending", keep)
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
    player.room:addTableMark(player, "fengsui_heg__fangke_pending", { general = choice, skill = skillName })
  end,
})

-- 访客技能若留下了本技能的临时标记，等标记对应的后续效果结束后再移除访客。
s:addEffect(fk.EventPhaseStart, {
  global = true,
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Start and #player:getTableMark("fengsui_heg__fangke_pending") > 0
  end,
  on_use = function(self, event, target, player) flushPending(player.room, player) end,
})
s:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player)
    return target == player and #player:getTableMark("fengsui_heg__fangke_pending") > 0
  end,
  on_use = function(self, event, target, player) flushPending(player.room, player) end,
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
