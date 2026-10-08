local qusheng = fk.CreateSkill { name = "fengsui_heg__qusheng" }

qusheng:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return player:hasSkill(self.name) and player:getMark(self.name .. "-turn") == 0 and data and
      table.find(data, function(m) return m.toArea == Card.DiscardPile and (m.moveReason == fk.ReasonUse or m.moveReason == fk.ReasonResponse) and m.moveInfo and #m.moveInfo > 0 end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__qusheng-invoke" }) then
      event:setCostData(self, { moves = data })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local candidates = {}
    for _, move in ipairs(event:getCostData(self).moves or {}) do
      if move.toArea == Card.DiscardPile and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) and move.moveInfo then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          local card = Fk:getCardById(id)
          if card then
            for _, other in ipairs(room.discard_pile) do
              local c = Fk:getCardById(other)
              if other ~= id and c and c.name == card.name and c.color ~= card.color then
                table.insert(candidates, { first = id, second = other, source = move.from })
                break
              end
            end
          end
        end
      end
    end
    if #candidates == 0 then return end
    local pair = candidates[1]
    local choice = room:askToChoice(player, { choices = { "fengsui_heg__qusheng_first", "fengsui_heg__qusheng_second" }, skill_name = self.name })
    local gain, put = choice == "fengsui_heg__qusheng_second" and pair.second or pair.first, choice == "fengsui_heg__qusheng_second" and pair.first or pair.second
    room:setPlayerMark(player, self.name .. "-turn", 1)
    room:obtainCard(player, gain, true, fk.ReasonPrey, player, self.name)
    if room:getCardArea(put) == Card.DiscardPile then room:moveCardTo(put, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, true, player) end
    if room.current and pair.source ~= room.current then room:drawCards(room.current, 1, self.name) end
  end,
})

qusheng:addEffect(fk.TurnStart, { global = true, on_use = function(self, _, target) target.room:setPlayerMark(target, self.name .. "-turn", 0) end })
return qusheng
