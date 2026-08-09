local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local pijian = fk.CreateSkill{
  name = "fengsui_heg__pijianRemake",
}

local function getDiscardTypes(room)
  local types = {}
  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(event)
    for _, move in ipairs(event.data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(types, Fk:getCardById(info.cardId).type)
        end
      end
    end
    return false
  end, Player.HistoryTurn)
  return types
end

pijian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player or target.phase ~= Player.Finish or not player:hasSkill(pijian.name) then
      return false
    end

    local types = getDiscardTypes(player.room)
    return #types > 0 and table.every(types, function(card_type)
      return table.find(player:getCardIds("he"), function(id)
        return Fk:getCardById(id).type == card_type
      end) ~= nil
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local selected = {}
    for _, card_type in ipairs(getDiscardTypes(room)) do
      local available = table.filter(player:getCardIds("he"), function(id)
        return Fk:getCardById(id).type == card_type and not table.contains(selected, id)
      end)
      local cards = U.chooseCardsFromList(room, player, available, 1, 1,
        "#fengsui_heg__pijianRemake-card::" .. target.id .. ":" .. card_type, pijian.name, true)
      if #cards == 0 then return false end
      table.insert(selected, cards[1])
    end
    event:setCostData(self, {cards = selected})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, pijian.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = pijian.name,
      }
    end
  end,
})

return pijian
