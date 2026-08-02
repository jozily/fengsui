local Yili = require "packages.fengsui.pkg.fengsui_yili.util"

local neutralRule = fk.CreateSkill {
  name = "#fengsui_neutral_rule",
}

local function otherPlace(place)
  return place == "m" and "d" or "m"
end

local function clearRevealProhibition(room, player)
  room:setPlayerMark(player, "fengsui_neutral_reveal_place", 0)
  room:setPlayerMark(player, "fengsui_neutral_reveal_round", 0)
  room:setPlayerMark(player, MarkEnum.RevealProhibited .. "-fengsui", 0)
end

local function loseNeutralSkills(room, player)
  local skills = table.filter(Yili.neutralSkills, function(skillName)
    return player:hasSkill(skillName, true, true)
  end)
  if #skills > 0 then
    room:handleAddLoseSkills(player, "-" .. table.concat(skills, "|-"), nil, false, true)
  end
end

local function determineKingdom(room, player)
  local kingdom = player:getMark("__heg_kingdom")
  if type(kingdom) ~= "string" or kingdom == "" or kingdom == Yili.kingdom then return end
  room:setPlayerProperty(player, "kingdom", kingdom)
  room:setPlayerProperty(player, "role", kingdom)
  clearRevealProhibition(room, player)
  loseNeutralSkills(room, player)
end

neutralRule:addEffect(fk.GeneralShown, {
  global = true,
  priority = 20,
  can_trigger = function(self, event, target, player, data)
    return target == player and Yili.getNeutralPlace(player) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local neutralPlace = Yili.getNeutralPlace(player)
    local shownPlace = data.m and "m" or "d"
    local otherShown = neutralPlace == "m" and player.deputyGeneral ~= "anjiang" or
      neutralPlace == "d" and player.general ~= "anjiang"

    if shownPlace == neutralPlace and not otherShown then
      room:setPlayerProperty(player, "kingdom", "unknown")
      room:setPlayerProperty(player, "role", "hidden")
      room:setPlayerMark(player, "@fengsui_neutral", 1)
      room:setPlayerMark(player, "fengsui_neutral_reveal_place", otherPlace(neutralPlace))
      room:setPlayerMark(player, "fengsui_neutral_reveal_round", room:getBanner("RoundCount") or 0)
      room:setPlayerMark(player, MarkEnum.RevealProhibited .. "-fengsui", { otherPlace(neutralPlace) })
    else
      room:setPlayerMark(player, "@fengsui_neutral", 0)
      determineKingdom(room, player)
    end
  end,
})

neutralRule:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_neutral_reveal_place") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    clearRevealProhibition(player.room, player)
  end,
})

neutralRule:addEffect(fk.RoundStart, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    local shownRound = player:getMark("fengsui_neutral_reveal_round")
    return shownRound > 0 and (player.room:getBanner("RoundCount") or 0) > shownRound
  end,
  on_use = function(self, event, target, player, data)
    clearRevealProhibition(player.room, player)
  end,
})

return neutralRule
