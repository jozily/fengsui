local qiaosi = fk.CreateSkill{
  name = "fengsui_heg__qiaosi",
}

local discarded_mark = "fengsui_heg__qiaosi_discarded-turn"

qiaosi:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(qiaosi.name) then return false end
    return table.find(data, function(move)
      return move.toArea == Card.DiscardPile and #move.moveInfo > 0
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    local cards = player:getTableMark(discarded_mark)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      end
    end
    player.room:setPlayerMark(player, discarded_mark, cards)
  end,
})

qiaosi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiaosi.name) and
      player.phase == Player.Discard and table.find(player:getTableMark(discarded_mark), function(id)
        return player.room:getCardArea(id) == Card.DiscardPile
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local eligible = table.filter(player:getTableMark(discarded_mark), function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    local choices = {}
    local mapping = {
      [Card.TypeBasic] = "fengsui_heg__qiaosi_basic",
      [Card.TypeTrick] = "fengsui_heg__qiaosi_trick",
      [Card.TypeEquip] = "fengsui_heg__qiaosi_equip",
    }
    for _, id in ipairs(eligible) do
      table.insertIfNeed(choices, mapping[Fk:getCardById(id).type])
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qiaosi.name,
      prompt = "#fengsui_heg__qiaosi-choice",
      cancelable = true,
    })
    if choice and choice ~= "Cancel" then
      event:setCostData(self, { choice = choice, cards = eligible })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local mapping = {
      fengsui_heg__qiaosi_basic = Card.TypeBasic,
      fengsui_heg__qiaosi_trick = Card.TypeTrick,
      fengsui_heg__qiaosi_equip = Card.TypeEquip,
    }
    local cards = table.filter(cost.cards, function(id)
      return room:getCardArea(id) == Card.DiscardPile and
        Fk:getCardById(id).type == mapping[cost.choice]
    end)
    if #cards > 0 then
      room:obtainCard(player, cards, true, fk.ReasonPrey, player, qiaosi.name)
    end
    if #cards ~= player.hp then
      room:loseHp(player, 1, qiaosi.name)
    end
  end,
})

return qiaosi
