local dilie = fk.CreateSkill{
  name = "fengsui_heg__dilie",
}

local function isCurio(card)
  return card and card.package and card.package.name == "nine_variations"
end

local function canRecast(card)
  return card and card.type ~= Card.TypeBasic
end

local function getDiscardCurios(room, player)
  return table.filter(room.discard_pile, function(id)
    return isCurio(Fk:getCardById(id)) and player:canMoveCardIntoEquip(id)
  end)
end

local function getSourceEquips(source, player)
  if not source or source.dead then return {} end
  return table.filter(source:getCardIds("e"), function(id)
    return player:canMoveCardIntoEquip(id)
  end)
end

dilie:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(dilie.name) and
      table.find(player:getCardIds("he"), function(id) return canRecast(Fk:getCardById(id)) end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local cards = table.filter(player:getCardIds("he"), function(id)
      return canRecast(Fk:getCardById(id))
    end)
    local chosen = player.room:askToCards(player, {
      min_num = 1,
      max_num = #cards,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = dilie.name,
      prompt = "#fengsui_heg__dilie-recast",
      cancelable = true,
      include_equip = true,
    })
    if #chosen > 0 then
      event:setCostData(self, chosen)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recastCard(event:getCostData(self), player, dilie.name)
  end,
})

dilie:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(dilie.name) or #player:getEquipments(Card.SubtypeWeapon) > 0 then
      return false
    end
    return #getDiscardCurios(player.room, player) > 0 or #getSourceEquips(data.from, player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not room:askToSkillInvoke(player, { skill_name = dilie.name }) then return false end
    local curios = getDiscardCurios(room, player)
    local sourceEquips = getSourceEquips(data.from, player)
    local choices = {}
    if #curios > 0 then table.insert(choices, "fengsui_heg__dilie_curio") end
    if #sourceEquips > 0 then table.insert(choices, "fengsui_heg__dilie_source_equip") end
    local choice = #choices == 1 and choices[1] or room:askToChoice(player, {
      choices = choices,
      skill_name = dilie.name,
      prompt = "#fengsui_heg__dilie-choice",
    })
    local cards = choice == "fengsui_heg__dilie_curio" and curios or sourceEquips
    local id = table.random(cards, 1)[1]
    if id then
      event:setCostData(self, id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self)
    local card = Fk:getCardById(id)
    local moved = room:moveCardIntoEquip(player, id, dilie.name, true, player)
    if #moved > 0 and card.sub_type == Card.SubtypeWeapon and data.from and data.from:isAlive() and
      player:isAlive() and room:askToSkillInvoke(player, {
      skill_name = dilie.name,
      prompt = "#fengsui_heg__dilie-damage::" .. data.from.id,
    }) then
      room:damage{ from = player, to = data.from, damage = 1, skillName = dilie.name }
    end
  end,
})

dilie:addTest(function(room, me)
  lu.assertFalse(canRecast(Fk:cloneCard("slash")))
  lu.assertTrue(canRecast(Fk:cloneCard("duel")))
  lu.assertTrue(canRecast(Fk:cloneCard("crossbow")))
end)

return dilie
