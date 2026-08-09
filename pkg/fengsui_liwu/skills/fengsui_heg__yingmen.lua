local U = require "packages.utility.utility"

local s = fk.CreateSkill { name = "fengsui_heg__yingmen", tags = { Skill.Compulsory } }

local function kingdomCount(room)
  local kingdoms = {}
  for _, p in ipairs(room.alive_players) do
    if p.kingdom ~= "unknown" and p.kingdom ~= "fengsui_neutral" and p.kingdom ~= "fengsui_neutralall" then
      table.insertIfNeed(kingdoms, p.kingdom)
    end
  end
  return math.max(1, #kingdoms)
end

local function eligibleSkill(skill)
  if not skill then return false end
  local tags = skill.tags or {}
  return #tags == 0 or (#tags == 1 and skill:hasTag(Skill.Compulsory))
end

local function attachSkill(room, player, skill)
  player:addFakeSkill(skill)
  local skills = { skill }
  table.insertTable(skills, skill.related_skills or {})
  for _, related in ipairs(skills) do
    if related:isInstanceOf(TriggerSkill) then room.logic:addTriggerSkill(related) end
  end
end

local function detachSkill(room, player, skillName)
  room:removeTableMark(player, "fengsui_heg__fangke_skills", skillName)
  player:loseFakeSkill(Fk.skills[skillName])
end

local function addVisitor(room, player, generalName)
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  table.insertIfNeed(visitors, generalName)
  U.setPrivateMark(player, "&fengsui_heg__fangke", visitors)
  for _, skillName in ipairs(Fk.generals[generalName]:getSkillNameList()) do
    local skill = Fk.skills[skillName]
    if eligibleSkill(skill) then
      attachSkill(room, player, skill)
      room:addTableMark(player, "fengsui_heg__fangke_skills", skillName)
    end
  end
end

local function fillVisitors(room, player)
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  local need = kingdomCount(room) - #visitors
  if need <= 0 then return end
  local selectedKingdoms = {}
  for _, name in ipairs(visitors) do
    local general = Fk.generals[name]
    if general then table.insertIfNeed(selectedKingdoms, general.kingdom) end
  end
  for _ = 1, need do
    local generals = room:findGenerals(function(general)
      if table.contains(visitors, general.name) then return false end
      if table.contains(selectedKingdoms, general.kingdom) then return false end
      return table.find(general:getSkillNameList(), function(name) return eligibleSkill(Fk.skills[name]) end) ~= nil
    end, 1)
    if #generals == 0 then break end
    local name = generals[1]
    addVisitor(room, player, name)
    table.insertIfNeed(visitors, name)
    local general = Fk.generals[name]
    if general then table.insertIfNeed(selectedKingdoms, general.kingdom) end
  end
end


local function clearVisitors(room, player)
  local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
  local skillNames = player:getTableMark("fengsui_heg__fangke_skills")
  for _, skillName in ipairs(skillNames) do
    detachSkill(room, player, skillName)
  end
  room:returnToGeneralPile(visitors)
  room:setPlayerMark(player, "@[private]&fengsui_heg__fangke", 0)
  room:setPlayerMark(player, "fengsui_heg__fangke_skills", 0)
end

s:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and player:getMark(s.name .. "_shown") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, s.name .. "_shown", 1)
    fillVisitors(player.room, player)
  end,
})

s:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(s.name)
  end,
  on_use = function(self, event, target, player, data) fillVisitors(player.room, player) end,
})

s:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name)
  end,
  on_use = function(self, event, target, player, data) fillVisitors(player.room, player) end,
  on_lose = function(self, player)
    clearVisitors(player.room, player)
  end,
})

return s
