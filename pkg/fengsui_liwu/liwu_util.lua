local Liwu = {}

local H = require "packages.hegemony.util"

Liwu.kingdom = "fengsui_neutralall"
Liwu.compatKingdom = Liwu.kingdom
Liwu.legacyKingdom = "fengsui_neutral"

Liwu.generals = {
  "fengsui_heg__jiaxu",
  "fengsui_heg__lusu",
  "fengsui_heg__xushu",
  "fengsui_heg__zhaoe",
  "fengsui_heg__xushao",
  "fengsui_toaru__heg__frenda",
  "fengsui_toaru__heg__shokuhou",
  "fengsui_toaru__heg__misaka",
  "fengsui_toaru__heg__shirai",
}

Liwu.neutralSkills = {}

function Liwu.isNeutralGeneral(generalName)
  local general = Fk.generals[generalName]
  return general ~= nil and general.kingdom == Liwu.kingdom
end

function Liwu.getNeutralPlace(player)
  if Liwu.isNeutralGeneral(player:getMark("__heg_general")) then return "m" end
  if Liwu.isNeutralGeneral(player:getMark("__heg_deputy")) then return "d" end
end

function Liwu.isNeutralShown(player)
  local place = Liwu.getNeutralPlace(player)
  return (place == "m" and player.general ~= "anjiang") or
    (place == "d" and player.deputyGeneral ~= "anjiang")
end

function Liwu.isKingdomDetermined(player)
  local kingdom = player and player.kingdom
  if type(kingdom) ~= "string" then
    kingdom = player and player:getMark("__heg_kingdom")
  end
  return type(kingdom) == "string" and kingdom ~= "unknown" and
    kingdom ~= Liwu.kingdom and kingdom ~= Liwu.compatKingdom
end

if not H._fengsuiNeutralWrapped then
  local originalGetKingdom = H.getKingdom
  H.getKingdom = function(player)
    local kingdom = player and player.kingdom
    -- 某些客户端回包会把势力属性暂时暴露为数字；优先使用国战规则
    -- 保存的字符串势力，避免与 "unknown" 比较时发生类型错误。
    if type(kingdom) ~= "string" then
      local marked = player and player:getMark("__heg_kingdom")
      if type(marked) == "string" then kingdom = marked end
    end
    local neutral_mark = tonumber(player and player:getMark("@fengsui_neutral")) or 0
    if kingdom == "unknown" and neutral_mark > 0 then
      return Liwu.legacyKingdom .. "_" .. player.id
    end
    if player and type(player.kingdom) ~= "string" and type(kingdom) == "string" then
      return kingdom
    end
    return originalGetKingdom(player)
  end
  H._fengsuiNeutralWrapped = true
end

return Liwu
