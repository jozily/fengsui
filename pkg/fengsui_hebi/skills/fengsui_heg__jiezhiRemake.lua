local jiezhi = fk.CreateSkill{
  name = "fengsui_heg__jiezhiRemake",
}

local function getLastDifferentDiscard(room, card_type)
  local result
  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
    for move_index = #e.data, 1, -1 do
      local move = e.data[move_index]
      if move.toArea == Card.DiscardPile then
        for info_index = #move.moveInfo, 1, -1 do
          local id = move.moveInfo[info_index].cardId
          if table.contains(room.discard_pile, id) and Fk:getCardById(id).type ~= card_type then
            result = id
            return true
          end
        end
      end
    end
    return false
  end, Player.HistoryTurn)
  return result
end

jiezhi:addEffect(fk.AfterCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(jiezhi.name) then return false end
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local discard = getLastDifferentDiscard(player.room, Fk:getCardById(info.cardId).type)
            if discard then
              event:setCostData(self, {to = move.to, given = info.cardId, discard = discard})
              return true
            end
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local cost = event:getCostData(self)
    return player.room:askToSkillInvoke(player, {
      skill_name = jiezhi.name,
      prompt = "#fengsui_heg__jiezhiRemake-invoke::" .. cost.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    if room:getCardArea(cost.discard) ~= Card.DiscardPile then return end
    room:obtainCard(player, cost.discard, true, fk.ReasonPrey, player, jiezhi.name)
    local given = Fk:getCardById(cost.given)
    local obtained = Fk:getCardById(cost.discard)
    if given:compareColorWith(obtained) then
      room:addTableMarkIfNeed(cost.to, "fengsui_heg__jiezhiRemake_prohibit-turn", player.id)
      room:addTableMarkIfNeed(cost.to, "@fengsui_heg__jiezhiRemake-turn", player.id)
    else
      room:addTableMarkIfNeed(player, "fengsui_heg__jiezhiRemake_prohibit-turn", cost.to.id)
      room:addTableMarkIfNeed(player, "@fengsui_heg__jiezhiRemake-turn", cost.to.id)
    end
  end,
})

jiezhi:addEffect("prohibit", {
  global = true,
  is_prohibited = function(self, from, to, card)
    return from and to and
      table.contains(from:getTableMark("fengsui_heg__jiezhiRemake_prohibit-turn"), to.id)
  end,
})

return jiezhi
