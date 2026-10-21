local H = require "packages.hegemony.util"

-- Keep the extended transform contract inside Fengsui so the official
-- hegemony package can remain untouched.
function H.transformGeneral(room, player, isMain, isHidden, num, skillName)
  local data = H.GeneralTransformedData:new{
    isMain = isMain,
    isHidden = isHidden,
    num = num,
    skillName = skillName,
  }
  if room.logic:trigger(H.GeneralTransforming, player, data) then return false end
  isMain, isHidden, num = data.isMain, data.isHidden, data.num
  local orig = isMain and player.general or player.deputyGeneral
  data.origName = orig
  num = num or 1
  if not orig then return false end
  if orig == "anjiang" then
    player:revealGeneral(not isMain, true)
    orig = isMain and player.general or player.deputyGeneral
  end

  local kingdom = player:getMark("__heg_kingdom")
  local generals
  if kingdom == "wild" then
    generals = room:findGenerals(function(name)
      local general = Fk.generals[name]
      return general and general.kingdom ~= "wild" and general.subkingdom ~= "wild"
    end, num)
  else
    generals = room:findGenerals(function(name)
      local general = Fk.generals[name]
      return general and (general.kingdom == kingdom or general.subkingdom == kingdom)
    end, num)
  end
  if #generals == 0 then return false end

  local general = #generals == 1 and generals[1] or room:askToChooseGeneral(player, {
    generals = generals,
    n = 1,
    no_convert = true,
  })
  if not general or general == "" then
    room:returnToGeneralPile(generals)
    return false
  end

  table.removeOne(generals, general)
  if orig ~= "" and orig ~= "anjiang" and not orig:startsWith("blank_") then
    table.insertIfNeed(generals, orig)
  end
  room:returnToGeneralPile(generals)
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
  room.logic:trigger(H.GeneralTransformed, player, data)
  return true
end

function H.wildChooseKingdom(player, generalName)
  local room = player.room
  local allChoices = table.clone(H.wildKingdoms)
  local choices = table.clone(allChoices)
  for _, p in ipairs(room.players) do
    table.removeOne(choices, p.role)
  end

  local choice
  if player.general == generalName and H.kingdomMapper[generalName] and
      H.kingdomMapper[generalName] ~= player.role and table.contains(choices, H.kingdomMapper[generalName]) then
    choice = H.kingdomMapper[generalName]
  else
    if #choices == 0 then choices = table.clone(allChoices) end
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = "game_rule",
      prompt = "#wild-choose",
      cancelable = false,
      all_choices = allChoices,
    })
  end

  player.role = choice
  room:setPlayerProperty(player, "role_shown", true)
  room:broadcastProperty(player, "role")
  room:sendLog{
    type = "#WildChooseKingdom",
    from = player.id,
    arg = choice,
    arg2 = "wild",
  }
  return choice
end

if not H._fengsuiOriginalInFormationRelation then
  H._fengsuiOriginalInFormationRelation = H.inFormationRelation
  H.inFormationRelation = function(player, target)
    if H._fengsuiOriginalInFormationRelation(player, target) then return true end
    local room = (player and player.room) or (target and target.room) or Fk:currentRoom()
    if not room or not player or not target or not H.compareKingdomWith(player, target) then return false end
    local ignoresRelation = player:getMark("@fengsui_heg__zhouwang-round") > 0 or
      target:getMark("@fengsui_heg__zhouwang-round") > 0 or table.find(room.alive_players, function(p)
      return p:hasSkill("fengsui_heg__chenji") and H.compareKingdomWith(p, player)
    end) ~= nil
    if not ignoresRelation then return false end
    if player ~= target then return true end
    return table.find(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player)
    end) ~= nil
  end
end

if Room and not Room._fengsuiKnownBothWrapped then
  local originalAskToChoice = Room.askToChoice
  Room.askToChoice = function(self, player, params)
    local choice = originalAskToChoice(self, player, params)
    local capture = self._fengsuiKnownBothCapture
    if capture and player == capture.player and params.skill_name == "known_both" then
      capture.choice = choice
    end
    return choice
  end
  Room._fengsuiKnownBothWrapped = true
end

Fk:loadTranslationTable{
  ["#ChangeHiddenGeneral"] = "%from 变更了 %arg（暗置）",
}

return H
