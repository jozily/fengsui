local modern = require "packages.hegemony.util"

local compat = setmetatable({}, { __index = modern })

-- 遴哲：被标记的角色除计算胜利外，视为与标记者势力相同（模仿构逆）。
local linzheMark = "fengsui_heg__linzhe_target"
local _compareKingdomWith = modern.compareKingdomWith

-- “除计算胜利外”：胜利条件计算不应用遴哲效果。
-- 胜利相关调用点：hegemony_rule.lua 的全员同势力结算（直接调用），
-- 以及 new_hegemony_mode.lua 的 winner_getter（经 compareExpectedKingdomWith 间接调用）。
local function inVictoryCalc()
  local caller = debug.getinfo(2, "S")
  local src = caller and caller.source or ""
  if src:find("hegemony_rule", 1, true) then return true end
  if src:find("util", 1, true) then
    local upper = debug.getinfo(3, "S")
    local src2 = upper and upper.source or ""
    if src2:find("new_hegemony_mode", 1, true) then return true end
  end
  return false
end

function compat.compareKingdomWith(from, to, diff, ignore_gouni)
  if not ignore_gouni and not inVictoryCalc() and from and to and from ~= to and
    from.getTableMark and to.getTableMark then
    if table.contains(from:getTableMark(linzheMark), to.id) or
      table.contains(to:getTableMark(linzheMark), from.id) then
      local ret = true
      if diff then ret = not ret end
      return ret
    end
  end
  return _compareKingdomWith(from, to, diff, ignore_gouni)
end
-- 全局生效：hegemony 本体与各包都直接调用 HegUtil.compareKingdomWith，
-- 必须替换模块表上的函数，仅包装 compat 只对 fengsui 包内生效。
modern.compareKingdomWith = compat.compareKingdomWith

compat.HegMarkChanged = TriggerEvent:subclass("FengsuiHegMarkChanged")
-- Fengsui 奖惩即将执行时；替换摸牌和弃牌两种分支，保留死亡的其他后续。
compat.KillRewardExecuting = TriggerEvent:subclass("FengsuiKillRewardExecuting")

-- 怀香、绝嗣把势力暂时显示为未确定，但击杀奖惩仍使用原势力。
function compat.getRewardKingdom(player)
  if not player then return "unknown" end
  if player.kingdom == "unknown" then
    local original = player:getMark("fengsui_heg__huaixiang_original_kingdom-turn")
    if type(original) ~= "string" or original == "" then
      original = player:getMark("fengsui_heg__juesi_original_kingdom")
    end
    if type(original) == "string" and original ~= "" then return original end
  end
  return compat.getKingdom(player)
end

function compat.compareRewardKingdom(first, second)
  return compat.getRewardKingdom(first) == compat.getRewardKingdom(second)
end

if not modern.__fengsui_mark_hooked then
  local addHegMark = modern.addHegMark
  modern.addHegMark = function(player, markName, number)
    local result = addHegMark(player, markName, number)
    if player and player.room and player.room.logic then
      player.room.logic:trigger(compat.HegMarkChanged, player, {
        markName = markName,
        number = number or 1,
        action = "gain",
      })
    end
    return result
  end
  modern.__fengsui_mark_hooked = true
end

-- Fengsui's hegemony rule passes room explicitly; the 0.5.20 helper only needs player.
function compat.addHegMark(roomOrPlayer, playerOrMark, markOrNumber, number)
  if type(playerOrMark) == "string" then
    local player, mark, n = roomOrPlayer, playerOrMark, markOrNumber or 1
    if mark == "fengsui_heg_ascend" or mark == "fengsui_heg__descend" then
      local room = player.room
      local key = mark == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or "@!!fengsui_heg__descend"
      local skill = mark == "fengsui_heg_ascend" and "fengsui_heg_ascend_skill&" or "fengsui_heg__descend_skill&"
      room:addPlayerMark(player, key, n)
      room:handleAddLoseSkills(player, skill)
      if room.logic then room.logic:trigger(compat.HegMarkChanged, player, {
        markName = mark, number = n, action = "gain",
      }) end
      return
    end
    return modern.addHegMark(roomOrPlayer, playerOrMark, markOrNumber)
  end
  if markOrNumber == "fengsui_heg_ascend" or markOrNumber == "fengsui_heg__descend" then
    local player, mark, n = playerOrMark, markOrNumber, number or 1
    local room = player.room
    local key = mark == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or "@!!fengsui_heg__descend"
    local skill = mark == "fengsui_heg_ascend" and "fengsui_heg_ascend_skill&" or "fengsui_heg__descend_skill&"
    room:addPlayerMark(player, key, n)
    room:handleAddLoseSkills(player, skill)
    if room.logic then room.logic:trigger(compat.HegMarkChanged, player, {
      markName = mark, number = n, action = "gain",
    }) end
    return
  end
  return modern.addHegMark(playerOrMark, markOrNumber, number)
