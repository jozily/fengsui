local s = fk.CreateSkill { name = "fengsui_heg__shuge" }

s:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasShownSkill(s.name) or player:usedSkillTimes(s.name, Player.HistoryRound) > 0 or
      not data.from or data.from == player then return false end
    local damageCards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
    return #damageCards > 0 and table.find(player.room:getOtherPlayers(player), function(p)
      return p ~= data.from and p:canPindian(data.from)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p ~= data.from and p:canPindian(data.from) end)
    local damageCards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1, max_num = 1, min_card_num = 1, max_card_num = 1,
      targets = targets, pattern = tostring(Exppattern { id = damageCards }),
      skill_name = s.name, prompt = "#fengsui_heg__shuge-give::" .. data.from.id, cancelable = true,
    })
    if #tos == 0 or #cards == 0 then return false end
    event:setCostData(self, { to = tos[1], card = cards[1] })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local card = Fk:getCardById(cost.card)
    room:showCards({ cost.card }, player, player)
    room:moveCardTo(cost.card, Card.PlayerHand, cost.to, fk.ReasonGive, s.name, nil, true, player)
    if cost.to.dead or data.from.dead or not cost.to:canPindian(data.from) then return end
    local pindian = cost.to:pindian({ data.from }, s.name)
    local result = pindian.results[data.from]
    if not result then return end
    local shownUsed = (pindian.fromCard and pindian.fromCard:getEffectiveId() == cost.card) or
      (result.toCard and result.toCard:getEffectiveId() == cost.card)
    if shownUsed then
      local user = pindian.fromCard and pindian.fromCard:getEffectiveId() == cost.card and cost.to or data.from
      if user:isAlive() then room:damage { to = user, damage = 1, damageType = fk.ThunderDamage, skillName = s.name } end
    end
    if not result.winner then return end
    local loser = result.winner == cost.to and data.from or cost.to
    if result.winner:isAlive() and loser:isAlive() then
      local useCard = Fk:cloneCard(card.name, card.suit, card.number)
      useCard.skillName = s.name
      if result.winner:canUseTo(useCard, loser, { bypass_distances = true, bypass_times = true }) then
        room:useCard { from = result.winner, tos = { loser }, card = useCard, extraUse = true }
      end
    end
  end,
})

return s
