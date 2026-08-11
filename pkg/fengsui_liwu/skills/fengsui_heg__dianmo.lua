local dianmo = fk.CreateSkill{
  name = "fengsui_heg__dianmo",
}

local function isCurio(card)
  return card and card.type == Card.TypeEquip and card.package and card.package.name == "nine_variations"
end

local function transformedName(card)
  if not card then return nil end
  if card.color == Card.Red then return "nullification" end
  if card.color == Card.Black then return "rob__jink" end
end

local function matchesCurrentResponse(card)
  local name = transformedName(card)
  if not name then return false end
  return not Fk.currentResponsePattern or
    Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name))
end

dianmo:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "nullification,jink",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return card and card.type == Card.TypeEquip and
      matchesCurrentResponse(card)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local source = Fk:getCardById(cards[1])
    local name = transformedName(source)
    if not name then return end
    local card = Fk:cloneCard(name)
    card.skillName = dianmo.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player, response)
    return table.find(player:getCardIds("he"), function(id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and
        matchesCurrentResponse(card)
    end) ~= nil
  end,
  enabled_at_nullification = function(self, player, data)
    return table.find(player:getCardIds("he"), function(id)
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

dianmo:addTest(function(room, me)
  local source = room:printCard("axe", Card.Spade, 1)
  local redSource = room:printCard("axe", Card.Heart, 1)
  local skill = Fk.skills[dianmo.name]
  local card = skill:viewAs(me, { source.id })
  local previousPattern = Fk.currentResponsePattern
  Fk.currentResponsePattern = "jink"
  local blackMatchesJink = matchesCurrentResponse(source)
  local redMatchesJink = matchesCurrentResponse(redSource)
  Fk.currentResponsePattern = previousPattern

  lu.assertEquals(skill.pattern, "nullification,jink")
  lu.assertEquals(card.name, "rob__jink")
  lu.assertEquals(card.trueName, "jink")
  lu.assertTrue(Exppattern:Parse("jink"):match(card))
  lu.assertTrue(blackMatchesJink)
  lu.assertFalse(redMatchesJink)
end)

return dianmo
