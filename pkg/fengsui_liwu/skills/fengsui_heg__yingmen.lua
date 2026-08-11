local U = require "packages.utility.utility"
local FU = require "packages.fengsui.pkg.fengsui_liwu.util"

local s = fk.CreateSkill { name = "fengsui_heg__yingmen", tags = { Skill.Compulsory } }
local XUSHAO = "fengsui_heg__xushao"
local INITIALIZED_MARK = "fengsui_heg__yingmen_initialized"

local function kingdomCount(room)
  local kingdoms = {}
  for _, p in ipairs(room.alive_players) do
    if p.kingdom ~= "unknown" and p.kingdom ~= "fengsui_neutral" and p.kingdom ~= "fengsui_neutralall" then
      table.insertIfNeed(kingdoms, p.kingdom)
    end
  end
  return math.max(1, #kingdoms)
end

local function getXushaoPlace(player)
  return FU.getGeneralPlace(player, XUSHAO)
end

local function xushaoRevealed(player)
  local isDeputy = getXushaoPlace(player)
  if isDeputy == nil then return false end
  return isDeputy and player.deputyGeneral == XUSHAO or not isDeputy and player.general == XUSHAO
end

local function eligibleSkill(skill, isDeputy)
  if not skill then return false end
  if isDeputy == nil then return false end
  if skill:hasTag(Skill.MainPlace) and isDeputy then return false end
  if skill:hasTag(Skill.DeputyPlace) and not isDeputy then return false end
  return not skill:hasTag(Skill.Limited)
end

local function attachSkill(room, player, skill)
  player:addFakeSkill(skill)
  local skills = { skill }
  table.insertTable(skills, skill.related_skills or {})
  for _, related in ipairs(skills) do
    if related:isInstanceOf(TriggerSkill) then room.logic:addTriggerSkill(related) end
  end
end

local function addVisitor(room, player, generalName)
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  table.insertIfNeed(visitors, generalName)
  U.setPrivateMark(player, "&fengsui_heg__fangke", visitors)
  local isDeputy = getXushaoPlace(player)
  for _, skillName in ipairs(Fk.generals[generalName]:getSkillNameList()) do
    local skill = Fk.skills[skillName]
    if eligibleSkill(skill, isDeputy) then
      attachSkill(room, player, skill)
      room:addTableMark(player, "fengsui_heg__fangke_skills", skillName)
    end
  end
end

local function fillVisitors(room, player)
  local isDeputy = getXushaoPlace(player)
  if not xushaoRevealed(player) then return end
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  local need = kingdomCount(room) - #visitors
  if need <= 0 then return end
  local selectedKingdoms = {}
  for _, name in ipairs(visitors) do
    local general = Fk.generals[name]
    if general then table.insertIfNeed(selectedKingdoms, general.kingdom) end
  end
  for _ = 1, need do
    local generals = room:findGenerals(function(generalName)
      local general = Fk.generals[generalName]
      if not general then return false end
      if table.contains(visitors, generalName) then return false end
      if table.contains(selectedKingdoms, general.kingdom) then return false end
      return table.find(general:getSkillNameList(), function(name)
        return eligibleSkill(Fk.skills[name], isDeputy)
      end) ~= nil
    end, 1)
    if #generals == 0 then break end
    local name = generals[1]
    addVisitor(room, player, name)
    table.insertIfNeed(visitors, name)
    local general = Fk.generals[name]
    if general then table.insertIfNeed(selectedKingdoms, general.kingdom) end
  end
end

local function detachVisitorSkills(room, player)
  local skillNames = player:getTableMark("fengsui_heg__fangke_skills")
  for _, skillName in ipairs(skillNames) do
    player:loseFakeSkill(Fk.skills[skillName])
  end
  room:setPlayerMark(player, "fengsui_heg__fangke_skills", 0)
end

local function attachVisitorSkills(room, player)
  local isDeputy = getXushaoPlace(player)
  if isDeputy == nil then return end
  for _, generalName in ipairs(U.getPrivateMark(player, "&fengsui_heg__fangke")) do
    local general = Fk.generals[generalName]
    if general then
      for _, skillName in ipairs(general:getSkillNameList()) do
        local skill = Fk.skills[skillName]
        if eligibleSkill(skill, isDeputy) and
          not table.contains(player:getTableMark("fengsui_heg__fangke_skills"), skillName) then
          attachSkill(room, player, skill)
          room:addTableMark(player, "fengsui_heg__fangke_skills", skillName)
        end
      end
    end
  end
end

local function syncVisitorSkills(room, player)
  detachVisitorSkills(room, player)
  attachVisitorSkills(room, player)
end


local function clearVisitors(room, player)
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  detachVisitorSkills(room, player)
  room:returnToGeneralPile(visitors)
  room:setPlayerMark(player, "@[private]&fengsui_heg__fangke", 0)
  room:setPlayerMark(player, "fengsui_heg__fangke_skills", 0)
end

s:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.m == XUSHAO or data.d == XUSHAO) and player:hasSkill(s.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(INITIALIZED_MARK) == 0 then
      room:setPlayerMark(player, INITIALIZED_MARK, 1)
      fillVisitors(room, player)
    else
      attachVisitorSkills(room, player)
    end
  end,
})

s:addEffect(fk.GeneralHidden, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and data == XUSHAO and
      (#player:getTableMark("fengsui_heg__fangke_skills") > 0 or
        #U.getPrivateMark(player, "&fengsui_heg__fangke") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    clearVisitors(player.room, player)
  end,
})

s:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and xushaoRevealed(player) and player:hasSkill(s.name)
  end,
  on_use = function(self, event, target, player, data) fillVisitors(player.room, player) end,
})

s:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and xushaoRevealed(player) and player:hasSkill(s.name)
  end,
  on_use = function(self, event, target, player, data)
    syncVisitorSkills(player.room, player)
    fillVisitors(player.room, player)
  end,
  on_lose = function(self, player)
    clearVisitors(player.room, player)
  end,
})

s:addTest(function(room, me)
  lu.assertTrue(eligibleSkill(Fk.skills["fengsui_heg__yinbing"], false))
  lu.assertFalse(eligibleSkill(Fk.skills["fengsui_heg__yinbing"], true))
  lu.assertTrue(eligibleSkill(Fk.skills["fengsui_heg__yuandao"], true))
  lu.assertFalse(eligibleSkill(Fk.skills["fengsui_heg__yuandao"], false))
  lu.assertFalse(eligibleSkill(Fk.skills["fengsui_heg__baoguo"], false))

  local translations = require "packages.fengsui.pkg.fengsui_liwu.option_translations"
  for key in pairs(translations) do
    lu.assertNotEquals(Fk:translate(key), key)
  end

  FkTest.runInRoom(function()
    room:changeHero(me, XUSHAO, false, false, true, false, false)
    room:setPlayerProperty(me, "kingdom", "wei")
    room:setPlayerProperty(room.players[2], "kingdom", "shu")
    fillVisitors(room, me)
  end)

  local visitors = U.getPrivateMark(me, "&fengsui_heg__fangke")
  lu.assertTrue(#visitors > 0)

  FkTest.runInRoom(function()
    clearVisitors(room, me)
  end)
end)

return s
