local Liwu = require "packages.fengsui.pkg.fengsui_liwu.liwu_util"
local H = require "packages.fengsui.hegemony_util"

local neutralRule = fk.CreateSkill {
  name = "#fengsui_neutral_rule",
  mute = true,
  no_indicate = true,
}

local neutralKingdom = "fengsui_neutral_old"
local neutralAllKingdom = "fengsui_neutral"

local function otherPlace(place)
  return place == "m" and "d" or "m"
end

local function getNeutralPlace(player)
  local main = Fk.generals[player:getMark("__heg_general")]
  if main and (main.kingdom == Liwu.kingdom or main.kingdom == Liwu.legacyKingdom) then return "m" end
  local deputy = Fk.generals[player:getMark("__heg_deputy")]
  if deputy and (deputy.kingdom == Liwu.kingdom or deputy.kingdom == Liwu.legacyKingdom) then return "d" end
end

local function clearRevealProhibition(room, player)
  room:setPlayerMark(player, "fengsui_neutral_reveal_place", 0)
  room:setPlayerMark(player, "fengsui_neutral_reveal_round", 0)
  room:setPlayerMark(player, "fengsui_neutral_old_reveal_place", 0)
  room:setPlayerMark(player, "fengsui_neutral_old_reveal_round", 0)
  room:setPlayerMark(player, "@fengsui_neutral", 0)
  room:setPlayerMark(player, "@fengsui_neutral_old", 0)
  room:setPlayerMark(player, MarkEnum.RevealProhibited .. "-fengsui", 0)
end

local function loseNeutralSkills(room, player)
  local skills = table.filter(Liwu.neutralSkills, function(skillName)
    return player:hasSkill(skillName, true, true)
  end)
  if #skills > 0 then
    room:handleAddLoseSkills(player, "-" .. table.concat(skills, "|-"), nil, false, true)
  end
end

local function shownGeneralKingdom(player, data)
  local generalName = data.m or data.d
  local general = generalName and Fk.generals[generalName]
  return general and general.kingdom
end

local function warlordsEnabled(room)
  local value = room:getSettings("fengsui_warlords")
  return value == true or value == 1 or value == "1" or value == "true"
end

