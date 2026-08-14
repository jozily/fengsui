local modern = require "packages.hegemony.util"

local compat = setmetatable({}, { __index = modern })

-- Fengsui's hegemony rule passes room explicitly; the 0.5.20 helper only needs player.
function compat.addHegMark(roomOrPlayer, playerOrMark, markOrNumber, number)
  if type(playerOrMark) == "string" then
    return modern.addHegMark(roomOrPlayer, playerOrMark, markOrNumber)
  end
  return modern.addHegMark(playerOrMark, markOrNumber, number)
end

function compat.removeHegMark(room, player, markName, number)
  return modern.removeHegMark(room, player, markName, number)
end

-- The official helper is already random when it receives one candidate. For
-- Fengsui callers that request a multi-candidate choice, keep the same pool
-- and event contract but select one candidate directly.
function compat.transformGeneral(room, player, isMain, isHidden, num, skillName)
  if (num or 1) <= 1 then
    local original = modern.getActualGeneral(player, not isMain)
    local result = modern.transformGeneral(room, player, isMain, isHidden, num, skillName)
    local current = modern.getActualGeneral(player, not isMain)
    if original and original ~= current and original ~= "" and original ~= "anjiang" and
        not original:startsWith("blank_") then
      room:findGenerals(function(name) return name == original end, 1)
    end
    return result
  end

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
  local generals = room:findGenerals(function(name)
    local general = Fk.generals[name]
    if not general then return false end
    if kingdom == "wild" then
      return general.kingdom ~= "wild" and general.subkingdom ~= "wild"
    end
    return general.kingdom == kingdom or general.subkingdom == kingdom
  end, 1)
  local general = generals[1]
  if not general then return false end

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
    return general and general.kingdom ~= "wild" and general.subkingdom ~= "wild" and
      (main:isCompanionWith(general) or general:isCompanionWith(main))
  end, #(room.general_pile or {}))

  -- A careerist companion cannot form Hebi; replace the deputy directly instead.
  if #companions == 0 then
    return compat.transformGeneral(room, player, false, false, 1, skillName)
  end

  local choices = { "fengsui_hebi_choice", "fengsui_transform" }
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

Fk:loadTranslationTable{
  ["#fengsui-hebi-or-transform"] = "请选择合璧或变更副将",
}

return compat
