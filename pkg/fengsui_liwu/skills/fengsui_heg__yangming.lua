local H = require "packages.fengsui.hegemony_util"

local s = fk.CreateSkill { name = "fengsui_heg__yangming" }

local function kingdomCount(room)
  local kingdoms = {}
  for _, p in ipairs(room.alive_players) do
    if p.kingdom ~= "unknown" and p.kingdom ~= "fengsui_neutral" and p.kingdom ~= "fengsui_neutralall" then
      table.insertIfNeed(kingdoms, p.kingdom)
    end
  end
  return #kingdoms
end

local function getDiscardCardTypes(data, player, usedCards)
  usedCards = usedCards or player:getTableMark(s.name .. "_used_cards-turn")
  local types = {}
  for _, move in ipairs(data) do
    if move.toArea == Card.DiscardPile and
      (move.moveReason == fk.ReasonDiscard and move.from == player or move.moveReason == fk.ReasonUse) then
      for _, info in ipairs(move.moveInfo) do
        if move.moveReason == fk.ReasonDiscard or table.contains(usedCards, info.cardId) then
          table.insertIfNeed(types, Fk:getCardById(info.cardId):getTypeString())
        end
      end
    end
  end
  return types
end

s:addEffect(fk.PreCardUse, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and #Card:getIdList(data.card) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local ids = player:getTableMark(s.name .. "_used_cards-turn")
    table.insertTableIfNeed(ids, Card:getIdList(data.card))
    player.room:setPlayerMark(player, s.name .. "_used_cards-turn", ids)
  end,
})

s:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(s.name) and #getDiscardCardTypes(data, player) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local types = player:getTableMark(s.name .. "-turn")
    table.insertTableIfNeed(types, getDiscardCardTypes(data, player))
    player.room:setPlayerMark(player, s.name .. "-turn", types)
  end,
})

s:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(s.name) and H.compareKingdomWith(target, player) and
      #player:getTableMark(s.name .. "-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = s.name })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = #player:getTableMark(s.name .. "-turn")
    player:drawCards(x, s.name)
    if player.dead or x < kingdomCount(room) or player:isKongcheng() then return end
    room:showCards(player:getCardIds("h"), player, player)
    local chosen = {}
    for _ = 1, x do
      if player.dead or player:isKongcheng() then break end
      local targets = table.filter(room:getOtherPlayers(player), function(p)
        return p:isAlive() and p.kingdom ~= "unknown" and p.kingdom ~= "fengsui_neutral" and
          p.kingdom ~= "fengsui_neutralall" and not table.contains(chosen, p.kingdom)
      end)
      if #targets == 0 then break end
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_num = 1, max_num = 1, min_card_num = 1, max_card_num = 1,
        targets = targets, pattern = ".|.|.|hand", skill_name = s.name,
        prompt = "#fengsui_heg__yangming-give", cancelable = false,
      })
      if #tos == 0 or #cards == 0 then break end
      table.insertIfNeed(chosen, tos[1].kingdom)
      room:moveCardTo(cards, Card.PlayerHand, tos[1], fk.ReasonGive, s.name, nil, true, player)
    end
  end,
})

s:addTest(function(room, me)
  local slash = room:printCard("slash")
  local duel = room:printCard("duel")
  local types = getDiscardCardTypes({
    {
      from = me,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      moveInfo = {
        { cardId = slash.id, fromArea = Card.PlayerHand },
      },
    },
    {
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse,
      moveInfo = {
        { cardId = duel.id, fromArea = Card.Processing },
      },
    },
  }, me, { duel.id })
  lu.assertTrue(table.contains(types, "basic"))
  lu.assertTrue(table.contains(types, "trick"))
end)

return s
