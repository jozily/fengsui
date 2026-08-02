local Yili = {}

local H = require "packages.hegemony.util"

Yili.kingdom = "fengsui_neutral"

Yili.generals = {
  "fengsui_heg__jiaxu",
  "fengsui_heg__lusu",
  "fengsui_heg__xushu",
  "fengsui_heg__zhaoe",
  "fengsui_heg__xushao",
}

Yili.neutralSkills = {
  "fengsui_heg__shuge",
  "fengsui_heg__yangming",
  "fengsui_heg__xiawang",
  "fengsui_heg__yanshi",
  "fengsui_heg__suoli",
}

function Yili.isNeutralGeneral(generalName)
  return table.contains(Yili.generals, generalName)
end

function Yili.getNeutralPlace(player)
  if Yili.isNeutralGeneral(player:getMark("__heg_general")) then return "m" end
  if Yili.isNeutralGeneral(player:getMark("__heg_deputy")) then return "d" end
end

function Yili.isNeutralShown(player)
  local place = Yili.getNeutralPlace(player)
  return (place == "m" and player.general ~= "anjiang") or
    (place == "d" and player.deputyGeneral ~= "anjiang")
end

function Yili.isKingdomDetermined(player)
  return player.kingdom ~= "unknown" and player.kingdom ~= Yili.kingdom
end

if not H._fengsuiNeutralWrapped then
  local originalGetKingdom = H.getKingdom
  H.getKingdom = function(player)
    if player.kingdom == "unknown" and player:getMark("@fengsui_neutral") > 0 then
      return Yili.kingdom .. "_" .. player.id
    end
    return originalGetKingdom(player)
  end
  H._fengsuiNeutralWrapped = true
end

return Yili
