local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yamai = fk.CreateSkill{
  name = "fengsui_heg__yamai",
}

yamai:addEffect("arraysummon", { array_type = "formation" })

yamai:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(yamai.name) then return false end
    return table.find(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand then return true end
      if move.from == player and move.moveReason == fk.ReasonUse then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) ~= nil
      end
      return false
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local cards = player:getTableMark("fengsui_heg__yamai_cards-turn")
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      elseif move.from == player and move.moveReason == fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    player.room:setPlayerMark(player, "fengsui_heg__yamai_cards-turn", cards)
  end,
})

yamai:addEffect(fk.TurnEnd, {
  global = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yamai.name) or not U.inSameQueue(target, player) then return false end
    return table.find(player:getTableMark("fengsui_heg__yamai_cards-turn"), function(id)
      local area = player.room:getCardArea(id)
      return (area == Card.PlayerHand and player.room:getCardOwner(id) == player) or area == Card.DiscardPile
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getTableMark("fengsui_heg__yamai_cards-turn"), function(id)
      local area = room:getCardArea(id)
      return (area == Card.PlayerHand and room:getCardOwner(id) == player) or area == Card.DiscardPile
    end)
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      expand_pile = cards,
      skill_name = yamai.name,
      prompt = "#fengsui_heg__yamai-use::" .. target.id,
      cancelable = true,
      skip = true,
      extra_data = {bypass_times = true},
    })
    if use then
      event:setCostData(self, {use = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = event:getCostData(self).use
    use.extraUse = true
    player.room:useCard(use)
  end,
})

return yamai
