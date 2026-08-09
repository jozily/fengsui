local dianmo = fk.CreateSkill{
  name = "fengsui_heg__dianmo",
}

local function isCurio(card)
  return card and card.type == Card.TypeEquip and card.package and card.package.name == "nine_variations"
end

dianmo:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "nullification,rob__jink",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return card and card.type == Card.TypeEquip and
      player:getMark("fengsui_heg__dianmo_used-round") == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local source = Fk:getCardById(cards[1])
    local name = source.color == Card.Red and "nullification" or
      (source.color == Card.Black and "rob__jink" or nil)
    if not name then return end
    local card = Fk:cloneCard(name)
    card.skillName = dianmo.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "fengsui_heg__dianmo_used-round", 1)
  end,
  enabled_at_response = function(self, player, response)
    return table.find(player:getCardIds("he"), function(id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and
        player:getMark("fengsui_heg__dianmo_used-round") == 0
    end) ~= nil
  end,
  enabled_at_nullification = function(self, player, data)
    return player:getMark("fengsui_heg__dianmo_used-round") == 0 and
      table.find(player:getCardIds("he"), function(id)
        local card = Fk:getCardById(id)
        return card.type == Card.TypeEquip and card.color == Card.Red
      end) ~= nil
  end,
})

dianmo:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(dianmo.name) or not isCurio(data.card) then return false end
    local n = #player:getCardIds("e")
    return table.find(player.room:getOtherPlayers(player, false), function(p) return #p:getCardIds("e") < n end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player:getCardIds("e")
    local tos = table.filter(player.room:getOtherPlayers(player, false), function(p) return #p:getCardIds("e") < n end)
    local to = player.room:askToChoosePlayers(player, {
      targets = tos,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__dianmo-swap",
      skill_name = dianmo.name,
      cancelable = true,
    })[1]
    if to then
      event:setCostData(self, to)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:swapAllCards(player, { player, event:getCostData(self) }, dianmo.name, "e")
  end,
})

return dianmo
