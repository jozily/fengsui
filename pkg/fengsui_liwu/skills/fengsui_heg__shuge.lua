local s = fk.CreateSkill { name = "fengsui_heg__shuge" }

s:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasShownSkill(s.name) or
      not data.from or data.from.dead then return false end
    local cards = player:getCardIds("he")
    return #cards > 0 and table.find(player.room:getOtherPlayers(player), function(p)
      return p:canPindian(data.from, true)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p:canPindian(data.from, true) end)
    local cards = player:getCardIds("he")
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1, max_num = 1, min_card_num = 1, max_card_num = 1,
      targets = targets, pattern = tostring(Exppattern { id = cards }),
      skill_name = s.name, prompt = "#fengsui_heg__shuge-give::" .. data.from.id, cancelable = true,
    })
    if #tos == 0 or #cards == 0 then return false end
    event:setCostData(self, { to = tos[1], card = cards[1] })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local suit = Fk:getCardById(cost.card).suit
    room:showCards({ cost.card }, player, player)
    room:moveCardTo(cost.card, Card.PlayerHand, cost.to, fk.ReasonGive, s.name, nil, true, player)
    if cost.to.dead or data.from.dead or not cost.to:canPindian(data.from) then return end
    local pindian = cost.to:pindian({ data.from }, s.name)
    local result = pindian.results[data.from]
    if not result then return end
    local losers = table.filter({cost.to, data.from}, function(p) return p ~= result.winner end)
    local sameSuitUsers = {}
    for _, participant in ipairs({ cost.to, data.from }) do
      local used = participant == cost.to and pindian.fromCard or result.toCard
      if used and used.suit == suit then table.insert(sameSuitUsers, participant) end
    end
    for _, loser in ipairs(losers) do
      for _, sameSuitUser in ipairs(sameSuitUsers) do
        if loser:isAlive() and sameSuitUser:isAlive() then
          room:damage {from = loser, to = sameSuitUser, damage = 1, skillName = s.name}
        end
      end
    end
  end,
})

return s
