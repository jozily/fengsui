local s = fk.CreateSkill { name = "fengsui_heg__yanshi" }
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local function damageCard(id)
  local card = Fk:getCardById(id)
  return card and card.is_damage_card
end

s:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and data.damage > 0 and data.from and
      data.from.hp >= player.hp and player:getMark(s.name .. "_prevent-turn") == 0 and
      table.find(player:getCardIds("h"), damageCard) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local names = {}
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if damageCard(id) then table.insertIfNeed(names, card.trueName) end
    end
    local name = player.room:askToChoice(player, {
      choices = table.connect(names, { "Cancel" }), skill_name = s.name,
    })
    if name == "Cancel" then return false end
    event:setCostData(self, name)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = event:getCostData(self)
    room:showCards(player:getCardIds("h"), player, player)
    local cards = table.filter(player:getCardIds("h"), function(id)
      return damageCard(id) and Fk:getCardById(id).trueName == name
    end)
    room:setPlayerMark(player, s.name .. "_prevent-turn", 1)
    if #cards > 0 then room:throwCard(cards, s.name, player, player) end
    data.damage = 0
  end,
})

s:addEffect("viewas", {
  handly_pile = true,
  interaction = function(self, player)
    local allNames = table.filter(Fk:getAllCardNames("bt"), function(name)
      local card = Fk:cloneCard(name)
      return card.type == Card.TypeBasic or card.is_common_trick
    end)
    local names = player:getViewAsCardNames(s.name, allNames)
    return CardNameUI.create(s.name, names, allNames)
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 or not self.interaction.data or player:getMark(s.name .. "_convert-turn") ~= 0 or
      not damageCard(to_select) then return false end
    local source = Fk:getCardById(to_select)
    local converted = Fk:cloneCard(self.interaction.data)
    return source.skill:getMinTargetNum(player) == converted.skill:getMinTargetNum(player) and
      source.skill:getMaxTargetNum(player, source) == converted.skill:getMaxTargetNum(player, converted)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = s.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local ids = use.card:getIdList()
    room:setPlayerMark(player, s.name .. "_convert-turn", 1)
    if #ids > 0 then
      room:moveCardTo(ids, Card.DrawPile, nil, fk.ReasonPut, s.name, nil, true, player)
      use.card.subcards = {}
    end
  end,
  enabled_at_play = function(self, player) return player:getMark(s.name .. "_convert-turn") == 0 end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark(s.name .. "_convert-turn") == 0
  end,
})

return s
