local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tuanfeng = fk.CreateSkill{
  name = "fengsui_heg__tuanfengRemake",
}

tuanfeng:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuanfeng.name) and
      player.phase == Player.Start and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = U.chooseCardsFromList(player.room, player, player:getCardIds("he"), 1, 1,
      "#fengsui_heg__tuanfengRemake-recast", tuanfeng.name, true)
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local id = event:getCostData(self).cards[1]
    local card = Fk:getCardById(id)
    local card_type = card.type
    player.room:recastCard(id, player, tuanfeng.name)
    player.room:setPlayerMark(player, "fengsui_heg__tuanfengRemake_type_" .. card_type .. "-round", 1)
    player.room:addTableMarkIfNeed(player, "@fengsui_heg__tuanfengRemake-round", card.trueName)
  end,
})

local function canModify(player, card)
  if not card or player.phase ~= Player.Play or
    player:getMark("fengsui_heg__tuanfengRemake_used_" .. card.type .. "-turn") > 0 then return false end
  local room = Fk:currentRoom()
  return room and table.find(room.alive_players, function(owner)
    return owner:hasSkill(tuanfeng.name) and H.compareKingdomWith(owner, player) and
      owner:getMark("fengsui_heg__tuanfengRemake_type_" .. card.type .. "-round") > 0
  end) ~= nil
end

tuanfeng:addEffect(fk.PreCardUse, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and canModify(player, data.card)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

tuanfeng:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return canModify(player, card)
  end,
  bypass_distances = function(self, player, skill, card)
    return canModify(player, card)
  end,
})

tuanfeng:addEffect(fk.CardUseFinished, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and canModify(player, data.card)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player,
      "fengsui_heg__tuanfengRemake_used_" .. data.card.type .. "-turn", 1)
  end,
})

return tuanfeng