end

function compat.removeHegMark(room, player, markName, number)
  local amount = number or 1
  local key = markName == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or
    markName == "fengsui_heg__descend" and "@!!fengsui_heg__descend" or
    "@!!" .. markName
  local before = player and player:getMark(key) or 0
  if markName == "fengsui_heg_ascend" or markName == "fengsui_heg__descend" then
    local key = markName == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or "@!!fengsui_heg__descend"
    local skill = markName == "fengsui_heg_ascend" and "fengsui_heg_ascend_skill&" or "fengsui_heg__descend_skill&"
    room:removePlayerMark(player, key, amount)
    if player:getMark(key) == 0 then room:handleAddLoseSkills(player, "-" .. skill) end
  else
    modern.removeHegMark(room, player, markName, amount)
  end
  local used = math.min(before, amount)
  if used > 0 and room.logic then
    room.logic:trigger(compat.HegMarkChanged, player, {
      markName = markName, number = -used, action = "use",
    })
  end
end

-- 本局变更过的武将牌不能再次作为变更副将或合璧候选；场上暗置的
-- 武将牌也视为已占用，不能因为暂时看不见而再次选入。
local transformedGeneralsTag = "fengsui_heg__transformed_generals"

local function wasTransformed(room, general)
  local used = room:getTag(transformedGeneralsTag) or {}
  return used[general] == true
end

local function recordTransformed(room, general)
  if not general or general == "" or general == "anjiang" then return end
  local used = room:getTag(transformedGeneralsTag) or {}
  used[general] = true
  room:setTag(transformedGeneralsTag, used)
end

compat.recordTransformed = recordTransformed

local function isGeneralOnField(room, general)
  for _, p in ipairs(room.players) do
    if p.general == general or p.deputyGeneral == general or
        p:getMark("__heg_general") == general or p:getMark("__heg_deputy") == general then
      return true
    end
  end
  return false
end

local function findFreshGenerals(room, kingdom, num)
  return room:findGenerals(function(name)
    local general = Fk.generals[name]
    if not general or wasTransformed(room, name) or isGeneralOnField(room, name) then return false end
    if kingdom == "wild" then
      return general.kingdom ~= "wild" and general.subkingdom ~= "wild"
    end
    return general.kingdom == kingdom or general.subkingdom == kingdom
  end, num)
end