local function promoteWarlord(room, player, kingdom)
  if not warlordsEnabled(room) or not kingdom or kingdom == "unknown" or kingdom == "wild" then return false end
  local sameKingdom = 0
  for _, other in ipairs(room.alive_players) do
    if other ~= player and other.kingdom == kingdom then sameKingdom = sameKingdom + 1 end
  end
  -- 按用户规则：达到三分之一后，下一名加入该势力的角色成为野心家。
  if sameKingdom >= math.ceil(#room.players / 3) then
    room:setPlayerMark(player, "__heg_wild", 1)
    room:setPlayerProperty(player, "kingdom", "wild")
    room:setPlayerProperty(player, "role", "wild")
    room:sendLog{
      type = "#FengsuiWarlordsPromote",
      from = player.id,
    }
    return true
  end
  return false
end


local function determineKingdom(room, player)
  local kingdom = player:getMark("__heg_kingdom")
  if type(kingdom) ~= "string" or kingdom == "" or kingdom == Liwu.legacyKingdom then return end
  if promoteWarlord(room, player, kingdom) then
    clearRevealProhibition(room, player)
    loseNeutralSkills(room, player)
    return
  end
  room:setPlayerProperty(player, "kingdom", kingdom)
  room:setPlayerProperty(player, "role", kingdom)
  clearRevealProhibition(room, player)
  loseNeutralSkills(room, player)
end

local function makeFourthKingdomWild(room, player, oldKingdom)
  if oldKingdom ~= "unknown" or player.kingdom == "wild" then return end
  local kingdoms = {}
  for _, p in ipairs(room.alive_players) do
    local k = p.kingdom
    if k ~= "unknown" and k ~= neutralKingdom and k ~= neutralAllKingdom then
      table.insertIfNeed(kingdoms, k)
    end
  end
  if #kingdoms >= 4 then
    room:setPlayerMark(player, "__heg_wild", 1)
    room:setPlayerProperty(player, "kingdom", "wild")
    room:setPlayerProperty(player, "role", "wild")
  end
end

-- 本技能只做势力判定与标记维护，属纯事务性动作，不该走技能发动流程：
-- 走 on_trigger 而不是 on_cost/on_use，否则明置、换将时会弹出
-- 「你想发动〖屹立于世〗吗？」，日志里还会多出一条技能播报。
local function applyNeutralRule(player, data)
  local room = player and player.room
  if not room then return end
  local revealedKingdom = player.kingdom
  if revealedKingdom ~= "unknown" and revealedKingdom ~= "wild" then
    promoteWarlord(room, player, revealedKingdom)
  end
  local neutralPlace = getNeutralPlace(player)
  local shownPlace = data.m and "m" or (data.d and "d")
  local firstNeutral = shownPlace == neutralPlace and
    ((shownPlace == "m" and player.deputyGeneral == "anjiang") or
     (shownPlace == "d" and player.general == "anjiang")) and
    not (data.m and data.d)
  if firstNeutral then
    room:setPlayerProperty(player, "kingdom", "unknown")
    room:setPlayerProperty(player, "role", "hidden")
    room:setPlayerMark(player, "@fengsui_neutral", "")
  else
    -- 先亮正常势力牌或同时亮两张时，不触发中立特效，
    -- 但仍按正常势力确定当前角色势力。
    local oldKingdom = player.kingdom
    room:setPlayerMark(player, "@fengsui_neutral", 0)
    room:setPlayerMark(player, "@fengsui_neutral_old", 0)
    -- ServerPlayer:revealGeneral 会先按国战规则检查人数上限；
    -- 如果该角色已被判为野心家，这里不能再把它覆盖回原势力。
    if oldKingdom == "wild" then
      room:setPlayerMark(player, "__heg_wild", 1)
      room:setPlayerProperty(player, "kingdom", "wild")
      room:setPlayerProperty(player, "role", player:getMark("__heg_kingdom"))
    else
      determineKingdom(room, player)
      makeFourthKingdomWild(room, player, oldKingdom)
    end
  end
end

neutralRule:addEffect(fk.GeneralShown, {
  global = true,
  priority = 20,
  can_trigger = function(self, event, target, player, data)
    return target == player and getNeutralPlace(player) ~= nil and data ~= nil
  end,
  on_trigger = function(self, event, target, player, data)
    applyNeutralRule(target, data)
  end,
})

-- 群雄割据：普通势力武将（不涉及中立者的组合）首次亮将确定势力时，同样按 1/3 人数上限转野心家。
-- 核心 revealGeneral 的人数上限固定是总人数的一半（普通国战规则），这里在亮将时机补判三分之一。
-- 判定逻辑：每名角色整局只判一次（挂 judged 记号）。
-- 不能只挂 fk.GeneralShown：全部明置（ServerPlayer:revealGenerals）走 no_trigger
-- 路径，不触发 GeneralShown 只补发 GeneralRevealed——漏挂会让"一次亮两张"的
-- 角色整场绕过 1/3 判定（六人局因此可出现三个同势力不变野）。
local judgedMark = "fengsui_warlords_judged"
local function warlordsCanTrigger(self, event, target, player, data)
  if target ~= player or not player.room then return false end
  if not warlordsEnabled(player.room) then return false end
  if getNeutralPlace(player) ~= nil then return false end
  if player.dead then return false end
  if player:getMark(judgedMark) ~= 0 then return false end
  local kingdom = player.kingdom
  if not kingdom or kingdom == "unknown" or kingdom == "wild" or
    kingdom == neutralKingdom or kingdom == neutralAllKingdom then return false end
  return true
end

local function warlordsOnUse(self, event, target, player, data)
  player.room:setPlayerMark(player, judgedMark, 1)
  promoteWarlord(player.room, player, player.kingdom)
end

-- 群雄割据单独注册为另一个全局技能，避免普通势力亮将时在日志中显示
-- 中立者专属的“屹立于世”。
neutralRule.warlordsCanTrigger = warlordsCanTrigger
neutralRule.warlordsOnUse = warlordsOnUse

-- 兜底：包装 ServerPlayer.revealGeneral，让任何亮将路径完成后都执行 1/3 判定。
-- 仅挂事件不够——no_trigger 亮将（全部明置 revealGenerals、变身流程
-- hegemony_util.transformGeneral / 兼友等）不触发 GeneralShown/GeneralRevealed，
-- 会整场绕过判定。包装后正常路径由 judged 记号去重，不会二次判定。
-- 注意：ServerPlayer 全局要到 lua/server/scheduler.lua 加载时才存在，
-- 包加载阶段通常为 nil——因此真正的包装由 _fengsui_warlords_patch.lua 在
-- scheduler.lua 内 pcall require 完成；这里只导出判定函数。
local dbgLog = function(...)
  fk.qWarning("[fengsui-judge] " .. table.concat({ ... }, " "))
end

function neutralRule.warlordsJudge(self)
  local room = self.room
  if not room or self.dead then
    dbgLog("skip: no room or dead, room=", tostring(room ~= nil), "dead=", tostring(self.dead))
    return
  end
  local enabledRaw = room:getSettings("fengsui_warlords")
  if not warlordsEnabled(room) then
    dbgLog("skip: warlords disabled, raw=", tostring(enabledRaw))
    return
  end
  local neutralPlace = getNeutralPlace(self)
  if neutralPlace ~= nil then
    dbgLog("skip: player is neutral, place=", neutralPlace)
    return
  end
  if self:getMark(judgedMark) ~= 0 then
    dbgLog("skip: already judged, player=", self.id)
    return
  end
  local kingdom = self.kingdom
  if not kingdom or kingdom == "unknown" or kingdom == "wild" or
    kingdom == neutralKingdom or kingdom == neutralAllKingdom then
    dbgLog("skip: invalid kingdom=", tostring(kingdom), "player=", self.id)
    return
  end
  room:setPlayerMark(self, judgedMark, 1)
  local sameKingdom = 0
  for _, other in ipairs(room.alive_players) do
    if other ~= self and other.kingdom == kingdom then sameKingdom = sameKingdom + 1 end
  end
  dbgLog("judge: player=", self.id, "kingdom=", kingdom,
    "players=", #room.players, "same=", sameKingdom,
    "threshold=", math.ceil(#room.players / 3))
  promoteWarlord(room, self, kingdom)
end

neutralRule:addEffect(H.GeneralTransformed, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local old = data and data.origName and Fk.generals[data.origName]
    return target == player and old and
      (old.kingdom == neutralKingdom or old.kingdom == neutralAllKingdom)
  end,
  -- 同上：清标记与收回技能是静默结算，走 on_trigger 免得弹出「是否发动」。
  on_trigger = function(self, event, target)
    if not target or not target.room then return end
    clearRevealProhibition(target.room, target)
    loseNeutralSkills(target.room, target)
  end,
})

return neutralRule
