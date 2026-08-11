local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__shuge" }

local function useLimit(player)
  return math.max(1, #table.filter(player.room.alive_players, function(p)
    return H.compareKingdomWith(p, player)
  end))
end

local function refreshMark(player)
  player.room:setPlayerMark(player, "@" .. s.name,
    tostring(player:getMark(s.name .. "_used")) .. "/" .. tostring(useLimit(player)))
end

s:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(s.name) or
      player:getMark(s.name .. "_used") >= useLimit(player) or not data.from or data.from == player then return false end
    if not table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end) then return false end
    return table.find(player.room:getOtherPlayers(player), function(p)
      return p ~= data.from and p:canPindian(data.from)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p ~= data.from and p:canPindian(data.from)
    end)
    local damageCards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).is_damage_card
    end)
    local tos, cards = player.room:askToChooseCardsAndPlayers(player, {
      min_num = 1, max_num = 1, min_card_num = 1, max_card_num = 1,
      targets = targets, pattern = tostring(Exppattern { id = damageCards }), skill_name = s.name,
      prompt = "#fengsui_heg__shuge-give::" .. data.from.id, cancelable = true,
    })
    if #tos == 0 or #cards == 0 then return false end
    event:setCostData(self, { to = tos[1], card = cards[1] })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, s.name .. "_used", 1)
    refreshMark(player)
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

s:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(s.name, true, true)
  end,
  on_use = function(self, event, target, player, data) refreshMark(player) end,
})

return s