-- The official helper is already random when it receives one candidate. For
-- Fengsui callers that request a multi-candidate choice, keep the same pool
-- and event contract but select one candidate directly.
function compat.transformGeneral(room, player, isMain, isHidden, num, skillName)
  local data = modern.GeneralTransformedData:new{
    isMain = isMain,
    isHidden = isHidden,
    num = num,
    skillName = skillName,
  }
  if room.logic:trigger(modern.GeneralTransforming, player, data) then return false end
  isMain, isHidden = data.isMain, data.isHidden
  local original = isMain and player.general or player.deputyGeneral
  data.origName = original
  if not original then return false end
  if original == "anjiang" then
    player:revealGeneral(not isMain, true)
    original = isMain and player.general or player.deputyGeneral
    data.origName = original
  end

  local kingdom = player:getMark("__heg_kingdom")
  if kingdom == 0 or kingdom == "" or kingdom == nil then kingdom = player.kingdom end
  local count = math.max(1, num or 1)
  local generals = findFreshGenerals(room, kingdom, count)
  if #generals == 0 then return false end
  local general = count == 1 and generals[1] or room:askToChooseGeneral(player, {
    generals = generals,
    n = math.min(count, #generals),
    no_convert = true,
  })
  if not general then
    room:returnToGeneralPile(generals)
    return false
  end
  table.removeOne(generals, general)
  if #generals > 0 then room:returnToGeneralPile(generals) end

  room:changeHero(player, general, false, not isMain, not isHidden, false, false)
  if isHidden then
    player:hideGeneral(not isMain)
    room:sendLog{
      type = "#ChangeHiddenGeneral",
      from = player.id,
      arg = isMain and "mainGeneral" or "deputyGeneral",
      toast = true,
    }
  end
  room:setPlayerMark(player, isMain and "__heg_general" or "__heg_deputy", general)
  recordTransformed(room, data.origName)
  recordTransformed(room, general)
  room.logic:trigger(modern.GeneralTransformed, player, data)
  return true
end

local function returnGenerals(room, generals, chosen)
  table.removeOne(generals, chosen)
  if #generals > 0 then room:returnToGeneralPile(generals) end
end

local function changeGeneral(room, player, general, isMain, isHidden, data)
  room:changeHero(player, general, false, not isMain, not isHidden, false, false)
  if isHidden then
    player:hideGeneral(not isMain)
    room:sendLog{
      type = "#ChangeHiddenGeneral",
      from = player.id,
      arg = isMain and "mainGeneral" or "deputyGeneral",
      toast = true,
    }
  end
  room:setPlayerMark(player, isMain and "__heg_general" or "__heg_deputy", general)
  recordTransformed(room, data.origName)
  recordTransformed(room, general)
  room.logic:trigger(modern.GeneralTransformed, player, data)
end

function compat.askToHebiOrTransform(room, player, skillName, cancelable)
  if not room or not player or player.dead then return false end
  local main = Fk.generals[modern.getActualGeneral(player, false)]
  if not main then return compat.transformGeneral(room, player, false, false, 1, skillName) end
  if main.kingdom == "wild" or main.subkingdom == "wild" then
    return compat.transformGeneral(room, player, false, false, 1, skillName)
  end

  local companions = room:findGenerals(function(name)
    local general = Fk.generals[name]
    return general and not wasTransformed(room, name) and not isGeneralOnField(room, name) and
      general.kingdom ~= "wild" and general.subkingdom ~= "wild" and
      (main:isCompanionWith(general) or general:isCompanionWith(main))
  end, #(room.general_pile or {}))

  -- A careerist companion cannot form Hebi; replace the deputy directly instead.
  if #companions == 0 then
    return compat.transformGeneral(room, player, false, false, 1, skillName)
  end

  local choices = { "fengsui_hebi_choice" }
  if cancelable then table.insert(choices, "Cancel") end
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = skillName,
    prompt = "#fengsui-hebi-or-transform",
  })
  if choice ~= "fengsui_hebi_choice" then
    room:returnToGeneralPile(companions)
    if choice == "Cancel" then return false end
    return compat.transformGeneral(room, player, false, false, 1, skillName)
  end

  local original = modern.getActualGeneral(player, true)
  local data = modern.GeneralTransformedData:new{
    isMain = false,
    isHidden = false,
    num = #companions,
    origName = original,
    skillName = skillName,
  }
  if room.logic:trigger(modern.GeneralTransforming, player, data) then
    room:returnToGeneralPile(companions)
    return false
  end
  if player.deputyGeneral == "anjiang" then player:revealGeneral(true, true) end

  local general = room:tableRandomPick(companions, 1)[1]
  if not general or general == "" then
    room:returnToGeneralPile(companions)
    return false
  end
  returnGenerals(room, companions, general)
  changeGeneral(room, player, general, false, false, data)
  modern.addHegMark(player, "companion", 1)
  return true
end

-- 非标签技判定：供揖门访客、相谶发放等临时获得技能的场合使用。
-- 主将技/副将技是位置标签而非技能类型，不在排除之列（由调用方做位置匹配）。
local GRANT_FORBIDDEN_TAGS = {
  [Skill.Lord] = true, [Skill.Compulsory] = true, [Skill.Limited] = true,
  [Skill.Wake] = true, [Skill.Switch] = true, [Skill.Quest] = true,
  [Skill.Permanent] = true, [Skill.Hidden] = true, [Skill.AttachedKingdom] = true,
  [Skill.Charge] = true, [Skill.Family] = true, [Skill.Combo] = true,
  [Skill.Rhyme] = true, [Skill.Force] = true,
}

function compat.isTaggedSkill(skill)
  if not skill then return true end
  local skel = skill.getSkeleton and skill:getSkeleton() or skill
  for _, tag in ipairs(skel.tags or {}) do
    if GRANT_FORBIDDEN_TAGS[tag] then return true end
  end
  return false
end

Fk:loadTranslationTable{
  ["#fengsui-hebi-or-transform"] = "请选择合璧；若无可用配对对象则自动变更副将",
}

return compat
