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
  "fengsui_limited_heg__frenda",
  "fengsui_limited_heg__shokuhou",
  "fengsui_limited_heg__misaka",
  "fengsui_limited_heg__shirai",
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
  return player.kingdom ~= "unknown" and player.kingdom ~= Liwu.kingdom and
    player.kingdom ~= Liwu.compatKingdom
end

if not H._fengsuiNeutralWrapped then
  local originalGetKingdom = H.getKingdom
  H.getKingdom = function(player)
    if player.kingdom == "unknown" and player:getMark("@fengsui_neutral") > 0 then
      return Liwu.legacyKingdom .. "_" .. player.id
    end
    return originalGetKingdom(player)
  end
  H._fengsuiNeutralWrapped = true
end

return Liwu
