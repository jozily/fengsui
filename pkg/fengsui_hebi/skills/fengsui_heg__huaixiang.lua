local H = require "packages.fengsui.hegemony_util"

local huaixiang = fk.CreateSkill{
  name = "fengsui_heg__huaixiang",
}

local original_kingdom_mark = "fengsui_heg__huaixiang_original_kingdom-turn"

local function entersDiscardPileByDiscard(move)
  return move.toArea == Card.DiscardPile and
    (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonRecast)
end

local function getEligibleCards(room, data)
  local discarded_types = {}
  local current_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(event)
    if not current_event or event.id ~= current_event.id then
      for _, move in ipairs(event.data) do
        if entersDiscardPileByDiscard(move) then
          for _, info in ipairs(move.moveInfo) do
            discarded_types[Fk:getCardById(info.cardId).type] = true
          end
        end
      end
    end
  end, Player.HistoryPhase)

  local ids = {}
  for _, move in ipairs(data) do
    if entersDiscardPileByDiscard(move) then
      for _, info in ipairs(move.moveInfo) do
        local card = Fk:getCardById(info.cardId)
        if not discarded_types[card.type] and room:getCardArea(info.cardId) == Card.DiscardPile then
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
  end
  return ids
end

huaixiang:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local current = player.room.current
    return player:hasSkill(huaixiang.name) and current and
      current.phase ~= Player.NotActive and
      H.compareKingdomWith(current, player) and #getEligibleCards(player.room, data) > 0 and
      table.find(player.room.alive_players, function(p) return p.kingdom ~= "unknown" end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = getEligibleCards(room, data)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = huaixiang.name,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#fengsui_heg__huaixiang-card",
      expand_pile = ids,
      cancelable = true,
    })
    if #cards == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = table.filter(room.alive_players, function(p) return p.kingdom ~= "unknown" end),
      skill_name = huaixiang.name,
      prompt = "#fengsui_heg__huaixiang-target",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {cards = cards, tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local to = cost.tos[1]
    if room:getCardArea(cost.cards[1]) == Card.DiscardPile then
      room:obtainCard(player, cost.cards[1], true, fk.ReasonPrey, player, huaixiang.name)
    end
    if to:isAlive() and to.kingdom ~= "unknown" then
      room:setPlayerMark(to, original_kingdom_mark, to.kingdom)
      room:setPlayerMark(to, "@fengsui_heg__huaixiang-turn", 1)
      room:setPlayerProperty(to, "kingdom", "unknown")
    end
  end,
})

huaixiang:addEffect(fk.TurnEnd, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return table.find(player.room.players, function(p)
      return p:getMark(original_kingdom_mark) ~= 0
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      local kingdom = p:getMark(original_kingdom_mark)
      if kingdom ~= 0 then
        room:setPlayerProperty(p, "kingdom", kingdom)
        room:setPlayerMark(p, original_kingdom_mark, 0)
        room:setPlayerMark(p, "@fengsui_heg__huaixiang-turn", 0)
      end
    end
  end,
})

return huaixiang
